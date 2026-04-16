module Domain.IAM.Permission.Errors (DomainError (..), domainErrorMessage) where

import Data.Text (Text)
import Data.Text qualified as T

data DomainError
    = InvalidPermissionId
    | InvalidPermissionName
    | InvalidPermissionCode
    | DuplicatePermissionCode
    | RepositoryError String
    deriving stock (Show, Eq)

domainErrorMessage :: DomainError -> Text
domainErrorMessage InvalidPermissionId = "Invalid permission ID"
domainErrorMessage InvalidPermissionName = "Invalid permission name"
domainErrorMessage InvalidPermissionCode = "Invalid permission code"
domainErrorMessage DuplicatePermissionCode = "Permission code already exists"
domainErrorMessage (RepositoryError msg) = T.pack $ "Repository error: " ++ msg
