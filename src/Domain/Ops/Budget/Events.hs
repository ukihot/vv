module Domain.Ops.Budget.Events (
    BudgetEventPayload (..),
)
where

import Domain.Ops.Budget.ValueObjects.BudgetId (BudgetId)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (Symbol)

data BudgetEventPayload (currency :: Symbol)
    = BudgetCreated BudgetId FiscalYearMonth (Money currency)
    | BudgetActualUpdated BudgetId (Money currency)
    | BudgetExceeded BudgetId (Money currency) (Money currency)
    deriving (Show, Eq)
