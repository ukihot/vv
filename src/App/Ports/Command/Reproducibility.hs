module App.Ports.Command.Reproducibility (
    SaveCalculationParametersUseCase (..),
    SaveIntermediateCalculationUseCase (..),
    RecalculateFromHistoryUseCase (..),
    VerifyReproducibilityUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (UTCTime)

-- ============================================================================
-- Reproducibility (再現性保証 - 規程第7章対応)
-- ============================================================================

class Monad m => SaveCalculationParametersUseCase m where
    executeSaveCalculationParameters :: Text -> Text -> UTCTime -> m (Either Text Text)

-- calculationType, parameters, timestamp -> parameterId

class Monad m => SaveIntermediateCalculationUseCase m where
    executeSaveIntermediateCalculation :: Text -> Text -> Text -> m (Either Text Text)

-- calculationId, step, intermediateValue -> recordId

class Monad m => RecalculateFromHistoryUseCase m where
    executeRecalculateFromHistory :: Text -> UTCTime -> m (Either Text Text)

-- calculationId, timestamp -> recalculationId

class Monad m => VerifyReproducibilityUseCase m where
    executeVerifyReproducibility :: Text -> Text -> m (Either Text Bool)

-- originalId, recalculationId -> isConsistent
