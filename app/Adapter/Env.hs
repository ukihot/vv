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

import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO, readTVar)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Reader (ReaderT, runReaderT)
import Data.Map.Strict qualified as M
import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.User (User (..))
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.Services.Factory (registerUser)
import Domain.IAM.User.ValueObjects.Email (mkEmail)
import Domain.IAM.User.ValueObjects.UserId (UserId, unUserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))
import Unsafe.Coerce (unsafeCoerce)

-- ─────────────────────────────────────────────────────────────────────────────
-- 依存レコード: すべての依存を明示的に定義（TUI版）
-- ─────────────────────────────────────────────────────────────────────────────

data Env = Env
    { -- Repository Port (Write側) - 現在はスタブ実装
      envLoadUser :: forall s. UserId -> IO (Either DomainError (User s))
    , envSaveUser :: forall s. User s -> IO (Either DomainError ())
    , envAppendUserEvent :: UserId -> UserEventPayload -> IO (Either DomainError ())
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
-- Env構築（本番仕様対応）
-- ─────────────────────────────────────────────────────────────────────────────

mkEnv :: TVar [Text] -> IO Env
mkEnv logsVar = do
    -- 現在はスタブ実装（インメモリ）
    -- TODO: 本番では以下を初期化
    -- - SQLite ConnectionPool
    -- - acid-state IamReadModel
    -- - ProjectionQueue + Projector threads
    usersRef <- newTVarIO M.empty

    pure
        Env
            { envLoadUser = \uid -> do
                -- TODO: 本番ではSQLite EventStoreから読み込み
                -- 現在はスタブ実装（インメモリ）
                users <- atomically $ readTVar usersRef
                case M.lookup (unUserId uid) users of
                    Nothing -> do
                        -- ユーザーが存在しない場合、新規作成可能として空を返す
                        pure $ Left (RepositoryError "User not found")
                    Just (StoredPending user) -> pure $ Right (unsafeCoerce user)
                    Just (StoredActive user) -> pure $ Right (unsafeCoerce user)
                    Just (StoredSuspended user) -> pure $ Right (unsafeCoerce user)
                    Just (StoredInactive user) -> pure $ Right (unsafeCoerce user)
            , envSaveUser = \user -> do
                -- TODO: 本番ではSQLite EventStoreに書き込み
                atomically $ modifyTVar' usersRef (M.insert (unUserId (getUserId user)) (toStoredUser user))
                atomically $ modifyTVar' logsVar (<> ["[REPO] User saved: " <> unUserId (getUserId user)])
                pure $ Right ()
            , envAppendUserEvent = \uid payload -> do
                -- TODO: 本番ではEventStoreに永続化
                atomically $
                    modifyTVar' logsVar (<> ["[EVENT] " <> T.pack (show payload) <> " for user " <> unUserId uid])
                pure $ Right ()
            , envPresentSuccess = \user -> do
                atomically $ modifyTVar' logsVar (<> ["[SUCCESS] User activated: " <> unUserId (getUserId user)])
            , envPresentFailure = \err -> do
                atomically $ modifyTVar' logsVar (<> ["[ERROR] " <> formatError err])
            , envPresentProgress = \msg -> do
                atomically $ modifyTVar' logsVar (<> ["[INFO] " <> msg])
            , envLogs = logsVar
            }

-- ─────────────────────────────────────────────────────────────────────────────
-- スタブ用のストレージ型
-- ─────────────────────────────────────────────────────────────────────────────

data StoredUser
    = StoredPending (User 'Pending)
    | StoredActive (User 'Active)
    | StoredSuspended (User 'Suspended)
    | StoredInactive (User 'Inactive)

toStoredUser :: User s -> StoredUser
toStoredUser user@(UserP _ _ _ _) = StoredPending user
toStoredUser user@(UserA _ _ _ _) = StoredActive user
toStoredUser user@(UserS _ _ _ _) = StoredSuspended user
toStoredUser user@(UserI _ _ _ _) = StoredInactive user

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
