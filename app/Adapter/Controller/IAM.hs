{-# LANGUAGE ImportQualifiedPost #-}

{- | IAM Controller
生データ（Text等）を受け取り、DTOに変換してCommandを実行する。
ファットコントローラは禁止。ビジネスロジックは含まない。
出力・表示処理は一切行わない（Presenterの責務）。
-}
module Adapter.Controller.IAM (
    handleRegisterUser,
    handleActivateUser,
)
where

import Adapter.Env (AppM, Env (..), runAppM)
import Adapter.Presenter.IAM (presentRegisterUserFailure, presentRegisterUserSuccess)
import App.DTO.Request (ActivateUserRequest (..), RegisterUserRequest (..))
import App.DTO.Response.IAM (UserResponse (..))
import App.UseCase.IAM.Internal qualified
import App.UseCase.IAM.RegisterUser (executeRegisterUser)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask)
import Data.Text (Text)
import Domain.IAM.Permission.Errors qualified as PermError
import Domain.IAM.Role.Errors qualified as RoleError
import Domain.IAM.User (User, activateUser)
import Domain.IAM.User.Errors (DomainError)
import Domain.IAM.User.ValueObjects.UserId (UserId (..), mkUserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))

-- ─────────────────────────────────────────────────────────────────────────────
-- Controller関数: 生データ → DTO → Command実行
-- ─────────────────────────────────────────────────────────────────────────────

{- | ユーザー登録コントローラ
責務:
  1. 生データ（Text）を受け取る
  2. DTOに変換
  3. UseCaseを実行

禁止事項:
  - ビジネスロジック
  - バリデーション（スマートコンストラクタに委譲）
  - 状態管理
  - 出力・表示処理（Presenterの責務）
-}
handleRegisterUser :: Text -> Text -> Text -> AppM ()
handleRegisterUser rawName rawEmail rawRole = do
    -- 生データをDTOに変換
    let request = RegisterUserRequest rawName rawEmail rawRole

    -- 本番仕様: IAMEnvを構築してUseCaseを実行
    env <- ask
    let iamEnv = mkIAMEnv env
    liftIO $ executeRegisterUser iamEnv request

{- | ユーザー有効化コントローラ
責務:
  1. 生データ（Text）を受け取る
  2. DTOに変換
  3. Commandを実行（具体的なUseCaseは知らない）

禁止事項:
  - ビジネスロジック
  - バリデーション（スマートコンストラクタに委譲）
  - 状態管理
  - 出力・表示処理（Presenterの責務）
-}
handleActivateUser :: Text -> AppM ()
handleActivateUser rawUserId = do
    -- 生データをDTOに変換
    let request = ActivateUserRequest rawUserId

    -- Command実行（スタブ実装）
    -- TODO: 本番では App.Ports.Command を通じてUseCaseを実行
    executeActivateUserStub request

-- ─────────────────────────────────────────────────────────────────────────────
-- IAMEnv構築: Adapter.Env → App.UseCase.IAM.Internal.IAMEnv
-- ─────────────────────────────────────────────────────────────────────────────

mkIAMEnv :: Env -> App.UseCase.IAM.Internal.IAMEnv IO
mkIAMEnv env =
    App.UseCase.IAM.Internal.IAMEnv
        { App.UseCase.IAM.Internal.envLoadUser = envLoadUser env
        , App.UseCase.IAM.Internal.envSaveUser = envSaveUser env
        , App.UseCase.IAM.Internal.envAppendUserEvent = envAppendUserEvent env
        , App.UseCase.IAM.Internal.envLoadRole = \_ -> pure $ Left (RoleError.RepositoryError "Not implemented")
        , App.UseCase.IAM.Internal.envSaveRole = \_ -> pure $ Right ()
        , App.UseCase.IAM.Internal.envAppendRoleEvent = \_ _ -> pure $ Right ()
        , App.UseCase.IAM.Internal.envLoadPermission = \_ -> pure $ Left (PermError.RepositoryError "Not implemented")
        , App.UseCase.IAM.Internal.envCurrentActorId = case mkUserId "system" of
            Right uid -> uid
            Left _ -> error "Invalid system user ID" -- TODO: 認証コンテキストから取得
        , App.UseCase.IAM.Internal.envPresentSuccess = \response ->
            -- UseCase層からPresenterを直接呼び出し（IO monadで実行）
            runAppM env $ presentRegisterUserSuccess response
        , App.UseCase.IAM.Internal.envPresentFailure = \msg ->
            runAppM env $ presentRegisterUserFailure msg
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- スタブ実装: 本番ではUseCaseに置き換え
-- ─────────────────────────────────────────────────────────────────────────────

executeActivateUserStub :: ActivateUserRequest -> AppM ()
executeActivateUserStub (ActivateUserRequest rawId) = do
    env <- ask

    -- スマートコンストラクタでバリデーション
    case mkUserId rawId of
        Left _err -> do
            -- エラーハンドリングはUseCaseに委譲すべき
            -- TODO: 本番ではUseCaseを通じて処理
            pure ()
        Right userId -> do
            -- Repository呼び出し（スタブ）
            -- 型注釈で 'Pending を明示
            loaded <- liftIO $ (envLoadUser env userId :: IO (Either DomainError (User 'Pending)))

            case loaded of
                Left _err -> do
                    -- エラーハンドリングはUseCaseに委譲すべき
                    pure ()
                Right pendingUser -> do
                    -- ドメインロジック実行
                    let (activeUser, _event) = activateUser pendingUser

                    -- Repository保存（スタブ）
                    _saved <- liftIO $ envSaveUser env activeUser
                    pure ()
