module App.Ports.Command.Consolidation (
    EliminateIntercompanyTransactionUseCase (..),
    EliminateEquityUseCase (..),
    CalculateGoodwillUseCase (..),
    AllocateNonControllingInterestUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Consolidation (連結)
-- ============================================================================

class Monad m => EliminateIntercompanyTransactionUseCase m where
    executeEliminateIntercompanyTransaction :: Text -> Text -> Day -> Double -> m (Either Text Text)

-- parentId, subsidiaryId, date, amount -> eliminationId

class Monad m => EliminateEquityUseCase m where
    executeEliminateEquity :: Text -> Text -> Day -> m (Either Text Text)

-- parentId, subsidiaryId, date -> eliminationId

class Monad m => CalculateGoodwillUseCase m where
    executeCalculateGoodwill :: Text -> Day -> Double -> Double -> m (Either Text Double)

-- subsidiaryId, acquisitionDate, consideration, fairValueOfNetAssets -> goodwill

class Monad m => AllocateNonControllingInterestUseCase m where
    executeAllocateNonControllingInterest :: Text -> Day -> Double -> m (Either Text Double)

-- subsidiaryId, date, ownershipPercentage -> nciAmount
