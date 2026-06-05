module Domain.Ops.Budget.Repository (
    BudgetRepository (..),
)
where

import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)
import Domain.Ops.Budget (Budget)
import Domain.Ops.Budget.ValueObjects.BudgetId (BudgetId)
import Domain.Shared (FiscalYearMonth)

class Monad m => BudgetRepository m currency where
    saveBudget :: Budget currency -> m ()
    findBudgetById :: BudgetId -> m (Maybe (Budget currency))
    findBudgetByAccountAndPeriod :: AccountCode -> FiscalYearMonth -> m (Maybe (Budget currency))
