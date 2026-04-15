module Domain.IAM.Permission
  ( Permission (..),
    PermissionState (..),
    getPermissionId,
    getPermissionProfile,
    getPermissionVersion,
    activatePermission,
    retirePermission,
  )
where

import Domain.IAM.Permission.Entities.Profile (PermissionProfile)
import Domain.IAM.Permission.Events (PermissionEventPayload (..))
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Permission.ValueObjects.PermissionState (PermissionState (..))
import Domain.IAM.Permission.ValueObjects.Version (Version, nextVersion)
import Domain.IAM.User.ValueObjects.UserId (UserId)

data Permission (s :: PermissionState) where
  PermissionD :: PermissionId -> PermissionProfile -> Version -> Permission 'Draft
  PermissionA :: PermissionId -> PermissionProfile -> Version -> Permission 'Active
  PermissionR :: PermissionId -> PermissionProfile -> Version -> Permission 'Retired

deriving stock instance Show (Permission s)

deriving stock instance Eq (Permission s)

getPermissionId :: Permission s -> PermissionId
getPermissionId (PermissionD permissionId _ _) = permissionId
getPermissionId (PermissionA permissionId _ _) = permissionId
getPermissionId (PermissionR permissionId _ _) = permissionId

getPermissionProfile :: Permission s -> PermissionProfile
getPermissionProfile (PermissionD _ profile _) = profile
getPermissionProfile (PermissionA _ profile _) = profile
getPermissionProfile (PermissionR _ profile _) = profile

getPermissionVersion :: Permission s -> Version
getPermissionVersion (PermissionD _ _ version) = version
getPermissionVersion (PermissionA _ _ version) = version
getPermissionVersion (PermissionR _ _ version) = version

activatePermission ::
  UserId ->
  Permission 'Draft ->
  (Permission 'Active, PermissionEventPayload)
activatePermission actorId (PermissionD permissionId profile version) =
  let nextV = nextVersion version
   in (PermissionA permissionId profile nextV, PermissionActivated actorId permissionId)

retirePermission ::
  UserId ->
  Permission 'Active ->
  (Permission 'Retired, PermissionEventPayload)
retirePermission actorId (PermissionA permissionId profile version) =
  let nextV = nextVersion version
   in (PermissionR permissionId profile nextV, PermissionRetired actorId permissionId)
