module Domain.IFRS.FinancialInstrument.Repository
    ( FinancialInstrumentRepository (..)
    )
where

import Domain.IFRS.FinancialInstrument (SomeFinancialAsset)
import Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (FinancialAssetId)

class Monad m => FinancialInstrumentRepository m currency where
    saveFinancialAsset :: SomeFinancialAsset currency -> m ()
    findFinancialAssetById :: FinancialAssetId -> m (Maybe (SomeFinancialAsset currency))
