module Domain.Accounting.ChartOfAccounts.ValueObjects.StatementSection (
    StatementSection (..),
    CurrentNonCurrent (..),
)
where

data CurrentNonCurrent
    = Current
    | NonCurrent
    | NotApplicable
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data StatementSection
    = SoFP_CurrentAsset
    | SoFP_NonCurrentAsset
    | SoFP_CurrentLiability
    | SoFP_NonCurrentLiability
    | SoFP_Equity
    | PL_Revenue
    | PL_CostOfSales
    | PL_GrossProfit
    | PL_OperatingExpense
    | PL_OperatingProfit
    | PL_FinanceIncome
    | PL_FinanceCost
    | PL_OtherIncome
    | PL_OtherExpense
    | PL_TaxExpense
    | OCI_Section
    deriving stock (Show, Eq, Ord, Enum, Bounded)
