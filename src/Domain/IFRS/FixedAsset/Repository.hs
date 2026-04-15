module Domain.IFRS.FixedAsset.Repository
    ( FixedAssetRepository (..)
    )
where

import Domain.IFRS.FixedAsset (FixedAsset)
import Domain.IFRS.FixedAsset.ValueObjects.FixedAssetId (FixedAssetId)
import Domain.IFRS.Impairment.ValueObjects.CguId (CguId)

class Monad m => FixedAssetRepository m currency where
    saveFixedAsset :: FixedAsset currency -> m ()
    findFixedAssetById :: FixedAssetId -> m (Maybe (FixedAsset currency))
    findFixedAssetsByCgu :: CguId -> m [FixedAsset currency]
