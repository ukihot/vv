module Domain.IFRS.Segment.ValueObjects.SegmentId (
    SegmentId (..),
    mkSegmentId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Segment.Errors (SegmentError (..))

newtype SegmentId = SegmentId {unSegmentId :: Text}
    deriving stock (Show, Eq, Ord)

mkSegmentId :: Text -> Either SegmentError SegmentId
mkSegmentId t
    | T.null t = Left InvalidSegmentId
    | otherwise = Right (SegmentId t)
