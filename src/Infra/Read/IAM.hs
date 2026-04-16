{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

{- | acid-state による IAM Read モデル（インメモリ・マテリアライズドビュー）
CQRS の Read 側。SQLite のイベントを適用して構築されるインメモリ状態。
クエリは純粋な Haskell 関数として記述できる。
-}
module Infra.Read.IAM (
    -- * 状態型
    IamReadModel (..),
    UserRecord (..),
    RoleRecord (..),
    PermissionRecord (..),

    -- * acid-state トランザクション
    GetUserRecord (..),
    GetRoleRecord (..),
    GetPermissionRecord (..),
    ApplyUserEvent (..),
    ApplyRoleEvent (..),
    ApplyPermissionEvent (..),
    GetLastUserSeq (..),
    GetLastRoleSeq (..),
    GetLastPermissionSeq (..),

    -- * 初期状態
    emptyIamReadModel,
) where

import Control.Monad.Reader (ask)
import Control.Monad.State (get, put)
import Data.Acid (Query, Update, makeAcidic)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.SafeCopy (base, deriveSafeCopy)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Typeable (Typeable)

-- ─────────────────────────────────────────────────────────────────────────────
-- Read モデルのレコード型
-- ─────────────────────────────────────────────────────────────────────────────

data UserRecord = UserRecord
    { urId :: Text
    , urName :: Text
    , urEmail :: Text
    , urStatus :: Text -- "pending" | "active" | "suspended" | "inactive"
    , urRoles :: [Text] -- RoleId のリスト
    , urVersion :: Int
    }
    deriving stock (Show, Eq, Typeable)

data RoleRecord = RoleRecord
    { rrId :: Text
    , rrName :: Text
    , rrStatus :: Text -- "draft" | "active" | "inactive"
    , rrPermissions :: [Text] -- PermissionId のリスト
    , rrVersion :: Int
    }
    deriving stock (Show, Eq, Typeable)

data PermissionRecord = PermissionRecord
    { prId :: Text
    , prName :: Text
    , prCode :: Text
    , prStatus :: Text -- "draft" | "active" | "retired"
    , prVersion :: Int
    }
    deriving stock (Show, Eq, Typeable)

-- ─────────────────────────────────────────────────────────────────────────────
-- Read モデル全体
-- ─────────────────────────────────────────────────────────────────────────────

data IamReadModel = IamReadModel
    { irmUsers :: Map Text UserRecord
    , irmRoles :: Map Text RoleRecord
    , irmPermissions :: Map Text PermissionRecord
    , -- 最終反映済みシーケンス番号（再起動時のリプレイ差分計算用）
      irmLastUserSeq :: Int
    , irmLastRoleSeq :: Int
    , irmLastPermissionSeq :: Int
    }
    deriving stock (Show, Typeable)

emptyIamReadModel :: IamReadModel
emptyIamReadModel = IamReadModel Map.empty Map.empty Map.empty 0 0 0

-- ─────────────────────────────────────────────────────────────────────────────
-- SafeCopy インスタンス（acid-state の永続化に必要）
-- ─────────────────────────────────────────────────────────────────────────────

$(deriveSafeCopy 0 'base ''UserRecord)
$(deriveSafeCopy 0 'base ''RoleRecord)
$(deriveSafeCopy 0 'base ''PermissionRecord)
$(deriveSafeCopy 0 'base ''IamReadModel)

-- ─────────────────────────────────────────────────────────────────────────────
-- Query トランザクション（純粋な読み取り）
-- ─────────────────────────────────────────────────────────────────────────────

getUserRecord :: Text -> Query IamReadModel (Maybe UserRecord)
getUserRecord uid = Map.lookup uid . irmUsers <$> ask

getRoleRecord :: Text -> Query IamReadModel (Maybe RoleRecord)
getRoleRecord rid = Map.lookup rid . irmRoles <$> ask

getPermissionRecord :: Text -> Query IamReadModel (Maybe PermissionRecord)
getPermissionRecord pid = Map.lookup pid . irmPermissions <$> ask

getLastUserSeq :: Query IamReadModel Int
getLastUserSeq = irmLastUserSeq <$> ask

getLastRoleSeq :: Query IamReadModel Int
getLastRoleSeq = irmLastRoleSeq <$> ask

getLastPermissionSeq :: Query IamReadModel Int
getLastPermissionSeq = irmLastPermissionSeq <$> ask

-- ─────────────────────────────────────────────────────────────────────────────
-- Update トランザクション（イベント適用）
-- 引数は既にシリアライズ済みの (eventType, payload) ペア。
-- ドメイン型（EventPayload）を acid-state の引数に取らないことで、
-- ドメイン層に SafeCopy 依存を持ち込まない。
-- ─────────────────────────────────────────────────────────────────────────────

applyUserEvent :: Int -> Text -> Text -> Update IamReadModel ()
applyUserEvent seq' eventType payload = do
    model <- get
    -- 順序チェック: 期待するシーケンス番号と一致する場合のみ適用（冪等性保証）
    let expected = irmLastUserSeq model + 1
    if seq' /= expected
        then pure () -- 重複または順序違いは無視
        else do
            let users' = applyToUsersRaw (irmUsers model) eventType payload
            put model {irmUsers = users', irmLastUserSeq = seq'}

applyRoleEvent :: Int -> Text -> Text -> Update IamReadModel ()
applyRoleEvent seq' eventType payload = do
    model <- get
    let expected = irmLastRoleSeq model + 1
    if seq' /= expected
        then pure ()
        else do
            let roles' = applyToRolesRaw (irmRoles model) eventType payload
            put model {irmRoles = roles', irmLastRoleSeq = seq'}

applyPermissionEvent :: Int -> Text -> Text -> Update IamReadModel ()
applyPermissionEvent seq' eventType payload = do
    model <- get
    let expected = irmLastPermissionSeq model + 1
    if seq' /= expected
        then pure ()
        else do
            let perms' = applyToPermissionsRaw (irmPermissions model) eventType payload
            put model {irmPermissions = perms', irmLastPermissionSeq = seq'}

-- ─────────────────────────────────────────────────────────────────────────────
-- イベント適用ロジック（純粋関数・シリアライズ済みテキストから直接適用）
-- ─────────────────────────────────────────────────────────────────────────────

applyToUsersRaw :: Map Text UserRecord -> Text -> Text -> Map Text UserRecord
applyToUsersRaw m eventType payload =
    let cols = T.splitOn "|" payload
     in case (eventType, cols) of
            ("UserRegistered", [uid, name, email]) ->
                Map.insert
                    uid
                    UserRecord
                        { urId = uid
                        , urName = name
                        , urEmail = email
                        , urStatus = "pending"
                        , urRoles = []
                        , urVersion = 1
                        }
                    m
            ("UserActivated", [uid]) -> bump uid (\r -> r {urStatus = "active"}) m
            ("UserSuspended", [uid]) -> bump uid (\r -> r {urStatus = "suspended"}) m
            ("UserUnsuspended", [uid]) -> bump uid (\r -> r {urStatus = "active"}) m
            ("UserDeactivated", uid : _) -> bump uid (\r -> r {urStatus = "inactive"}) m
            ("UserEmailCorrected", [uid, email]) -> bump uid (\r -> r {urEmail = email}) m
            ("UserNameCorrected", [uid, name]) -> bump uid (\r -> r {urName = name}) m
            ("UserRoleAssigned", [uid, rid]) ->
                bump uid (\r -> r {urRoles = urRoles r <> [rid]}) m
            ("UserRoleRevoked", [uid, rid]) ->
                bump uid (\r -> r {urRoles = filter (/= rid) (urRoles r)}) m
            _ -> m
    where
        bump uid f = Map.adjust (\r -> (f r) {urVersion = urVersion r + 1}) uid

applyToRolesRaw :: Map Text RoleRecord -> Text -> Text -> Map Text RoleRecord
applyToRolesRaw m eventType payload =
    let cols = T.splitOn "|" payload
     in case (eventType, cols) of
            ("RoleCreated", [rid, name]) ->
                Map.insert
                    rid
                    RoleRecord
                        { rrId = rid
                        , rrName = name
                        , rrStatus = "draft"
                        , rrPermissions = []
                        , rrVersion = 1
                        }
                    m
            ("RoleActivated", [_, rid]) -> bump rid (\r -> r {rrStatus = "active"}) m
            ("RoleDeactivated", [_, rid]) -> bump rid (\r -> r {rrStatus = "inactive"}) m
            ("PermissionAssignedToRole", [_, rid, pid]) ->
                bump rid (\r -> r {rrPermissions = rrPermissions r <> [pid]}) m
            ("PermissionRevokedFromRole", [_, rid, pid]) ->
                bump rid (\r -> r {rrPermissions = filter (/= pid) (rrPermissions r)}) m
            _ -> m
    where
        bump rid f = Map.adjust (\r -> (f r) {rrVersion = rrVersion r + 1}) rid

applyToPermissionsRaw :: Map Text PermissionRecord -> Text -> Text -> Map Text PermissionRecord
applyToPermissionsRaw m eventType payload =
    let cols = T.splitOn "|" payload
     in case (eventType, cols) of
            ("PermissionDefined", [pid, name, code]) ->
                Map.insert
                    pid
                    PermissionRecord
                        { prId = pid
                        , prName = name
                        , prCode = code
                        , prStatus = "draft"
                        , prVersion = 1
                        }
                    m
            ("PermissionActivated", [_, pid]) -> bump pid (\r -> r {prStatus = "active"}) m
            ("PermissionRetired", [_, pid]) -> bump pid (\r -> r {prStatus = "retired"}) m
            _ -> m
    where
        bump pid f = Map.adjust (\r -> (f r) {prVersion = prVersion r + 1}) pid

-- ─────────────────────────────────────────────────────────────────────────────
-- acid-state TH マクロ
-- ─────────────────────────────────────────────────────────────────────────────

$( makeAcidic
    ''IamReadModel
    [ 'getUserRecord
    , 'getRoleRecord
    , 'getPermissionRecord
    , 'getLastUserSeq
    , 'getLastRoleSeq
    , 'getLastPermissionSeq
    , 'applyUserEvent
    , 'applyRoleEvent
    , 'applyPermissionEvent
    ]
 )
