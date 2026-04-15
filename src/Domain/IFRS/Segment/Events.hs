module Domain.IFRS.Segment.Events (
    SegmentEventPayload (..),
)
where

import Data.Text (Text)
import Domain.IFRS.Segment.ValueObjects.SegmentId (SegmentId)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (Symbol)

data SegmentEventPayload (currency :: Symbol)
    = -- | セグメント作成 → 管理会計レポート
      SegmentCreated SegmentId Text
    | -- | セグメント業績記録 → 管理会計レポート、予算管理
      SegmentResultRecorded SegmentId FiscalYearMonth (Money currency) (Money currency)
    | -- | セグメント再編 → AuditTrail集約
      SegmentReorganized SegmentId SegmentId Text
    deriving (Show, Eq)
