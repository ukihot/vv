module Domain.Accounting.ChartOfAccounts.Errors (
    ChartError (..),
)
where

data ChartError
    = EmptyAccountCode
    | EmptyAccountName
    deriving stock (Show, Eq)
