-- | セグメント情報 (IFRS 8準拠)
-- 管理会計変換原則 §6.2 に基づき、
-- 制度表示区分に拘束されないセグメント別損益を管理する。
module Domain.IFRS.Segment
  ( -- * セグメント識別子
    SegmentId (..),
    mkSegmentId,

    -- * セグメント
    Segment (..),
    SegmentResult (..),

    -- * エラー
    SegmentError (..),
  )
where

import Data.Text (Text)
import Domain.Shared (FiscalYearMonth, Money (..))
import GHC.TypeLits (Symbol)

newtype SegmentId = SegmentId {unSegmentId :: Text}
  deriving (Show, Eq, Ord)

mkSegmentId :: Text -> Either SegmentError SegmentId
mkSegmentId t
  | null (show t) = Left InvalidSegmentId
  | otherwise = Right (SegmentId t)

data Segment = Segment
  { segmentId :: SegmentId,
    segmentName :: Text
  }
  deriving (Show, Eq)

-- | セグメント別損益結果
data SegmentResult (currency :: Symbol) = SegmentResult
  { srSegmentId :: SegmentId,
    srPeriod :: FiscalYearMonth,
    srRevenue :: Money currency,
    srCost :: Money currency
  }
  deriving (Show, Eq)

data SegmentError
  = InvalidSegmentId
  deriving (Show, Eq)
