module Domain.IFRS.Segment.Errors (
    SegmentError (..),
)
where

data SegmentError
    = InvalidSegmentId
    deriving (Show, Eq)
