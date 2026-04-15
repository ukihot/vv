module App.DTO.Response.IAM (
    LoginResponse (..),
    UserResponse (..),
    RoleResponse (..),
    PermissionResponse (..),
    UserListResponse (..),
)
where

import Data.Text (Text)
import Data.Time (UTCTime)

-- ============================================================================
-- IAM Response DTOs
-- ============================================================================

data LoginResponse = LoginResponse
    { loginResponseToken :: Text
    , loginResponseUserId :: Text
    , loginResponseExpiresAt :: UTCTime
    }
    deriving (Show, Eq)

data UserResponse = UserResponse
    { userResponseId :: Text
    , userResponseName :: Text
    , userResponseEmail :: Text
    , userResponseStatus :: Text -- "pending", "active", "inactive"
    , userResponseRoles :: [Text]
    , userResponseCreatedAt :: UTCTime
    , userResponseUpdatedAt :: Maybe UTCTime
    }
    deriving (Show, Eq)

data RoleResponse = RoleResponse
    { roleResponseId :: Text
    , roleResponseName :: Text
    , roleResponseDescription :: Text
    , roleResponsePermissions :: [Text]
    }
    deriving (Show, Eq)

data PermissionResponse = PermissionResponse
    { permissionResponseId :: Text
    , permissionResponseName :: Text
    , permissionResponseResource :: Text
    , permissionResponseAction :: Text
    , permissionResponseDescription :: Maybe Text
    }
    deriving (Show, Eq)

data UserListResponse = UserListResponse
    { userListItems :: [UserResponse]
    , userListTotal :: Int
    , userListOffset :: Int
    , userListLimit :: Int
    }
    deriving (Show, Eq)
