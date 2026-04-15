module Domain.Ops.BankStatement.Repository
    ( BankStatementRepository (..)
    )
where

import Data.Time (Day)
import Domain.Ops.BankAccount.ValueObjects.BankAccountId (BankAccountId)
import Domain.Ops.BankStatement (BankStatement)
import Domain.Ops.BankStatement.ValueObjects.BankStatementId (BankStatementId)

class Monad m => BankStatementRepository m currency where
    saveBankStatement :: BankStatement currency -> m ()
    findBankStatementById :: BankStatementId -> m (Maybe (BankStatement currency))
    findBankStatementsByAccount :: BankAccountId -> Day -> Day -> m [BankStatement currency]
