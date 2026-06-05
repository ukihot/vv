{-# LANGUAGE ScopedTypeVariables #-}

{- | ロール割り当てユースケース
#8: User 集約がロール一覧を保持する。集約境界を明確にする。
#45, #46: 型クラス DI を廃止。IAMEnv レコードで依存を注入。
#21, #22: イベントを appendUserEvent で永続化する。
#25: envCurrentActorId で操作者を記録する。
-}
module App.UseCase.IAM.AssignRole (executeAssignRole) where

import App.DTO.Request.IAM (AssignRoleRequest (..))
import App.DTO.Response.IAM (UserResponse)
import App.UseCase.IAM.Internal (IAMEnv (..), UserAppM, liftUserDomain, runUserAppM, toUserResponse)
import Control.Monad.Except (liftEither)
import Control.Monad.Reader (ask)
import Domain.IAM.Role.Errors qualified as RoleError
import Domain.IAM.Role.ValueObjects.RoleId (mkRoleId)
import Domain.IAM.User (assignRole, getUserId, getUserProfile, getUserState)
import Domain.IAM.User.Errors (DomainError (..), domainErrorMessage)
import Domain.IAM.User.ValueObjects.UserId (mkUserId)

executeAssignRole ::
    forall m.
    Monad m =>
    IAMEnv m ->
    AssignRoleRequest ->
    m ()
executeAssignRole env (AssignRoleRequest rawUserId rawRoleId) = do
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
            -- 1. Active ユーザーをロード（Active のみロール割り当て可）
            activeUser <- liftUserDomain $ envLoadUser env' userId
            -- 2. ロール存在確認（Active ロールのみ割り当て可）
            _ <- liftUserDomain $ fmap mapRoleError (envLoadRole env' roleId)
            -- 3. ドメインロジック適用（User 集約にロールを追加 #8）
            let (updatedUser, event) = assignRole roleId activeUser
            -- 4. 集約を保存
            liftUserDomain $ envSaveUser env' updatedUser
            -- 5. イベントを永続化 (#21, #22)
            liftUserDomain $ envAppendUserEvent env' (getUserId updatedUser) event
            -- 6. レスポンス
            pure $
                toUserResponse (getUserId updatedUser) (getUserProfile updatedUser) (getUserState updatedUser)

        mapRoleError :: Either RoleError.DomainError a -> Either DomainError a
        mapRoleError (Left _) = Left IllegalTransition
        mapRoleError (Right a) = Right a
