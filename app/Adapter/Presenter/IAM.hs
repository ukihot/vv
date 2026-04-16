{-# LANGUAGE ImportQualifiedPost #-}

{- | IAM Presenter
App.Ports.Output の具体実装。
UseCaseからの通知を受け取り、表示用の状態を更新する。
-}
module Adapter.Presenter.IAM (
    presentActivateUserSuccess,
    presentActivateUserFailure,
    presentActivateUserProgress,
    presentRegisterUserSuccess,
    presentRegisterUserFailure,
    presentRegisterUserProgress,
)
where

import Adapter.Env (AppM, Env (..))
import App.DTO.Response.IAM (UserResponse (..))
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask)
import Data.Text (Text)
import Domain.IAM.User (User)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.ValueObjects.UserState (UserState (Active))

-- ─────────────────────────────────────────────────────────────────────────────
-- Presenter関数: Output Portの具体実装
-- ─────────────────────────────────────────────────────────────────────────────

presentRegisterUserSuccess :: UserResponse -> AppM ()
presentRegisterUserSuccess response = do
    env <- ask
    -- UserResponse → 表示用メッセージに変換（Presenter層の責務）
    let message = "User registered: " <> userResponseId response <> " (" <> userResponseName response <> ")"
    liftIO $ envPresentProgress env message

presentRegisterUserFailure :: Text -> AppM ()
presentRegisterUserFailure msg = do
    env <- ask
    liftIO $ envPresentProgress env ("[ERROR] " <> msg)

presentRegisterUserProgress :: Text -> AppM ()
presentRegisterUserProgress msg = do
    env <- ask
    liftIO $ envPresentProgress env msg

presentActivateUserSuccess :: User 'Active -> AppM ()
presentActivateUserSuccess user = do
    env <- ask
    liftIO $ envPresentSuccess env user

presentActivateUserFailure :: DomainError -> AppM ()
presentActivateUserFailure err = do
    env <- ask
    liftIO $ envPresentFailure env err

presentActivateUserProgress :: Text -> AppM ()
presentActivateUserProgress msg = do
    env <- ask
    liftIO $ envPresentProgress env msg
