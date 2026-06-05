module App.Ports.Command.Valuation (
    CalculateAllowanceForDoubtfulAccountsUseCase (..),
    AssessECLStageUseCase (..),
    CalculateECLUseCase (..),
    PerformImpairmentTestUseCase (..),
    MeasureFairValueUseCase (..),
    CalculateNRVUseCase (..),
    MeasureProvisionUseCase (..),
    TranslateForeignCurrencyUseCase (..),
    ApplyHedgeAccountingUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Valuation Processing (評価処理)
-- ============================================================================

class Monad m => CalculateAllowanceForDoubtfulAccountsUseCase m where
    executeCalculateAllowanceForDoubtfulAccounts :: Day -> m (Either Text Text)

-- date -> allowanceId

class Monad m => AssessECLStageUseCase m where
    executeAssessECLStage :: Text -> Day -> m (Either Text Int)

-- receivableId, date -> stage (1/2/3)

class Monad m => CalculateECLUseCase m where
    executeCalculateECL :: Text -> Int -> Double -> Double -> Double -> m (Either Text Double)

-- receivableId, stage, pd, lgd, ead -> ecl

class Monad m => PerformImpairmentTestUseCase m where
    executePerformImpairmentTest :: Text -> Day -> m (Either Text (Bool, Double))

-- assetId, date -> (isImpaired, impairmentLoss)

class Monad m => MeasureFairValueUseCase m where
    executeMeasureFairValue :: Text -> Day -> Text -> m (Either Text Double)

-- assetId, date, valuationTechnique -> fairValue

class Monad m => CalculateNRVUseCase m where
    executeCalculateNRV :: Text -> Day -> m (Either Text Double)

-- inventoryId, date -> nrv

class Monad m => MeasureProvisionUseCase m where
    executeMeasureProvision :: Text -> Double -> Double -> m (Either Text Double)

-- obligationType, estimatedAmount, probability -> provisionAmount

class Monad m => TranslateForeignCurrencyUseCase m where
    executeTranslateForeignCurrency :: Text -> Text -> Day -> Double -> m (Either Text Double)

-- fromCurrency, toCurrency, date, amount -> translatedAmount

class Monad m => ApplyHedgeAccountingUseCase m where
    executeApplyHedgeAccounting :: Text -> Text -> Day -> m (Either Text Text)

-- hedgeItemId, hedgedItemId, date -> hedgeRelationshipId
