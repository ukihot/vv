module Domain.Accounting.ChartOfAccounts.Repository (
    ChartOfAccountsRepository (..),
)
where

import Domain.Accounting.ChartOfAccounts (Account)
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)

class Monad m => ChartOfAccountsRepository m where
    saveAccount :: Account -> m ()
    findAccountByCode :: AccountCode -> m (Maybe Account)
    listAllAccounts :: m [Account]
