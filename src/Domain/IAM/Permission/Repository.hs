module Domain.IAM.Permission.Repository where

import Domain.IAM.Permission (Permission)
import Domain.IAM.Permission.Errors (DomainError)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)

class (Monad m) => PermissionRepository m where
  loadPermission :: forall s. PermissionId -> m (Either DomainError (Permission s))
  savePermission :: Permission s -> m (Either DomainError ())
