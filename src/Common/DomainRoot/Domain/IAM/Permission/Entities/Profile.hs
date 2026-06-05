module Domain.IAM.Permission.Entities.Profile (PermissionProfile (..)) where

import Domain.IAM.Permission.ValueObjects.PermissionCode (PermissionCode)
import Domain.IAM.Permission.ValueObjects.PermissionName (PermissionName)

data PermissionProfile = PermissionProfile
    { profileName :: PermissionName
    , profileCode :: PermissionCode
    }
    deriving stock (Show, Eq)
