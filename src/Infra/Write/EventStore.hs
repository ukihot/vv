{- | SQLite イベントストア
persistent ORM を使って IAM イベントを append-only で永続化する。
CQRS: load（rehydrate 用）と append のみ。検索系は一切持たない。
-}
module Infra.Write.EventStore (
    appendUserEvent,
    loadUserEvents,
    appendRoleEvent,
    loadRoleEvents,
    appendPermissionEvent,
    loadPermissionEvents,
    runDb,
) where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Text (Text)
import Data.Time (getCurrentTime)
import Database.Persist (Entity (..))
import Database.Persist.Sqlite (
    ConnectionPool,
    SqlPersistT,
    insert_,
    runSqlPool,
    selectList,
    (==.),
 )
import Domain.IAM.Permission.Events (PermissionEventPayload)
import Domain.IAM.Permission.ValueObjects.PermissionId (PermissionId, unPermissionId)
import Domain.IAM.Role.Events (RoleEventPayload)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId, unRoleId)
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.ValueObjects.UserId (UserId, unUserId)
import Infra.Write.Schema
import Infra.Write.Serialise (
    decodePermissionEvent,
    decodeRoleEvent,
    decodeUserEvent,
    encodePermissionEvent,
    encodeRoleEvent,
    encodeUserEvent,
 )

-- | DB アクションを実行するヘルパー
runDb :: MonadIO m => ConnectionPool -> SqlPersistT IO a -> m a
runDb pool action = liftIO $ runSqlPool action pool

-- ─────────────────────────────────────────────────────────────────────────────
-- User
-- ─────────────────────────────────────────────────────────────────────────────

appendUserEvent ::
    MonadIO m =>
    ConnectionPool ->
    UserId ->
    Int -> -- 現在のバージョン（楽観ロック）
    UserEventPayload ->
    m (Either Text ())
appendUserEvent pool uid version payload = do
    now <- liftIO getCurrentTime
    let (eventType, encoded) = encodeUserEvent payload
    runDb pool $
        insert_
            UserEvent
                { userEventAggregateId = unUserId uid
                , userEventVersion = version
                , userEventEventType = eventType
                , userEventPayload = encoded
                , userEventRecordedAt = now
                }
    pure $ Right ()

loadUserEvents ::
    MonadIO m =>
    ConnectionPool ->
    UserId ->
    m [UserEventPayload]
loadUserEvents pool uid = do
    rows <-
        runDb pool $
            selectList [UserEventAggregateId ==. unUserId uid] []
    pure $ concatMap (decodeUserEvent . entityVal) rows

-- ─────────────────────────────────────────────────────────────────────────────
-- Role
-- ─────────────────────────────────────────────────────────────────────────────

appendRoleEvent ::
    MonadIO m =>
    ConnectionPool ->
    RoleId ->
    Int ->
    RoleEventPayload ->
    m (Either Text ())
appendRoleEvent pool rid version payload = do
    now <- liftIO getCurrentTime
    let (eventType, encoded) = encodeRoleEvent payload
    runDb pool $
        insert_
            RoleEvent
                { roleEventAggregateId = unRoleId rid
                , roleEventVersion = version
                , roleEventEventType = eventType
                , roleEventPayload = encoded
                , roleEventRecordedAt = now
                }
    pure $ Right ()

loadRoleEvents ::
    MonadIO m =>
    ConnectionPool ->
    RoleId ->
    m [RoleEventPayload]
loadRoleEvents pool rid = do
    rows <-
        runDb pool $
            selectList [RoleEventAggregateId ==. unRoleId rid] []
    pure $ concatMap (decodeRoleEvent . entityVal) rows

-- ─────────────────────────────────────────────────────────────────────────────
-- Permission
-- ─────────────────────────────────────────────────────────────────────────────

appendPermissionEvent ::
    MonadIO m =>
    ConnectionPool ->
    PermissionId ->
    Int ->
    PermissionEventPayload ->
    m (Either Text ())
appendPermissionEvent pool pid version payload = do
    now <- liftIO getCurrentTime
    let (eventType, encoded) = encodePermissionEvent payload
    runDb pool $
        insert_
            PermissionEvent
                { permissionEventAggregateId = unPermissionId pid
                , permissionEventVersion = version
                , permissionEventEventType = eventType
                , permissionEventPayload = encoded
                , permissionEventRecordedAt = now
                }
    pure $ Right ()

loadPermissionEvents ::
    MonadIO m =>
    ConnectionPool ->
    PermissionId ->
    m [PermissionEventPayload]
loadPermissionEvents pool pid = do
    rows <-
        runDb pool $
            selectList [PermissionEventAggregateId ==. unPermissionId pid] []
    pure $ concatMap (decodePermissionEvent . entityVal) rows
