module Domain.IFRS.Segment.Events
    ( SegmentEventPayload (..)
    )
where

import Domain.IFRS.Segment.ValueObjects.SegmentId (SegmentId)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (Symbol)

data SegmentEventPayload (currency :: Symbol)
    = SegmentResultRecorded SegmentId FiscalYearMonth (Money currency) (Money currency)
    deriving (Show, Eq)
