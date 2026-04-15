module Domain.IFRS.Impairment.Repository (
    ImpairmentRepository (..),
)
where

import Data.Time (Day)
import Domain.IFRS.Impairment (ImpairmentTest)
import Domain.IFRS.Impairment.ValueObjects.CguId (CguId)
import Domain.IFRS.Impairment.ValueObjects.ImpairmentTestId (ImpairmentTestId)

class Monad m => ImpairmentRepository m currency where
    saveImpairmentTest :: ImpairmentTest currency -> m ()
    findImpairmentTestById :: ImpairmentTestId -> m (Maybe (ImpairmentTest currency))
    findImpairmentTestsByCgu :: CguId -> Day -> m [ImpairmentTest currency]
