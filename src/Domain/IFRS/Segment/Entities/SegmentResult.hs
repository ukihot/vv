module Domain.IFRS.Segment.Entities.SegmentResult (
    SegmentResult (..),
)
where

import Domain.IFRS.Segment.ValueObjects.SegmentId (SegmentId)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (Symbol)

data SegmentResult (currency :: Symbol) = SegmentResult
    { srSegmentId :: SegmentId
    , srPeriod :: FiscalYearMonth
    , srRevenue :: Money currency
    , srCost :: Money currency
    }
    deriving (Show, Eq)
