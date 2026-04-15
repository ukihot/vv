module Domain.IAM.Permission.Errors (DomainError (..)) where

data DomainError
    = InvalidPermissionId
    | InvalidPermissionName
    | InvalidPermissionCode
    | DuplicatePermissionCode
    | RepositoryError String
    deriving stock (Show, Eq)
