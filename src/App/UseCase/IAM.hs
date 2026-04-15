module App.UseCase.IAM (
    executeActivateUser,
) where

import App.DTO.Request.IAM (ActivateUserRequest (..))
import App.DTO.Response.IAM (UserResponse (..))
import App.Ports.Output.IAM (ActivateUserOutputPort (..))
import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.User (activateUser)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Repository (UserRepository (..))
import Domain.IAM.User.ValueObjects.UserId (mkUserId)

{- | ユーザー有効化ユースケース

新しい設計:
- RequestDTOを受け取る
- ()を返す（副作用のみ）
- 結果はOutputPortを通じて提示
-}

-- | DomainErrorをTextに変換する
domainErrorToText :: DomainError -> Text
domainErrorToText InvalidUserId = "Invalid user ID"
domainErrorToText InvalidUserName = "Invalid user name"
domainErrorToText InvalidEmail = "Invalid email"
domainErrorToText DuplicateEmail = "Email already exists"
domainErrorToText IllegalTransition = "Illegal state transition"
domainErrorToText AlreadyActivated = "User is already activated"
domainErrorToText UserIsInactive = "User is inactive"
domainErrorToText (RepositoryError msg) = T.pack $ "Repository error: " ++ msg

executeActivateUser ::
    (Monad m, UserRepository m, ActivateUserOutputPort m) =>
    ActivateUserRequest ->
    m ()
executeActivateUser (ActivateUserRequest rawId) = do
    -- 1. UserId作成
    case mkUserId rawId of
        Left err -> presentActivateUserFailure (domainErrorToText err)
        Right userId -> do
            -- 2. ユーザー読み込み
            loadResult <- loadUser userId
            case loadResult of
                Left err -> presentActivateUserFailure (domainErrorToText err)
                Right pendingUser -> do
                    -- 3. ドメインロジック適用
                    let (activeUser, _event) = activateUser pendingUser

                    -- 4. 保存
                    saveResult <- saveUser activeUser
                    case saveResult of
                        Left err -> presentActivateUserFailure (domainErrorToText err)
                        Right () -> do
                            -- 5. 成功レスポンス作成（仮実装）
                            let response =
                                    UserResponse
                                        { userResponseId = rawId
                                        , userResponseName = "User" -- TODO: 実際の値
                                        , userResponseEmail = "user@example.com" -- TODO: 実際の値
                                        , userResponseStatus = "active"
                                        , userResponseRoles = []
                                        , userResponseCreatedAt = undefined -- TODO: 実際の値
                                        , userResponseUpdatedAt = Nothing
                                        }
                            presentActivateUserSuccess response
