module Domain.Accounting.ChartOfAccounts.Errors
    ( ChartError (..)
    )
where

data ChartError
    = EmptyAccountCode
    | EmptyAccountName
    deriving (Show, Eq)
