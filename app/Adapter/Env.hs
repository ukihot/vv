{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE RankNTypes #-}

{- | アプリケーション環境（本番仕様）
ReaderT Envパターンによる明示的な依存注入。
型クラスDIを廃止し、依存を値として扱う。

本番仕様:
- SQLite EventStore (Write)
- acid-state ReadModel (Read)
- 非同期Projection
- Handle パターンでのリポジトリ注入
-}
module Adapter.Env (
    Env (..),
    AppM,
    runAppM,
    mkEnv,
)
where

import Control.Concurrent.STM (TVar, atomically, modifyTVar')
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (runNoLoggingT)
import Control.Monad.Reader (ReaderT, runReaderT)
import Data.Acid (AcidState, openLocalState, query)
import Data.Text (Text)
import Data.Text qualified as T
import Database.Persist.Sqlite (createSqlitePool, runMigration, runSqlPool)
import Domain.IAM.User (User (..))
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.Repository (UserHandle (..))
import Domain.IAM.User.ValueObjects.UserId (UserId, unUserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))
import Infra.Read.IAM (
    GetAllUsers (..),
    GetUsersByFilter (..),
    IamReadModel,
    UserRecord,
    emptyIamReadModel,
 )
import Infra.Repositories.IAM (IamRepoEnv (..), mkUserHandle)
import Infra.Write.EventStore qualified as ES
import Infra.Write.Projection (newProjectionQueue, replayFromSqlite, startIamProjector)
import Infra.Write.Schema (migrateAll)
import System.Directory (createDirectoryIfMissing)

-- ─────────────────────────────────────────────────────────────────────────────
-- 依存レコード: すべての依存を明示的に定義（本番仕様）
-- ─────────────────────────────────────────────────────────────────────────────

data Env = Env
    { -- Repository Port (Write側) - 本番SQLite実装
      envLoadUser :: forall s. UserId -> IO (Either DomainError (User s))
    , envSaveUser :: forall s. User s -> IO (Either DomainError ())
    , envAppendUserEvent :: UserId -> UserEventPayload -> IO (Either DomainError ())
    , -- Query Port (Read側) - acid-state ReadModel
      envQueryAllUsers :: IO [UserRecord]
    , envQueryUsersByFilter :: Text -> IO [UserRecord]
    , -- Output Port (Presenter側) - TUI用
      envPresentSuccess :: User 'Active -> IO ()
    , envPresentFailure :: DomainError -> IO ()
    , envPresentProgress :: Text -> IO ()
    , -- 共有状態（ログ出力用）
      envLogs :: TVar [Text]
    }

-- ─────────────────────────────────────────────────────────────────────────────
-- AppM: ReaderT Env IO
-- ─────────────────────────────────────────────────────────────────────────────

type AppM = ReaderT Env IO

runAppM :: Env -> AppM a -> IO a
runAppM env action = runReaderT action env

-- ─────────────────────────────────────────────────────────────────────────────
-- Env構築（本番仕様SQLite実装）
-- ─────────────────────────────────────────────────────────────────────────────

mkEnv :: TVar [Text] -> IO Env
mkEnv logsVar = do
    -- データディレクトリ作成
    createDirectoryIfMissing True "data"

    -- 本番仕様: SQLite + acid-state 初期化（ログ無効化でUI保護）
    pool <- runNoLoggingT $ createSqlitePool "data/vv.db" 10

    -- EventStore テーブル初期化
    runSqlPool (runMigration migrateAll) pool

    -- acid-state ReadModel 初期化
    acidState <- openLocalState emptyIamReadModel

    -- 再起動時リプレイ（SQLiteとacid-stateの差分を同期）
    replayFromSqlite pool acidState

    -- Projection Queue初期化
    projectionQueue <- newProjectionQueue

    -- Projectorスレッド起動（非同期でEventをReadModelに反映）
    startIamProjector acidState projectionQueue

    -- Repository環境構築
    let repoEnv =
            IamRepoEnv
                { envPool = pool
                , envAcidState = acidState
                , envProjectionQueue = Just projectionQueue -- Projection有効化
                }

    -- UserHandle構築
    let userHandle = mkUserHandle repoEnv

    pure
        Env
            { envLoadUser = loadUser userHandle
            , envSaveUser = saveUser userHandle
            , envAppendUserEvent = appendUserEvent userHandle
            , -- Query Port実装（acid-state ReadModel）
              envQueryAllUsers = query acidState GetAllUsers
            , envQueryUsersByFilter = \filterText -> query acidState (GetUsersByFilter filterText)
            , envPresentSuccess = \user -> do
                atomically $ modifyTVar' logsVar (<> ["[SUCCESS] User activated: " <> unUserId (getUserId user)])
            , envPresentFailure = \err -> do
                atomically $ modifyTVar' logsVar (<> ["[ERROR] " <> formatError err])
            , envPresentProgress = \msg -> do
                atomically $ modifyTVar' logsVar (<> ["[INFO] " <> msg])
            , envLogs = logsVar
            }

-- ─────────────────────────────────────────────────────────────────────────────
-- ヘルパー関数
-- ─────────────────────────────────────────────────────────────────────────────

getUserId :: User s -> UserId
getUserId (UserP uid _ _ _) = uid
getUserId (UserA uid _ _ _) = uid
getUserId (UserS uid _ _ _) = uid
getUserId (UserI uid _ _ _) = uid

formatError :: DomainError -> Text
formatError err = case err of
    InvalidUserId -> "Invalid user ID"
    InvalidUserName -> "Invalid user name"
    InvalidEmail -> "Invalid email"
    DuplicateEmail -> "Duplicate email"
    IllegalTransition -> "Illegal state transition"
    AlreadyActivated -> "Already activated"
    UserIsInactive -> "User is inactive"
    RepositoryError msg -> "Repository error: " <> T.pack msg
