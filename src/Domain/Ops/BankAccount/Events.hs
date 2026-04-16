{-# LANGUAGE StandaloneDeriving #-}

module Domain.Ops.BankAccount.Events (
    BankAccountEventPayload (..),
)
where

import Domain.Ops.BankAccount.ValueObjects.BankAccountId (BankAccountId)
import Domain.Shared (Money)
import GHC.TypeLits (KnownSymbol, Symbol)

data BankAccountEventPayload (currency :: Symbol)
    = BankAccountCreated BankAccountId
    | BankAccountBalanceUpdated BankAccountId (Money currency)

deriving stock instance KnownSymbol currency => Show (BankAccountEventPayload currency)
deriving stock instance Eq (BankAccountEventPayload currency)
