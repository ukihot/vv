module App.UseCase.IAM
    ( executeActivateUser
    )
where

import App.DTO.Request (ActivateUserRequest (..))
import App.Ports.Output (ActivateUserPort (..))
import Domain.IAM.User (activateUser)
import Domain.IAM.User.Repository (UserRepository (..))
import Domain.IAM.User.ValueObjects.UserId (mkUserId)

executeActivateUser ::
    (UserRepository m, ActivateUserPort m) =>
    ActivateUserRequest ->
    m ()
executeActivateUser (ActivateUserRequest rawId) =
    case mkUserId rawId of
        Left err -> presentFailure err
        Right userId -> do
            loaded <- loadUser userId
            case loaded of
                Left err -> presentFailure err
                Right pendingUser -> do
                    let (activeUser, _) = activateUser pendingUser
                    saved <- saveUser activeUser
                    case saved of
                        Left err -> presentFailure err
                        Right () -> presentSuccess activeUser
