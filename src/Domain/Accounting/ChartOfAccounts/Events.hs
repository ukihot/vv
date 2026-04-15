module Domain.Accounting.ChartOfAccounts.Events (
    ChartEventPayload (..),
)
where

import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)

data ChartEventPayload
    = AccountCreated AccountCode
    | AccountUpdated AccountCode
    deriving (Show, Eq)
