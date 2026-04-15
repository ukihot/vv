module App.Ports.Command.Revenue (
    IdentifyContractUseCase (..),
    IdentifyPerformanceObligationUseCase (..),
    DetermineTransactionPriceUseCase (..),
    AllocateTransactionPriceUseCase (..),
    RecognizeRevenueUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Revenue Recognition (収益認識 - IFRS 15)
-- ============================================================================

class Monad m => IdentifyContractUseCase m where
    executeIdentifyContract :: Text -> Day -> [(Text, Text)] -> m (Either Text Text)

-- contractNumber, date, terms -> contractId

class Monad m => IdentifyPerformanceObligationUseCase m where
    executeIdentifyPerformanceObligation :: Text -> [Text] -> m (Either Text [Text])

-- contractId, promises -> performanceObligationIds

class Monad m => DetermineTransactionPriceUseCase m where
    executeDetermineTransactionPrice :: Text -> Double -> [(Text, Double)] -> m (Either Text Double)

-- contractId, basePrice, variableConsiderations -> transactionPrice

class Monad m => AllocateTransactionPriceUseCase m where
    executeAllocateTransactionPrice ::
        Text -> Double -> [(Text, Double)] -> m (Either Text [(Text, Double)])

-- contractId, transactionPrice, standalonePrices -> allocations

class Monad m => RecognizeRevenueUseCase m where
    executeRecognizeRevenue :: Text -> Day -> Double -> Text -> m (Either Text Text)

-- performanceObligationId, date, amount, recognitionMethod -> revenueId
