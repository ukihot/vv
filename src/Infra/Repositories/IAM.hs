{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

{- | IAM リポジトリ実装
Handle パターン (#45, #46) で UserHandle / RoleHandle / PermissionHandle を構築する。
型クラスインスタンスは使わない。

WRITE: SQLite（persistent）に append-only でイベントを永続化
READ:  イベント列から rehydrate して集約を復元

CQRS: load / save / appendEvent のみ。検索系は一切持たない。

NOTE: loadUser / loadRole / loadPermission は `forall s.` を要求するが、
rehydrate が返す SomeUser の内部状態 s1 と呼び出し側の s は別の型変数。
Application 層が正しい状態を要求することを前提に unsafeCoerce で型消去を戻す。
状態の不一致は実行時に RepositoryError として表面化する。
-}
module Infra.Repositories.IAM (
    IamRepoEnv (..),
    mkUserHandle,
    mkRoleHandle,
    mkPermissionHandle,
) where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Acid (AcidState)
import Database.Persist.Sqlite (ConnectionPool)
import Domain.IAM.Permission (SomePermission (..), rehydratePermission)
import Domain.IAM.Permission.Errors qualified as PermErr
import Domain.IAM.Permission.Repository (PermissionHandle (..))
import Domain.IAM.Role (SomeRole (..), rehydrateRole)
import Domain.IAM.Role.Errors qualified as RoleErr
import Domain.IAM.Role.Repository (RoleHandle (..))
import Domain.IAM.User (SomeUser (..), rehydrate)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Repository (UserHandle (..))
import Infra.Read.IAM (IamReadModel)
import Infra.Write.EventStore qualified as ES
import Infra.Write.Projection (ProjectionQueue)
import Unsafe.Coerce (unsafeCoerce)

-- ─────────────────────────────────────────────────────────────────────────────
-- 環境レコード
-- ─────────────────────────────────────────────────────────────────────────────

data IamRepoEnv = IamRepoEnv
    { envPool :: ConnectionPool
    , envAcidState :: AcidState IamReadModel
    , envProjectionQueue :: Maybe ProjectionQueue
    }

-- ─────────────────────────────────────────────────────────────────────────────
-- UserHandle 構築
-- ─────────────────────────────────────────────────────────────────────────────

mkUserHandle :: MonadIO m => IamRepoEnv -> UserHandle m
mkUserHandle env =
    UserHandle
        { loadUser = \uid -> do
            events <- liftIO $ ES.loadUserEvents (envPool env) uid
            case events of
                [] -> pure $ Left (RepositoryError "User not found")
                _ -> case rehydrate events of
                    Left err -> pure $ Left err
                    Right (SomeUser user) -> pure $ Right (unsafeCoerce user)
        , -- unsafeCoerce: SomeUser の内部状態 s1 を呼び出し側の s に合わせる。
          -- Application 層が正しい状態を要求することを前提とする。

          saveUser = \_ -> pure $ Right ()
        , appendUserEvent = \uid payload -> do
            events <- liftIO $ ES.loadUserEvents (envPool env) uid
            let nextVer = length events
            result <- liftIO $ ES.appendUserEvent (envPool env) (envProjectionQueue env) uid nextVer payload
            pure $ either (Left . RepositoryError . show) Right result
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- RoleHandle 構築
-- ─────────────────────────────────────────────────────────────────────────────

mkRoleHandle :: MonadIO m => IamRepoEnv -> RoleHandle m
mkRoleHandle env =
    RoleHandle
        { loadRole = \rid -> do
            events <- liftIO $ ES.loadRoleEvents (envPool env) rid
            case events of
                [] -> pure $ Left (RoleErr.RepositoryError "Role not found")
                _ -> case rehydrateRole events of
                    Left _ -> pure $ Left (RoleErr.RepositoryError "Role rehydration failed")
                    Right (SomeRole role) -> pure $ Right (unsafeCoerce role)
        , saveRole = \_ -> pure $ Right ()
        , appendRoleEvent = \rid payload -> do
            events <- liftIO $ ES.loadRoleEvents (envPool env) rid
            let nextVer = length events
            result <- liftIO $ ES.appendRoleEvent (envPool env) (envProjectionQueue env) rid nextVer payload
            pure $ either (Left . RoleErr.RepositoryError . show) Right result
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- PermissionHandle 構築
-- ─────────────────────────────────────────────────────────────────────────────

mkPermissionHandle :: MonadIO m => IamRepoEnv -> PermissionHandle m
mkPermissionHandle env =
    PermissionHandle
        { loadPermission = \pid -> do
            events <- liftIO $ ES.loadPermissionEvents (envPool env) pid
            case events of
                [] -> pure $ Left (PermErr.RepositoryError "Permission not found")
                _ -> case rehydratePermission events of
                    Left _ -> pure $ Left (PermErr.RepositoryError "Permission rehydration failed")
                    Right (SomePermission perm) -> pure $ Right (unsafeCoerce perm)
        , savePermission = \_ -> pure $ Right ()
        , appendPermissionEvent = \pid payload -> do
            events <- liftIO $ ES.loadPermissionEvents (envPool env) pid
            let nextVer = length events
            result <-
                liftIO $ ES.appendPermissionEvent (envPool env) (envProjectionQueue env) pid nextVer payload
            pure $ either (Left . PermErr.RepositoryError . show) Right result
        }
