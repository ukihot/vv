{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserRegister.Shell (
    runEffect,
) where

import App.DTO.Request.IAM (RegisterUserRequest (..))
import App.DTO.Response.IAM (UserResponse (..))
import App.UseCase.IAM.Internal qualified as IAM
import App.UseCase.IAM.RegisterUser (executeRegisterUser)
import Control.Concurrent.STM (atomically, modifyTVar')
import Data.Text (Text)
import Domain.IAM.Permission.Errors qualified as PermError
import Domain.IAM.Role.Errors qualified as RoleError
import Domain.IAM.User.ValueObjects.UserId (mkUserId)
import Features.IAM.UserRegister.Core (UserRegisterEffect (..))
import Fw.Types qualified as Fw

runEffect :: Fw.Env -> UserRegisterEffect -> IO ()
runEffect env = \case
    RegisterUser name email role ->
        executeRegisterUser (mkIAMEnv env) (RegisterUserRequest name email role)
    ReportValidationError message ->
        appendLog env ("[ERROR] " <> message)

mkIAMEnv :: Fw.Env -> IAM.IAMEnv IO
mkIAMEnv env =
    IAM.IAMEnv
        { IAM.envLoadUser = Fw.envLoadUser env
        , IAM.envSaveUser = Fw.envSaveUser env
        , IAM.envAppendUserEvent = Fw.envAppendUserEvent env
        , IAM.envLoadRole = \_ -> pure $ Left (RoleError.RepositoryError "Not implemented")
        , IAM.envSaveRole = \_ -> pure $ Right ()
        , IAM.envAppendRoleEvent = \_ _ -> pure $ Right ()
        , IAM.envLoadPermission = \_ -> pure $ Left (PermError.RepositoryError "Not implemented")
        , IAM.envCurrentActorId = case mkUserId "system" of
            Right uid -> uid
            Left _ -> error "Invalid system user ID"
        , IAM.envPresentSuccess = \response ->
            appendLog env (formatSuccess response)
        , IAM.envPresentFailure = \message ->
            appendLog env ("[ERROR] " <> message)
        }

formatSuccess :: UserResponse -> Text
formatSuccess response =
    "User registered: " <> userResponseId response <> " (" <> userResponseName response <> ")"

appendLog :: Fw.Env -> Text -> IO ()
appendLog env message =
    atomically $ modifyTVar' (Fw.envLogs env) (<> [message])
