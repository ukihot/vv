module Domain.IAM.Role.Entities.Profile (
    RoleProfile (..),
    addPermission,
    removePermission,
)
where

import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Role.ValueObjects.RoleName (RoleName)

data RoleProfile = RoleProfile
    { profileName :: RoleName
    , profilePermissions :: [PermissionId]
    }
    deriving stock (Show, Eq)

addPermission :: PermissionId -> RoleProfile -> RoleProfile
addPermission permissionId profile
    | permissionId `elem` profile.profilePermissions = profile
    | otherwise =
        profile
            { profilePermissions = profile.profilePermissions <> [permissionId]
            }

removePermission :: PermissionId -> RoleProfile -> RoleProfile
removePermission permissionId profile =
    profile
        { profilePermissions = filter (/= permissionId) profile.profilePermissions
        }
