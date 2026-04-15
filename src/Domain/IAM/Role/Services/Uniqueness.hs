module Domain.IAM.Role.Services.Uniqueness (DuplicateChecker, validateUniqueRoleName) where

import Domain.IAM.Role.Errors (DomainError (DuplicateRoleName))
import Domain.IAM.Role.ValueObjects.RoleName (RoleName)

type DuplicateChecker m = RoleName -> m Bool

validateUniqueRoleName :: Monad m => DuplicateChecker m -> RoleName -> m (Either DomainError ())
validateUniqueRoleName check roleName = do
    exists <- check roleName
    pure $ if exists then Left DuplicateRoleName else Right ()
