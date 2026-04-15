module App.Ports.Command
    ( ActivateUserUseCase (..)
    )
where

import App.DTO.Request (ActivateUserRequest)

class Monad m => ActivateUserUseCase m where
    execute :: ActivateUserRequest -> m ()
