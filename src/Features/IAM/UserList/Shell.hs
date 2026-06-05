{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserList.Shell (
    runEffect,
) where

import App.DTO.Response.IAM (UserListResponse (..))
import App.Ports.Query.IAM (ListUsersRequest (..))
import App.UseCase.IAM.ListUsers qualified as ListUsers
import Control.Concurrent.STM (atomically, modifyTVar')
import Data.Text (Text)
import Data.Text qualified as T
import Features.IAM.UserList.Core (UserListEffect (..))
import Fw.Types qualified as Fw

runEffect :: Fw.Env -> UserListEffect -> IO UserListResponse
runEffect env = \case
    LoadUsers mFilter offset limit -> do
        appendLog env "Loading users..."
        result <- ListUsers.executeListUsers (mkListUsersEnv env) (ListUsersRequest mFilter offset limit)
        appendLog env ("Users loaded: " <> showTotal result <> " users found")
        pure result

mkListUsersEnv :: Fw.Env -> ListUsers.ListUsersEnv IO
mkListUsersEnv env =
    ListUsers.ListUsersEnv
        { ListUsers.envQueryAllUsers = Fw.envQueryAllUsers env
        , ListUsers.envQueryUsersByFilter = Fw.envQueryUsersByFilter env
        }

showTotal :: UserListResponse -> Text
showTotal = T.pack . show . userListTotal

appendLog :: Fw.Env -> Text -> IO ()
appendLog env message =
    atomically $ modifyTVar' (Fw.envLogs env) (<> [message])
