module Domain.IAM.Role.Repository where

import Domain.IAM.Role (Role)
import Domain.IAM.Role.Errors (DomainError)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)

class Monad m => RoleRepository m where
    loadRole :: forall s. RoleId -> m (Either DomainError (Role s))
    saveRole :: Role s -> m (Either DomainError ())
