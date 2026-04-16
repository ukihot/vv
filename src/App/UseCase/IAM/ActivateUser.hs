{-# LANGUAGE ScopedTypeVariables #-}

{- | ユーザー有効化ユースケース
#45, #46: 型クラス DI を廃止。IAMEnv レコードで依存を注入。
#21, #22: イベントを appendUserEvent で永続化する。上書きしない。
#62: toUserResponse で実際の値を使う。ハードコードを廃止。
-}
module App.UseCase.IAM.ActivateUser (executeActivateUser) where

import App.DTO.Request.IAM (ActivateUserRequest (..))
import App.DTO.Response.IAM (UserResponse)
import App.UseCase.IAM.Internal (IAMEnv (..), UserAppM, liftUserDomain, runUserAppM, toUserResponse)
import Control.Monad.Except (liftEither)
import Control.Monad.Reader (ask)
import Domain.IAM.User (activateUser, getUserId, getUserProfile, getUserState)
import Domain.IAM.User.Errors (domainErrorMessage)
import Domain.IAM.User.ValueObjects.UserId (mkUserId)

executeActivateUser ::
    forall m.
    Monad m =>
    IAMEnv m ->
    ActivateUserRequest ->
    m ()
executeActivateUser env (ActivateUserRequest rawId) = do
    result <- runUserAppM env pipeline
    case result of
        Left err -> envPresentFailure env (domainErrorMessage err)
        Right response -> envPresentSuccess env response
    where
        pipeline :: UserAppM m UserResponse
        pipeline = do
            env' <- ask
            -- 1. UserId 生成
            userId <- liftEither $ mkUserId rawId
            -- 2. Pending ユーザーをロード
            pendingUser <- liftUserDomain $ envLoadUser env' userId
            -- 3. ドメインロジック適用（Pending → Active）
            let (activeUser, event) = activateUser pendingUser
            -- 4. 集約を保存
            liftUserDomain $ envSaveUser env' activeUser
            -- 5. イベントを永続化 (#21, #22)
            liftUserDomain $ envAppendUserEvent env' (getUserId activeUser) event
            -- 6. 実際の値でレスポンス生成 (#62)
            pure $ toUserResponse (getUserId activeUser) (getUserProfile activeUser) (getUserState activeUser)
