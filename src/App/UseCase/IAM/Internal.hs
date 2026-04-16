{-# LANGUAGE ScopedTypeVariables #-}

{- | IAM ユースケース共通基盤
#45, #46: 型クラス DI を廃止し、依存を Env レコードの値として渡す。
依存の出所がコードに直接現れ、テスト時の差し替えも明示的になる。
-}
module App.UseCase.IAM.Internal (
    -- * 環境レコード
    IAMEnv (..),

    -- * User ドメイン用モナドスタック
    UserAppM,
    runUserAppM,
    liftUserDomain,

    -- * Role ドメイン用モナドスタック
    RoleAppM,
    runRoleAppM,
    liftRoleDomain,

    -- * ヘルパー
    toUserResponse,
) where

import App.DTO.Response.IAM (UserResponse (..))
import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Control.Monad.Reader (ReaderT, ask, runReaderT)
import Control.Monad.Trans.Class (lift)
import Data.Text (Text)
import Domain.IAM.Permission (Permission)
import Domain.IAM.Permission.Errors qualified as PermError
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId)
import Domain.IAM.Role (Role)
import Domain.IAM.Role.Errors qualified as RoleError
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
import Domain.IAM.User (User)
import Domain.IAM.User.Entities.Profile (UserProfile (..))
import Domain.IAM.User.Errors (DomainError)
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.ValueObjects.Email (unEmail)
import Domain.IAM.User.ValueObjects.UserId (UserId, unUserId)
import Domain.IAM.User.ValueObjects.UserName (unUserName)
import Domain.IAM.User.ValueObjects.UserState (UserState, userStateToText)

-- ─────────────────────────────────────────────────────────────────────────────
-- Env レコード (#45, #46)
-- フィールドが依存の一覧になる。何に依存しているかが一目で分かる。
-- ─────────────────────────────────────────────────────────────────────────────

data IAMEnv m = IAMEnv
    { -- User 集約
      envLoadUser :: forall s. UserId -> m (Either DomainError (User s))
    , envSaveUser :: forall s. User s -> m (Either DomainError ())
    , envAppendUserEvent :: UserId -> UserEventPayload -> m (Either DomainError ())
    , -- Role 集約
      envLoadRole :: forall s. RoleId -> m (Either RoleError.DomainError (Role s))
    , envSaveRole :: forall s. Role s -> m (Either RoleError.DomainError ())
    , -- Permission 集約
      envLoadPermission :: forall s. PermissionId -> m (Either PermError.DomainError (Permission s))
    , -- 認証コンテキスト (#25: 誰が操作したかを監査証跡に含める)
      envCurrentActorId :: UserId
    , -- OutputPort（プレゼンター）
      envPresentSuccess :: UserResponse -> m ()
    , envPresentFailure :: Text -> m ()
    }

-- ─────────────────────────────────────────────────────────────────────────────
-- User ドメイン用モナドスタック（DomainError = User.DomainError）
-- ─────────────────────────────────────────────────────────────────────────────

type UserAppM m = ExceptT DomainError (ReaderT (IAMEnv m) m)

runUserAppM :: IAMEnv m -> UserAppM m a -> m (Either DomainError a)
runUserAppM env action = runReaderT (runExceptT action) env

liftUserDomain :: Monad m => m (Either DomainError a) -> UserAppM m a
liftUserDomain action = do
    result <- lift (lift action)
    case result of
        Left err -> throwError err
        Right val -> pure val

-- ─────────────────────────────────────────────────────────────────────────────
-- Role ドメイン用モナドスタック（DomainError = Role.DomainError）
-- ─────────────────────────────────────────────────────────────────────────────

type RoleAppM m = ExceptT RoleError.DomainError (ReaderT (IAMEnv m) m)

runRoleAppM :: IAMEnv m -> RoleAppM m a -> m (Either RoleError.DomainError a)
runRoleAppM env action = runReaderT (runExceptT action) env

liftRoleDomain :: Monad m => m (Either RoleError.DomainError a) -> RoleAppM m a
liftRoleDomain action = do
    result <- lift (lift action)
    case result of
        Left err -> throwError err
        Right val -> pure val

-- ─────────────────────────────────────────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────────────────────────────────────────

-- | User 集約 → 外部 DTO 変換（Adapter 層への橋渡し）
toUserResponse :: UserId -> UserProfile -> UserState -> UserResponse
toUserResponse uid profile state =
    UserResponse
        { userResponseId = unUserId uid
        , userResponseName = unUserName (profileName profile)
        , userResponseEmail = unEmail (profileEmail profile)
        , userResponseStatus = userStateToText state
        , userResponseRoles = [] -- TODO: ロール情報を含める
        , userResponseCreatedAt = undefined -- TODO: 実際の値
        , userResponseUpdatedAt = Nothing
        }
