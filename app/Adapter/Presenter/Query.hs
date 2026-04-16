{-# LANGUAGE ImportQualifiedPost #-}

{- | Query Presenter
クエリ結果の表示用プレゼンター。
成功・失敗・進捗を適切に報告する。
-}
module Adapter.Presenter.Query (
    presentListUsersSuccess,
    presentListUsersFailure,
    presentListUsersProgress,
) where

import Adapter.Env (AppM, Env (..))
import App.DTO.Response.IAM (UserListResponse (..))
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask)
import Data.Text (Text)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Query Presenter関数
-- ─────────────────────────────────────────────────────────────────────────────

presentListUsersSuccess :: UserListResponse -> AppM ()
presentListUsersSuccess response = do
    env <- ask
    let message = "Users loaded: " <> T.pack (show (userListTotal response)) <> " users found"
    liftIO $ envPresentProgress env message

presentListUsersFailure :: Text -> AppM ()
presentListUsersFailure msg = do
    env <- ask
    liftIO $ envPresentProgress env ("[ERROR] Failed to load users: " <> msg)

presentListUsersProgress :: Text -> AppM ()
presentListUsersProgress msg = do
    env <- ask
    liftIO $ envPresentProgress env msg
