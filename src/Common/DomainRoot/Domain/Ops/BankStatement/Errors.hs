module Domain.Ops.BankStatement.Errors (
    BankStatementError (..),
)
where

data BankStatementError
    = InvalidStatementId
    | InvalidStatementDate
    | DuplicateTransaction
    deriving stock (Show, Eq)
