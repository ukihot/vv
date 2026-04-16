{-# LANGUAGE ScopedTypeVariables #-}

{- | ユーザー登録ユースケース
#45, #46: 型クラス DI を廃止。IAMEnv レコードで依存を注入。
#10: ドメインロジックは Factory に委譲。UseCase は組み立てのみ。
#21, #22: イベントを appendUserEvent で永続化する。上書きしない。
-}
module App.UseCase.IAM.RegisterUser (executeRegisterUser) where

import App.DTO.Request.IAM (RegisterUserRequest (..))
import App.DTO.Response.IAM (UserResponse)
import App.UseCase.IAM.Internal (IAMEnv (..), UserAppM, liftUserDomain, runUserAppM, toUserResponse)
import Control.Monad.Except (liftEither)
import Control.Monad.Reader (ask)
import Domain.IAM.User (getUserId, getUserProfile, getUserState)
import Domain.IAM.User.Errors (DomainError, domainErrorMessage)
import Domain.IAM.User.Services.Factory (registerUser)
import Domain.IAM.User.ValueObjects.Email (mkEmail)
import Domain.IAM.User.ValueObjects.UserId (mkUserId)
import Domain.IAM.User.ValueObjects.UserName (mkUserName)

executeRegisterUser ::
    forall m.
    Monad m =>
    IAMEnv m ->
    RegisterUserRequest ->
    m ()
executeRegisterUser env req = do
    result <- runUserAppM env pipeline
    case result of
        Left err -> envPresentFailure env (domainErrorMessage err)
        Right response -> envPresentSuccess env response
    where
        pipeline :: UserAppM m UserResponse
        pipeline = do
            env' <- ask
            -- 1. 値オブジェクト生成（スマートコンストラクタで妥当性確定 #2）
            userId <- liftEither $ mkUserId (registerUserName req) -- TODO: UUID生成に差し替える
            name <- liftEither $ mkUserName (registerUserName req)
            email <- liftEither $ mkEmail (registerUserEmail req)
            -- 2. Factory でユーザーとイベントをペアで生成 (#10)
            let (newUser, event) = registerUser userId name email
            -- 3. 集約を保存
            liftUserDomain $ envSaveUser env' newUser
            -- 4. イベントを永続化 (#21, #22)
            liftUserDomain $ envAppendUserEvent env' (getUserId newUser) event
            -- 5. レスポンス
            pure $ toUserResponse (getUserId newUser) (getUserProfile newUser) (getUserState newUser)
