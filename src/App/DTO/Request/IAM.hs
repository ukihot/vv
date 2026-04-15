module App.DTO.Request.IAM (
    LoginRequest (..),
    RegisterUserRequest (..),
    ActivateUserRequest (..),
    DeactivateUserRequest (..),
    AssignRoleRequest (..),
    RevokeRoleRequest (..),
    GrantPermissionRequest (..),
    RevokePermissionRequest (..),
)
where

import Data.Text (Text)

-- ============================================================================
-- IAM Request DTOs
-- ============================================================================

data LoginRequest = LoginRequest
    { loginUsername :: Text
    , loginPassword :: Text
    }
    deriving (Show, Eq)

data RegisterUserRequest = RegisterUserRequest
    { registerUserName :: Text
    , registerUserEmail :: Text
    , registerUserRole :: Text
    }
    deriving (Show, Eq)

data ActivateUserRequest = ActivateUserRequest
    { activateUserId :: Text
    }
    deriving (Show, Eq)

data DeactivateUserRequest = DeactivateUserRequest
    { deactivateUserId :: Text
    , deactivateReason :: Text
    }
    deriving (Show, Eq)

data AssignRoleRequest = AssignRoleRequest
    { assignRoleUserId :: Text
    , assignRoleRoleId :: Text
    }
    deriving (Show, Eq)

data RevokeRoleRequest = RevokeRoleRequest
    { revokeRoleUserId :: Text
    , revokeRoleRoleId :: Text
    }
    deriving (Show, Eq)

data GrantPermissionRequest = GrantPermissionRequest
    { grantPermissionRoleId :: Text
    , grantPermissionPermissionId :: Text
    }
    deriving (Show, Eq)

data RevokePermissionRequest = RevokePermissionRequest
    { revokePermissionRoleId :: Text
    , revokePermissionPermissionId :: Text
    }
    deriving (Show, Eq)
