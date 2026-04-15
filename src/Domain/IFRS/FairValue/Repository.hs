module Domain.IFRS.FairValue.Repository
    ( FairValueRepository (..)
    )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.FairValue (FairValueMeasurement)
import Domain.IFRS.FairValue.ValueObjects.FairValueMeasurementId (FairValueMeasurementId)

class Monad m => FairValueRepository m currency where
    saveFairValueMeasurement :: FairValueMeasurement currency -> m ()
    findFairValueMeasurementById :: FairValueMeasurementId -> m (Maybe (FairValueMeasurement currency))
    findFairValueMeasurementsByAsset :: Text -> Day -> m [FairValueMeasurement currency]
