{-# LANGUAGE ScopedTypeVariables #-}

{- | ロール剥奪ユースケース
#8: User 集約がロール一覧を保持する。集約境界を明確にする。
#45, #46: 型クラス DI を廃止。IAMEnv レコードで依存を注入。
#21, #22: イベントを appendUserEvent で永続化する。
-}
module App.UseCase.IAM.RevokeRole (executeRevokeRole) where

import App.DTO.Request.IAM (RevokeRoleRequest (..))
import App.DTO.Response.IAM (UserResponse)
import App.UseCase.IAM.Internal (IAMEnv (..), UserAppM, liftUserDomain, runUserAppM, toUserResponse)
import Control.Monad.Except (liftEither)
import Control.Monad.Reader (ask)
import Domain.IAM.Role.Errors qualified as RoleError
import Domain.IAM.Role.ValueObjects.RoleId (mkRoleId)
import Domain.IAM.User (getUserId, getUserProfile, getUserState, revokeRole)
import Domain.IAM.User.Errors (DomainError (..), domainErrorMessage)
import Domain.IAM.User.ValueObjects.UserId (mkUserId)

executeRevokeRole ::
    forall m.
    Monad m =>
    IAMEnv m ->
    RevokeRoleRequest ->
    m ()
executeRevokeRole env (RevokeRoleRequest rawUserId rawRoleId) = do
    result <- runUserAppM env pipeline
    case result of
        Left err -> envPresentFailure env (domainErrorMessage err)
        Right response -> envPresentSuccess env response
    where
        pipeline :: UserAppM m UserResponse
        pipeline = do
            env' <- ask
            userId <- liftEither $ mkUserId rawUserId
            roleId <- liftEither $ mapRoleError (mkRoleId rawRoleId)
            -- 1. Active ユーザーをロード（Active のみロール剥奪可）
            activeUser <- liftUserDomain $ envLoadUser env' userId
            -- 2. ドメインロジック適用（User 集約からロールを除去 #8）
            let (updatedUser, event) = revokeRole roleId activeUser
            -- 3. 集約を保存
            liftUserDomain $ envSaveUser env' updatedUser
            -- 4. イベントを永続化 (#21, #22)
            liftUserDomain $ envAppendUserEvent env' (getUserId updatedUser) event
            -- 5. レスポンス
            pure $
                toUserResponse (getUserId updatedUser) (getUserProfile updatedUser) (getUserState updatedUser)

        mapRoleError :: Either RoleError.DomainError a -> Either DomainError a
        mapRoleError (Left _) = Left IllegalTransition
        mapRoleError (Right a) = Right a
