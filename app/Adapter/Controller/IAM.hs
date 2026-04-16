{-# LANGUAGE ImportQualifiedPost #-}

{- | IAM Controller
生データ（Text等）を受け取り、DTOに変換してCommandを実行する。
ファットコントローラは禁止。ビジネスロジックは含まない。
-}
module Adapter.Controller.IAM (
    handleActivateUser,
)
where

import Adapter.Env (AppM, Env (..))
import Adapter.Presenter.IAM (
    presentActivateUserFailure,
    presentActivateUserProgress,
    presentActivateUserSuccess,
 )
import App.DTO.Request (ActivateUserRequest (..))
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask)
import Data.Text (Text)
import Domain.IAM.User (User, activateUser)
import Domain.IAM.User.Errors (DomainError)
import Domain.IAM.User.ValueObjects.UserId (mkUserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))

-- ─────────────────────────────────────────────────────────────────────────────
-- Controller関数: 生データ → DTO → Command実行
-- ─────────────────────────────────────────────────────────────────────────────

{- | ユーザー有効化コントローラ
責務:
  1. 生データ（Text）を受け取る
  2. DTOに変換
  3. Commandを実行（具体的なUseCaseは知らない）
  4. 結果をPresenterに委譲

禁止事項:
  - ビジネスロジック
  - バリデーション（スマートコンストラクタに委譲）
  - 状態管理
-}
handleActivateUser :: Text -> AppM ()
handleActivateUser rawUserId = do
    -- 進捗報告
    presentActivateUserProgress "Starting user activation..."

    -- 生データをDTOに変換
    let request = ActivateUserRequest rawUserId

    -- Command実行（スタブ実装）
    -- TODO: 本番では App.Ports.Command を通じてUseCaseを実行
    executeActivateUserStub request

-- ─────────────────────────────────────────────────────────────────────────────
-- スタブ実装: 本番ではUseCaseに置き換え
-- ─────────────────────────────────────────────────────────────────────────────

executeActivateUserStub :: ActivateUserRequest -> AppM ()
executeActivateUserStub (ActivateUserRequest rawId) = do
    env <- ask

    -- スマートコンストラクタでバリデーション
    case mkUserId rawId of
        Left err -> do
            presentActivateUserFailure err
        Right userId -> do
            presentActivateUserProgress "Loading user..."

            -- Repository呼び出し（スタブ）
            -- 型注釈で 'Pending を明示
            loaded <- liftIO $ (envLoadUser env userId :: IO (Either DomainError (User 'Pending)))

            case loaded of
                Left err -> do
                    presentActivateUserFailure err
                Right pendingUser -> do
                    presentActivateUserProgress "Activating user..."

                    -- ドメインロジック実行
                    let (activeUser, _event) = activateUser pendingUser

                    -- Repository保存（スタブ）
                    saved <- liftIO $ envSaveUser env activeUser

                    case saved of
                        Left err -> do
                            presentActivateUserFailure err
                        Right () -> do
                            presentActivateUserSuccess activeUser
