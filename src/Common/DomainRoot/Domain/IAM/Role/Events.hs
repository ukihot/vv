module Domain.IAM.Role.Events (RoleEventPayload (..)) where

import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
import Domain.IAM.Role.ValueObjects.RoleName (RoleName)
import Domain.IAM.User.ValueObjects.UserId (UserId)

data RoleEventPayload
    = RoleCreated RoleId RoleName
    | RoleActivated UserId RoleId
    | RoleDeactivated UserId RoleId
    | PermissionAssignedToRole UserId RoleId PermissionId
    | PermissionRevokedFromRole UserId RoleId PermissionId
    deriving stock (Show, Eq)
