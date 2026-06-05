module App.Ports.Output.IAM (
    LoginOutputPort (..),
    RegisterUserOutputPort (..),
    ActivateUserOutputPort (..),
    DeactivateUserOutputPort (..),
    UserListOutputPort (..),
    UserDetailOutputPort (..),
    RoleListOutputPort (..),
    PermissionListOutputPort (..),
)
where

import App.DTO.Response.IAM
import Data.Text (Text)

-- ============================================================================
-- IAM Output Ports (画面ごとのプレゼンター)
-- ============================================================================

-- | Login画面用OutputPort
class Monad m => LoginOutputPort m where
    presentLoginSuccess :: LoginResponse -> m ()
    presentLoginFailure :: Text -> m ()

-- | ユーザー登録画面用OutputPort
class Monad m => RegisterUserOutputPort m where
    presentRegisterUserSuccess :: UserResponse -> m ()
    presentRegisterUserFailure :: Text -> m ()

-- | ユーザー有効化画面用OutputPort
class Monad m => ActivateUserOutputPort m where
    presentActivateUserSuccess :: UserResponse -> m ()
    presentActivateUserFailure :: Text -> m ()

-- | ユーザー無効化画面用OutputPort
class Monad m => DeactivateUserOutputPort m where
    presentDeactivateUserSuccess :: UserResponse -> m ()
    presentDeactivateUserFailure :: Text -> m ()

-- | ユーザー一覧画面用OutputPort
class Monad m => UserListOutputPort m where
    presentUserList :: UserListResponse -> m ()
    presentUserListFailure :: Text -> m ()

-- | ユーザー詳細画面用OutputPort
class Monad m => UserDetailOutputPort m where
    presentUserDetail :: UserResponse -> m ()
    presentUserDetailFailure :: Text -> m ()

-- | ロール一覧画面用OutputPort
class Monad m => RoleListOutputPort m where
    presentRoleList :: [RoleResponse] -> m ()
    presentRoleListFailure :: Text -> m ()

-- | 権限一覧画面用OutputPort
class Monad m => PermissionListOutputPort m where
    presentPermissionList :: [PermissionResponse] -> m ()
    presentPermissionListFailure :: Text -> m ()
