module App.Ports.Query.Ledger where

import Data.Text (Text)
import Data.Time (Day)

class Monad m => GetGeneralLedgerBalanceQuery m where
    executeGetGeneralLedgerBalance :: Day -> m [AccountBalanceDTO]

class Monad m => GetSubsidiaryLedgerQuery m where
    executeGetSubsidiaryLedger :: Text -> Day -> m (Maybe SubsidiaryLedgerDTO)

class Monad m => GetAccountBalanceQuery m where
    executeGetAccountBalance :: Text -> Day -> m (Maybe Double)

class Monad m => GetAccountHistoryQuery m where
    executeGetAccountHistory :: Text -> Day -> Day -> m [TransactionDTO]

class Monad m => GetLedgerReconciliationQuery m where
    executeGetLedgerReconciliation :: Text -> Day -> m (Maybe ReconciliationDTO)

data AccountBalanceDTO
data SubsidiaryLedgerDTO
data TransactionDTO
data ReconciliationDTO
