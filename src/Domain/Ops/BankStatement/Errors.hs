module Domain.Ops.BankStatement.Errors
    ( BankStatementError (..)
    )
where

data BankStatementError
    = InvalidStatementId
    | InvalidStatementDate
    | DuplicateTransaction
    deriving (Show, Eq)
