module Domain.IAM.Role
  ( Role (..),
    RoleState (..),
    getRoleId,
    getRoleProfile,
    getRoleVersion,
    activateRole,
    deactivateRole,
    assignPermissionToRole,
    revokePermissionFromRole,
  )
where

import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Role.Entities.Profile (RoleProfile, addPermission, removePermission)
import Domain.IAM.Role.Events (RoleEventPayload (..))
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
import Domain.IAM.Role.ValueObjects.RoleState (RoleState (..))
import Domain.IAM.Role.ValueObjects.Version (Version, nextVersion)
import Domain.IAM.User.ValueObjects.UserId (UserId)

data Role (s :: RoleState) where
  RoleD :: RoleId -> RoleProfile -> Version -> Role 'Draft
  RoleA :: RoleId -> RoleProfile -> Version -> Role 'Active
  RoleI :: RoleId -> RoleProfile -> Version -> Role 'Inactive

deriving stock instance Show (Role s)

deriving stock instance Eq (Role s)

getRoleId :: Role s -> RoleId
getRoleId (RoleD roleId _ _) = roleId
getRoleId (RoleA roleId _ _) = roleId
getRoleId (RoleI roleId _ _) = roleId

getRoleProfile :: Role s -> RoleProfile
getRoleProfile (RoleD _ profile _) = profile
getRoleProfile (RoleA _ profile _) = profile
getRoleProfile (RoleI _ profile _) = profile

getRoleVersion :: Role s -> Version
getRoleVersion (RoleD _ _ version) = version
getRoleVersion (RoleA _ _ version) = version
getRoleVersion (RoleI _ _ version) = version

activateRole :: UserId -> Role 'Draft -> (Role 'Active, RoleEventPayload)
activateRole actorId (RoleD roleId profile version) =
  let nextV = nextVersion version
   in (RoleA roleId profile nextV, RoleActivated actorId roleId)

deactivateRole :: UserId -> Role 'Active -> (Role 'Inactive, RoleEventPayload)
deactivateRole actorId (RoleA roleId profile version) =
  let nextV = nextVersion version
   in (RoleI roleId profile nextV, RoleDeactivated actorId roleId)

assignPermissionToRole ::
  UserId ->
  PermissionId ->
  Role 'Active ->
  (Role 'Active, RoleEventPayload)
assignPermissionToRole actorId permissionId (RoleA roleId profile version) =
  let nextProfile = addPermission permissionId profile
      nextV = nextVersion version
   in (RoleA roleId nextProfile nextV, PermissionAssignedToRole actorId roleId permissionId)

revokePermissionFromRole ::
  UserId ->
  PermissionId ->
  Role 'Active ->
  (Role 'Active, RoleEventPayload)
revokePermissionFromRole actorId permissionId (RoleA roleId profile version) =
  let nextProfile = removePermission permissionId profile
      nextV = nextVersion version
   in (RoleA roleId nextProfile nextV, PermissionRevokedFromRole actorId roleId permissionId)
