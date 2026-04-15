module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountNature (
    AccountNature (..),
)
where

data AccountNature
    = DebitNormal
    | CreditNormal
    deriving (Show, Eq, Ord, Enum, Bounded)
