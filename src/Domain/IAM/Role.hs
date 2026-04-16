module Domain.IAM.Role (
    Role (..),
    RoleState (..),
    getRoleId,
    getRoleProfile,
    getRoleVersion,
    activateRole,
    deactivateRole,
    assignPermissionToRole,
    revokePermissionFromRole,

    -- * Event Sourcing
    SomeRole (..),
    applyRoleEvent,
    rehydrateRole,
)
where

import Control.Monad (foldM)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Role.Entities.Profile (RoleProfile (..), addPermission, removePermission)
import Domain.IAM.Role.Errors (DomainError (..))
import Domain.IAM.Role.Events (RoleEventPayload (..))
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
import Domain.IAM.Role.ValueObjects.RoleName (RoleName)
import Domain.IAM.Role.ValueObjects.RoleState (RoleState (..))
import Domain.IAM.Role.ValueObjects.Version (Version, initialVersion, nextVersion)
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Sourcing
-- ─────────────────────────────────────────────────────────────────────────────

data SomeRole where
    SomeRole :: Role s -> SomeRole

deriving stock instance Show SomeRole

applyRoleEvent :: Maybe SomeRole -> RoleEventPayload -> Either DomainError SomeRole
applyRoleEvent Nothing (RoleCreated roleId roleName) =
    Right $ SomeRole $ RoleD roleId (RoleProfile roleName []) (nextVersion initialVersion)
applyRoleEvent (Just (SomeRole (RoleD roleId profile v))) (RoleActivated _ _) =
    Right $ SomeRole $ RoleA roleId profile (nextVersion v)
applyRoleEvent (Just (SomeRole (RoleA roleId profile v))) (RoleDeactivated _ _) =
    Right $ SomeRole $ RoleI roleId profile (nextVersion v)
applyRoleEvent (Just (SomeRole (RoleA roleId profile v))) (PermissionAssignedToRole _ _ pid) =
    Right $ SomeRole $ RoleA roleId (addPermission pid profile) (nextVersion v)
applyRoleEvent (Just (SomeRole (RoleA roleId profile v))) (PermissionRevokedFromRole _ _ pid) =
    Right $ SomeRole $ RoleA roleId (removePermission pid profile) (nextVersion v)
applyRoleEvent _ _ = Left IllegalTransition

rehydrateRole :: [RoleEventPayload] -> Either DomainError SomeRole
rehydrateRole [] = Left IllegalTransition
rehydrateRole (e : es) = do
    s0 <- applyRoleEvent Nothing e
    foldM (\s ev -> applyRoleEvent (Just s) ev) s0 es
