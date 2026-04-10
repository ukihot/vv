module Application.User.Boundary.Input.ActivateUserUseCase where

import Application.User.DTOs.Request.ActivateUserRequest (ActivateUserRequest)

-- | 入力境界。戻り値は () (Unit)。
class (Monad m) => ActivateUserUseCase m where
  execute :: ActivateUserRequest -> m ()