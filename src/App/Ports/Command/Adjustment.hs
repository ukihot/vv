module App.Ports.Command.Adjustment (
    ReclassifyAccountUseCase (..),
    AdjustAccrualUseCase (..),
    IdentifyTemporaryDifferenceUseCase (..),
    CalculateDeferredTaxUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Account Adjustment (勘定補正)
-- ============================================================================

class Monad m => ReclassifyAccountUseCase m where
    executeReclassifyAccount :: Text -> Text -> Text -> Double -> Text -> m (Either Text Text)

-- fromAccountId, toAccountId, date, amount, reason -> reclassificationId

class Monad m => AdjustAccrualUseCase m where
    executeAdjustAccrual :: Text -> Double -> Text -> m (Either Text Text)

-- accrualId, newAmount, reason -> adjustmentId

class Monad m => IdentifyTemporaryDifferenceUseCase m where
    executeIdentifyTemporaryDifference :: Text -> Day -> m (Either Text [(Text, Double)])

-- accountId, date -> temporary differences

class Monad m => CalculateDeferredTaxUseCase m where
    executeCalculateDeferredTax :: [(Text, Double)] -> Double -> m (Either Text Text)

-- temporaryDifferences, taxRate -> deferredTaxId
