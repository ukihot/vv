module Domain.IAM.Role.Errors (DomainError (..)) where

data DomainError
    = InvalidRoleId
    | InvalidRoleName
    | DuplicateRoleName
    | EmptyPermissionSet
    | RepositoryError String
    deriving stock (Show, Eq)
