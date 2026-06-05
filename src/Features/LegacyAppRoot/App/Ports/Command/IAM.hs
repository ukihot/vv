module App.Ports.Command.IAM (
    LoginUseCase (..),
    LogoutUseCase (..),
    RegisterUserUseCase (..),
    ActivateUserUseCase (..),
    DeactivateUserUseCase (..),
    AssignRoleUseCase (..),
    RevokeRoleUseCase (..),
    GrantPermissionUseCase (..),
    RevokePermissionUseCase (..),
)
where

import App.DTO.Request.IAM

-- ============================================================================
-- IAM Command Use Cases
-- Command: RequestDTO -> m ()
-- ============================================================================

class Monad m => LoginUseCase m where
    executeLogin :: LoginRequest -> m ()

class Monad m => LogoutUseCase m where
    executeLogout :: () -> m () -- No request needed, token from context

class Monad m => RegisterUserUseCase m where
    executeRegisterUser :: RegisterUserRequest -> m ()

class Monad m => ActivateUserUseCase m where
    executeActivateUser :: ActivateUserRequest -> m ()

class Monad m => DeactivateUserUseCase m where
    executeDeactivateUser :: DeactivateUserRequest -> m ()

class Monad m => AssignRoleUseCase m where
    executeAssignRole :: AssignRoleRequest -> m ()

class Monad m => RevokeRoleUseCase m where
    executeRevokeRole :: RevokeRoleRequest -> m ()

class Monad m => GrantPermissionUseCase m where
    executeGrantPermission :: GrantPermissionRequest -> m ()

class Monad m => RevokePermissionUseCase m where
    executeRevokePermission :: RevokePermissionRequest -> m ()
