module Domain.Ops.BankStatement.Events
    ( BankStatementEventPayload (..)
    )
where

import Data.Time (Day)
import Domain.Ops.BankStatement.ValueObjects.BankStatementId (BankStatementId)

data BankStatementEventPayload
    = BankStatementImported BankStatementId Day
    | TransactionReconciled BankStatementId Int
    deriving (Show, Eq)
