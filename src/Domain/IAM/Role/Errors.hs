module Domain.IAM.Role.Errors (DomainError (..), domainErrorMessage) where

import Data.Text (Text)
import Data.Text qualified as T

data DomainError
    = InvalidRoleId
    | InvalidRoleName
    | DuplicateRoleName
    | EmptyPermissionSet
    | RepositoryError String
    deriving stock (Show, Eq)

domainErrorMessage :: DomainError -> Text
domainErrorMessage InvalidRoleId = "Invalid role ID"
domainErrorMessage InvalidRoleName = "Invalid role name"
domainErrorMessage DuplicateRoleName = "Role name already exists"
domainErrorMessage EmptyPermissionSet = "Permission set must not be empty"
domainErrorMessage (RepositoryError msg) = T.pack $ "Repository error: " ++ msg
