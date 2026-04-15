module Domain.IAM.Permission.Events (PermissionEventPayload (..)) where

import Domain.IAM.Permission.ValueObjects.PermissionCode (PermissionCode)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Permission.ValueObjects.PermissionName (PermissionName)
import Domain.IAM.User.ValueObjects.UserId (UserId)

data PermissionEventPayload
    = PermissionDefined PermissionId PermissionName PermissionCode
    | PermissionActivated UserId PermissionId
    | PermissionRetired UserId PermissionId
    deriving stock (Show, Eq)
