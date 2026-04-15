module Domain.Ops.BankAccount.Repository
    ( BankAccountRepository (..)
    )
where

import Domain.Ops.BankAccount (BankAccount)
import Domain.Ops.BankAccount.ValueObjects.BankAccountId (BankAccountId)

class Monad m => BankAccountRepository m currency where
    saveBankAccount :: BankAccount currency -> m ()
    findBankAccountById :: BankAccountId -> m (Maybe (BankAccount currency))
