module Domain.IAM.Permission.Services.Factory (
    definePermission,
)
where

import Domain.IAM.Permission (Permission (PermissionD))
import Domain.IAM.Permission.Entities.Profile (PermissionProfile (..))
import Domain.IAM.Permission.Events (PermissionEventPayload (..))
import Domain.IAM.Permission.ValueObjects.PermissionCode (PermissionCode)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Permission.ValueObjects.PermissionName (PermissionName)
import Domain.IAM.Permission.ValueObjects.PermissionState (PermissionState (Draft))
import Domain.IAM.Permission.ValueObjects.Version (initialVersion)

definePermission ::
    PermissionId ->
    PermissionName ->
    PermissionCode ->
    (Permission 'Draft, PermissionEventPayload)
definePermission permissionId permissionName permissionCode =
    let profile = PermissionProfile permissionName permissionCode
        permission = PermissionD permissionId profile initialVersion
     in (permission, PermissionDefined permissionId permissionName permissionCode)
