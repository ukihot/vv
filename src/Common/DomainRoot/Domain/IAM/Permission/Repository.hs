{- | パーミッションリポジトリの型定義
Handle パターン (#45, #46) で依存を値として渡す。
-}
module Domain.IAM.Permission.Repository (PermissionHandle (..)) where

import Domain.IAM.Permission (Permission)
import Domain.IAM.Permission.Errors (DomainError)
import Domain.IAM.Permission.Events (PermissionEventPayload)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)

data PermissionHandle m = PermissionHandle
    { loadPermission :: forall s. PermissionId -> m (Either DomainError (Permission s))
    , savePermission :: forall s. Permission s -> m (Either DomainError ())
    , appendPermissionEvent :: PermissionId -> PermissionEventPayload -> m (Either DomainError ())
    }
