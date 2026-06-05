{- | 監査証跡集約ルートエンティティ
すべての重要な操作を記録し、監査可能性を保証する。
-}
module Domain.Audit.AuditTrail (
    -- * 集約
    AuditTrail (..),
    recordAuditTrail,

    -- * 値オブジェクト
    module Domain.Audit.AuditTrail.ValueObjects.AuditTrailId,
    module Domain.Audit.AuditTrail.ValueObjects.AuditAction,
)
where

import Data.Text (Text)
import Data.Time (UTCTime)
import Domain.Audit.AuditTrail.ValueObjects.AuditAction
import Domain.Audit.AuditTrail.ValueObjects.AuditTrailId
import Domain.Audit.AuditTrail.ValueObjects.Version (Version, initialVersion)
import Domain.IAM.User.ValueObjects.UserId (UserId)

-- ─────────────────────────────────────────────────────────────────────────────
-- 監査証跡集約
-- ─────────────────────────────────────────────────────────────────────────────

data AuditTrail = AuditTrail
    { auditTrailId :: AuditTrailId
    , auditEntityId :: Text
    -- ^ 操作対象エンティティID
    , auditEntityType :: Text
    -- ^ 操作対象エンティティ種別
    , auditAction :: AuditAction
    -- ^ 操作種別
    , auditActorId :: UserId
    -- ^ 操作実行者
    , auditTimestamp :: UTCTime
    -- ^ 操作日時
    , auditBeforeValue :: Maybe Text
    -- ^ 変更前の値（JSON等）
    , auditAfterValue :: Maybe Text
    -- ^ 変更後の値（JSON等）
    , auditNote :: Maybe Text
    -- ^ 備考
    , auditVersion :: Version
    }
    deriving stock (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- ファクトリ
-- ─────────────────────────────────────────────────────────────────────────────

recordAuditTrail ::
    AuditTrailId ->
    Text ->
    Text ->
    AuditAction ->
    UserId ->
    UTCTime ->
    Maybe Text ->
    Maybe Text ->
    Maybe Text ->
    AuditTrail
recordAuditTrail atId entityId entityType action actorId timestamp beforeVal afterVal note =
    AuditTrail
        { auditTrailId = atId
        , auditEntityId = entityId
        , auditEntityType = entityType
        , auditAction = action
        , auditActorId = actorId
        , auditTimestamp = timestamp
        , auditBeforeValue = beforeVal
        , auditAfterValue = afterVal
        , auditNote = note
        , auditVersion = initialVersion
        }
