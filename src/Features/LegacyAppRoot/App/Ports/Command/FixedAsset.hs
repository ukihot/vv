module App.Ports.Command.FixedAsset (
    RegisterFixedAssetUseCase (..),
    CalculateDepreciationUseCase (..),
    PerformAssetImpairmentTestUseCase (..),
    DisposeFixedAssetUseCase (..),
    TransferFromCIPUseCase (..),
    RevaluateAssetUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Fixed Asset Management (固定資産管理)
-- ============================================================================

class Monad m => RegisterFixedAssetUseCase m where
    executeRegisterFixedAsset :: Text -> Day -> Double -> Int -> Text -> m (Either Text Text)

-- assetName, acquisitionDate, cost, usefulLife, depreciationMethod -> assetId

class Monad m => CalculateDepreciationUseCase m where
    executeCalculateDepreciation :: Text -> Day -> m (Either Text Double)

-- assetId, date -> depreciationAmount

class Monad m => PerformAssetImpairmentTestUseCase m where
    executePerformAssetImpairmentTest :: Text -> Day -> m (Either Text (Bool, Double))

-- assetId, date -> (isImpaired, impairmentLoss)

class Monad m => DisposeFixedAssetUseCase m where
    executeDisposeFixedAsset :: Text -> Day -> Double -> Text -> m (Either Text Text)

-- assetId, disposalDate, disposalAmount, reason -> disposalId

class Monad m => TransferFromCIPUseCase m where
    executeTransferFromCIP :: Text -> Day -> [Text] -> m (Either Text Text)

-- cipId, transferDate, componentIds -> transferId

class Monad m => RevaluateAssetUseCase m where
    executeRevaluateAsset :: Text -> Day -> Double -> Text -> m (Either Text Text)

-- assetId, revaluationDate, revaluedAmount, basis -> revaluationId
