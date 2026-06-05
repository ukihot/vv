{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE RankNTypes #-}

module Fw.Types (
    Env (..),
    mkEnv,
    formatDomainError,
) where

import Control.Concurrent.STM (TVar, atomically, modifyTVar')
import Control.Monad.Logger (runNoLoggingT)
import Data.Acid (openLocalState, query)
import Data.Text (Text)
import Data.Text qualified as T
import Database.Persist.Sqlite (createSqlitePool, runMigration, runSqlPool)
import Domain.IAM.User (User (..))
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.Repository (UserHandle (..))
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Infra.Read.IAM (
    GetAllUsers (..),
    GetUsersByFilter (..),
    UserRecord,
    emptyIamReadModel,
 )
import Infra.Repositories.IAM (IamRepoEnv (..), mkUserHandle)
import Infra.Write.Projection (newProjectionQueue, replayFromSqlite, startIamProjector)
import Infra.Write.Schema (migrateAll)
import System.Directory (createDirectoryIfMissing)

data Env = Env
    { envLoadUser :: forall s. UserId -> IO (Either DomainError (User s))
    , envSaveUser :: forall s. User s -> IO (Either DomainError ())
    , envAppendUserEvent :: UserId -> UserEventPayload -> IO (Either DomainError ())
    , envQueryAllUsers :: IO [UserRecord]
    , envQueryUsersByFilter :: Text -> IO [UserRecord]
    , envLogs :: TVar [Text]
    }

mkEnv :: TVar [Text] -> IO Env
mkEnv logsVar = do
    createDirectoryIfMissing True "data"

    pool <- runNoLoggingT $ createSqlitePool "data/vv.db" 10
    runSqlPool (runMigration migrateAll) pool

    acidState <- openLocalState emptyIamReadModel
    replayFromSqlite pool acidState

    projectionQueue <- newProjectionQueue
    startIamProjector acidState projectionQueue

    let repoEnv =
            IamRepoEnv
                { envPool = pool
                , envAcidState = acidState
                , envProjectionQueue = Just projectionQueue
                }
        userHandle = mkUserHandle repoEnv

    atomically $ modifyTVar' logsVar (<> ["Application started. Press 'h' for help."])

    pure
        Env
            { envLoadUser = loadUser userHandle
            , envSaveUser = saveUser userHandle
            , envAppendUserEvent = appendUserEvent userHandle
            , envQueryAllUsers = query acidState GetAllUsers
            , envQueryUsersByFilter = \filterText -> query acidState (GetUsersByFilter filterText)
            , envLogs = logsVar
            }

formatDomainError :: DomainError -> Text
formatDomainError err = case err of
    InvalidUserId -> "Invalid user ID"
    InvalidUserName -> "Invalid user name"
    InvalidEmail -> "Invalid email"
    DuplicateEmail -> "Duplicate email"
    IllegalTransition -> "Illegal state transition"
    AlreadyActivated -> "Already activated"
    UserIsInactive -> "User is inactive"
    RepositoryError msg -> "Repository error: " <> T.pack msg
