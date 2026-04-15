module Domain.Ops.BankAccount.Events (
    BankAccountEventPayload (..),
)
where

import Domain.Ops.BankAccount.ValueObjects.BankAccountId (BankAccountId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data BankAccountEventPayload (currency :: Symbol)
    = BankAccountCreated BankAccountId
    | BankAccountBalanceUpdated BankAccountId (Money currency)
    deriving (Show, Eq)
