module Domain.Ops.BankAccount.Errors
    ( BankAccountError (..)
    )
where

data BankAccountError
    = InvalidBankAccountId
    | InvalidAccountNumber
    | InvalidBankCode
    deriving (Show, Eq)
