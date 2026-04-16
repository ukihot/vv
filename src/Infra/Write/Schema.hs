{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

{- | persistent ORM スキーマ定義
WRITE 側（SQLite）のテーブル定義。
CQRS 原則に従い、イベントストアとして機能する。
-}
module Infra.Write.Schema where

import Data.Text (Text)
import Data.Time (UTCTime)
import Database.Persist.TH

-- ─────────────────────────────────────────────────────────────────────────────
-- IAM イベントストア
-- ─────────────────────────────────────────────────────────────────────────────

share
    [mkPersist sqlSettings, mkMigrate "migrateAll"]
    [persistLowerCase|

-- ユーザーイベントストア（append-only）
UserEvent
    aggregateId  Text          -- UserId
    version      Int           -- 楽観ロック用シーケンス番号
    eventType    Text          -- "UserRegistered" | "UserActivated" | ...
    payload      Text          -- JSON シリアライズされたイベントペイロード
    recordedAt   UTCTime       -- 記録時刻 (#56)
    deriving Show

-- ロールイベントストア（append-only）
RoleEvent
    aggregateId  Text          -- RoleId
    version      Int
    eventType    Text
    payload      Text
    recordedAt   UTCTime
    deriving Show

-- パーミッションイベントストア（append-only）
PermissionEvent
    aggregateId  Text          -- PermissionId
    version      Int
    eventType    Text
    payload      Text
    recordedAt   UTCTime
    deriving Show
|]
