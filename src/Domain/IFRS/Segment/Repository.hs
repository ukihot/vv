module Domain.IFRS.Segment.Repository
    ( SegmentRepository (..)
    )
where

import Domain.IFRS.Segment (Segment)
import Domain.IFRS.Segment.Entities.SegmentResult (SegmentResult)
import Domain.IFRS.Segment.ValueObjects.SegmentId (SegmentId)
import Domain.Shared (FiscalYearMonth)

class Monad m => SegmentRepository m currency where
    saveSegment :: Segment -> m ()
    findSegmentById :: SegmentId -> m (Maybe Segment)
    saveSegmentResult :: SegmentResult currency -> m ()
    findSegmentResultsByPeriod :: SegmentId -> FiscalYearMonth -> m [SegmentResult currency]
