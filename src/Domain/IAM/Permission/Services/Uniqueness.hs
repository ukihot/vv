module Domain.IAM.Permission.Services.Uniqueness (DuplicateChecker, validateUniquePermissionCode) where

import Domain.IAM.Permission.Errors (DomainError (DuplicatePermissionCode))
import Domain.IAM.Permission.ValueObjects.PermissionCode (PermissionCode)

type DuplicateChecker m = PermissionCode -> m Bool

validateUniquePermissionCode ::
    Monad m =>
    DuplicateChecker m ->
    PermissionCode ->
    m (Either DomainError ())
validateUniquePermissionCode check permissionCode = do
    exists <- check permissionCode
    pure $ if exists then Left DuplicatePermissionCode else Right ()
