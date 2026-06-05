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
    deriving stock (Show, Eq)

data RegisterUserRequest = RegisterUserRequest
    { registerUserName :: Text
    , registerUserEmail :: Text
    , registerUserRole :: Text
    }
    deriving stock (Show, Eq)

data ActivateUserRequest = ActivateUserRequest
    { activateUserId :: Text
    }
    deriving stock (Show, Eq)

data DeactivateUserRequest = DeactivateUserRequest
    { deactivateUserId :: Text
    , deactivateReason :: Text
    }
    deriving stock (Show, Eq)

data AssignRoleRequest = AssignRoleRequest
    { assignRoleUserId :: Text
    , assignRoleRoleId :: Text
    }
    deriving stock (Show, Eq)

data RevokeRoleRequest = RevokeRoleRequest
    { revokeRoleUserId :: Text
    , revokeRoleRoleId :: Text
    }
    deriving stock (Show, Eq)

data GrantPermissionRequest = GrantPermissionRequest
    { grantPermissionRoleId :: Text
    , grantPermissionPermissionId :: Text
    }
    deriving stock (Show, Eq)

data RevokePermissionRequest = RevokePermissionRequest
    { revokePermissionRoleId :: Text
    , revokePermissionPermissionId :: Text
    }
    deriving stock (Show, Eq)
