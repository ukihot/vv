module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountClass (
    AccountClass (..),
)
where

data AccountClass
    = AssetAccount
    | LiabilityAccount
    | EquityAccount
    | RevenueAccount
    | ExpenseAccount
    | OciAccount
    deriving stock (Show, Eq, Ord, Enum, Bounded)
