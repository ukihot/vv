{-# LANGUAGE ImportQualifiedPost #-}

{- | IAM Presenter
App.Ports.Output の具体実装。
UseCaseからの通知を受け取り、表示用の状態を更新する。
-}
module Adapter.Presenter.IAM
    ( presentActivateUserSuccess
    , presentActivateUserFailure
    , presentActivateUserProgress
    )
where

import Adapter.Env (AppM, Env (..))
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask)
import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.User (User, getUserId)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.ValueObjects.UserId (unUserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (Active))

-- ─────────────────────────────────────────────────────────────────────────────
-- Presenter関数: Output Portの具体実装
-- ─────────────────────────────────────────────────────────────────────────────

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
