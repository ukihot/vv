module Domain.IAM.User.Errors (DomainError (..), domainErrorMessage) where

import Data.Text (Text)
import Data.Text qualified as T

data DomainError
    = InvalidUserId
    | InvalidUserName
    | InvalidEmail
    | DuplicateEmail
    | IllegalTransition -- #13, #14: 不正な状態遷移
    | AlreadyActivated
    | UserIsInactive -- #3: 無効化済みユーザーへの操作拒否
    | RepositoryError String
    deriving (Show, Eq)

-- | エラーの表示用メッセージ
domainErrorMessage :: DomainError -> Text
domainErrorMessage InvalidUserId = "Invalid user ID"
domainErrorMessage InvalidUserName = "Invalid user name"
domainErrorMessage InvalidEmail = "Invalid email"
domainErrorMessage DuplicateEmail = "Email already exists"
domainErrorMessage IllegalTransition = "Illegal state transition"
domainErrorMessage AlreadyActivated = "User is already activated"
domainErrorMessage UserIsInactive = "User is inactive"
domainErrorMessage (RepositoryError msg) = T.pack $ "Repository error: " ++ msg
