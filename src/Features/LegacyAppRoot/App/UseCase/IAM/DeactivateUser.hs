{-# LANGUAGE ScopedTypeVariables #-}

{- | ユーザー無効化ユースケース
#45, #46: 型クラス DI を廃止。IAMEnv レコードで依存を注入。
#21, #22: イベントを appendUserEvent で永続化する。上書きしない。
#40: reason を捨てずにイベントに含める（TODO: UserDeactivated に reason フィールド追加後に差し替え）
-}
module App.UseCase.IAM.DeactivateUser (executeDeactivateUser) where

import App.DTO.Request.IAM (DeactivateUserRequest (..))
import App.DTO.Response.IAM (UserResponse)
import App.UseCase.IAM.Internal (IAMEnv (..), UserAppM, liftUserDomain, runUserAppM, toUserResponse)
import Control.Monad.Except (liftEither)
import Control.Monad.Reader (ask)
import Domain.IAM.User (deactivateUser, getUserId, getUserProfile, getUserState)
import Domain.IAM.User.Errors (domainErrorMessage)
import Domain.IAM.User.ValueObjects.UserId (mkUserId)

executeDeactivateUser ::
    forall m.
    Monad m =>
    IAMEnv m ->
    DeactivateUserRequest ->
    m ()
executeDeactivateUser env (DeactivateUserRequest rawId reason) = do
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
            -- 2. Active/Suspended ユーザーをロード
            user <- liftUserDomain $ envLoadUser env' userId
            -- 3. ドメインロジック適用（Active|Suspended → Inactive）、reason を渡す (#40)
            (inactiveUser, event) <- liftEither $ deactivateUser reason user
            -- 4. 集約を保存
            liftUserDomain $ envSaveUser env' inactiveUser
            -- 5. イベントを永続化 (#21, #22, #40: reason はイベントに含まれている)
            liftUserDomain $ envAppendUserEvent env' (getUserId inactiveUser) event
            -- 6. レスポンス
            pure $
                toUserResponse (getUserId inactiveUser) (getUserProfile inactiveUser) (getUserState inactiveUser)
