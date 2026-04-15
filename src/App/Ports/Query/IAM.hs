module App.Ports.Query.IAM (
    FindUserByIdQuery (..),
    FindUserByEmailQuery (..),
    ListUsersQuery (..),
    ListRolesQuery (..),
    ListPermissionsQuery (..),
    CheckPermissionQuery (..),
    -- Request DTOs
    FindUserByIdRequest (..),
    FindUserByEmailRequest (..),
    ListUsersRequest (..),
    CheckPermissionRequest (..),
)
where

import App.DTO.Response.IAM
import Data.Text (Text)

-- ============================================================================
-- IAM Query Use Cases
-- Query: RequestDTO -> m ResponseDTO
-- ============================================================================

-- Request DTOs for Queries
data FindUserByIdRequest = FindUserByIdRequest
    { findUserByIdReqUserId :: Text
    }
    deriving (Show, Eq)

data FindUserByEmailRequest = FindUserByEmailRequest
    { findUserByEmailReqEmail :: Text
    }
    deriving (Show, Eq)

data ListUsersRequest = ListUsersRequest
    { listUsersReqFilter :: Maybe Text
    , listUsersReqOffset :: Int
    , listUsersReqLimit :: Int
    }
    deriving (Show, Eq)

data CheckPermissionRequest = CheckPermissionRequest
    { checkPermReqUserId :: Text
    , checkPermReqPermissionName :: Text
    }
    deriving (Show, Eq)

-- Query Use Cases
class Monad m => FindUserByIdQuery m where
    executeFindUserById :: FindUserByIdRequest -> m (Maybe UserResponse)

class Monad m => FindUserByEmailQuery m where
    executeFindUserByEmail :: FindUserByEmailRequest -> m (Maybe UserResponse)

class Monad m => ListUsersQuery m where
    executeListUsers :: ListUsersRequest -> m UserListResponse

class Monad m => ListRolesQuery m where
    executeListRoles :: () -> m [RoleResponse]

class Monad m => ListPermissionsQuery m where
    executeListPermissions :: Maybe Text -> m [PermissionResponse] -- roleId filter

class Monad m => CheckPermissionQuery m where
    executeCheckPermission :: CheckPermissionRequest -> m Bool
