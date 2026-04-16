module Domain.IAM.Permission (
    Permission (..),
    PermissionState (..),
    getPermissionId,
    getPermissionProfile,
    getPermissionVersion,
    activatePermission,
    retirePermission,

    -- * Event Sourcing
    SomePermission (..),
    applyPermissionEvent,
    rehydratePermission,
)
where

import Control.Monad (foldM)
import Domain.IAM.Permission.Entities.Profile (PermissionProfile (..))
import Domain.IAM.Permission.Errors (DomainError (..))
import Domain.IAM.Permission.Events (PermissionEventPayload (..))
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Permission.ValueObjects.PermissionState (PermissionState (..))
import Domain.IAM.Permission.ValueObjects.Version (Version, initialVersion, nextVersion)
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Sourcing
-- ─────────────────────────────────────────────────────────────────────────────

data SomePermission where
    SomePermission :: Permission s -> SomePermission

deriving stock instance Show SomePermission

applyPermissionEvent ::
    Maybe SomePermission -> PermissionEventPayload -> Either DomainError SomePermission
applyPermissionEvent Nothing (PermissionDefined pid name code) =
    Right $ SomePermission $ PermissionD pid (PermissionProfile name code) (nextVersion initialVersion)
applyPermissionEvent (Just (SomePermission (PermissionD pid profile v))) (PermissionActivated _ _) =
    Right $ SomePermission $ PermissionA pid profile (nextVersion v)
applyPermissionEvent (Just (SomePermission (PermissionA pid profile v))) (PermissionRetired _ _) =
    Right $ SomePermission $ PermissionR pid profile (nextVersion v)
applyPermissionEvent _ _ = Left IllegalTransition

rehydratePermission :: [PermissionEventPayload] -> Either DomainError SomePermission
rehydratePermission [] = Left IllegalTransition
rehydratePermission (e : es) = do
    s0 <- applyPermissionEvent Nothing e
    foldM (\s ev -> applyPermissionEvent (Just s) ev) s0 es
