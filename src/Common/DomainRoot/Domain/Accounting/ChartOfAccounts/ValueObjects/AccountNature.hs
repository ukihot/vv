module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountNature (
    AccountNature (..),
)
where

data AccountNature
    = DebitNormal
    | CreditNormal
    deriving stock (Show, Eq, Ord, Enum, Bounded)
