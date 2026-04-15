{- | 予算集約ルートエンティティ
予算計画と実績を管理し、予算超過を検知する。
-}
module Domain.Ops.Budget (
    -- * 集約
    Budget (..),

    -- * 値オブジェクト
    module Domain.Ops.Budget.ValueObjects.BudgetId,
)
where

import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)
import Domain.Ops.Budget.ValueObjects.BudgetId
import Domain.Ops.Budget.ValueObjects.Version (Version, initialVersion)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (Symbol)

data Budget (currency :: Symbol) = Budget
    { budgetId :: BudgetId
    , budgetAccountCode :: AccountCode
    , budgetPeriod :: FiscalYearMonth
    , budgetPlannedAmount :: Money currency
    , budgetActualAmount :: Money currency
    , budgetVersion :: Version
    }
    deriving (Show, Eq)
