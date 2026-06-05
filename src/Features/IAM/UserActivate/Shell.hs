{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserActivate.Shell (
    runEffect,
) where

import Control.Concurrent.STM (atomically, modifyTVar')
import Data.Text (Text)
import Domain.IAM.User (User, activateUser, getUserId)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.ValueObjects.UserId (mkUserId, unUserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))
import Features.IAM.UserActivate.Core (UserActivateEffect (..))
import Fw.Types qualified as Fw

runEffect :: Fw.Env -> UserActivateEffect -> IO ()
runEffect env = \case
    ActivateUser rawUserId -> activate env rawUserId
    ReportValidationError message -> appendLog env ("[ERROR] " <> message)

activate :: Fw.Env -> Text -> IO ()
activate env rawUserId =
    case mkUserId rawUserId of
        Left err ->
            appendLog env ("[ERROR] " <> Fw.formatDomainError err)
        Right userId -> do
            loaded <- Fw.envLoadUser env userId :: IO (Either DomainError (User 'Pending))
            case loaded of
                Left err ->
                    appendLog env ("[ERROR] " <> Fw.formatDomainError err)
                Right pendingUser -> do
                    let (activeUser, _event) = activateUser pendingUser
                    saved <- Fw.envSaveUser env activeUser
                    case saved of
                        Left err ->
                            appendLog env ("[ERROR] " <> Fw.formatDomainError err)
                        Right () ->
                            appendLog env ("[SUCCESS] User activated: " <> unUserId (getUserId activeUser))

appendLog :: Fw.Env -> Text -> IO ()
appendLog env message =
    atomically $ modifyTVar' (Fw.envLogs env) (<> [message])
