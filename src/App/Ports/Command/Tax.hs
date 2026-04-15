module App.Ports.Command.Tax (
    CalculateCorporateTaxUseCase (..),
    ReconcileTaxAccountingDifferenceUseCase (..),
    ProcessInterimTaxPaymentUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Tax Accounting (税務会計)
-- ============================================================================

class Monad m => CalculateCorporateTaxUseCase m where
    executeCalculateCorporateTax :: Int -> Int -> Double -> m (Either Text Double)

-- year, month, taxableIncome -> tax

class Monad m => ReconcileTaxAccountingDifferenceUseCase m where
    executeReconcileTaxAccountingDifference :: Int -> Int -> m (Either Text [(Text, Double)])

-- year, month -> differences

class Monad m => ProcessInterimTaxPaymentUseCase m where
    executeProcessInterimTaxPayment :: Int -> Double -> Day -> m (Either Text Text)

-- year, amount, paymentDate -> paymentId
