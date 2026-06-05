{- | ロールリポジトリの型定義
Handle パターン (#45, #46) で依存を値として渡す。
-}
module Domain.IAM.Role.Repository (RoleHandle (..)) where

import Domain.IAM.Role (Role)
import Domain.IAM.Role.Errors (DomainError)
import Domain.IAM.Role.Events (RoleEventPayload)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)

data RoleHandle m = RoleHandle
    { loadRole :: forall s. RoleId -> m (Either DomainError (Role s))
    , saveRole :: forall s. Role s -> m (Either DomainError ())
    , appendRoleEvent :: RoleId -> RoleEventPayload -> m (Either DomainError ())
    }
