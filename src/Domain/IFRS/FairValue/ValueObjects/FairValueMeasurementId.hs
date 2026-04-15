module Domain.IFRS.FairValue.ValueObjects.FairValueMeasurementId (
    FairValueMeasurementId (..),
    mkFairValueMeasurementId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.FairValue.Errors (FairValueError (..))

newtype FairValueMeasurementId = FairValueMeasurementId {unFairValueMeasurementId :: Text}
    deriving (Show, Eq, Ord)

mkFairValueMeasurementId :: Text -> Either FairValueError FairValueMeasurementId
mkFairValueMeasurementId t
    | T.null t = Left InvalidFairValueMeasurementId
    | otherwise = Right (FairValueMeasurementId t)
