module App.Ports.Query.Transaction where

import Data.Text (Text)
import Data.Time (Day)

class Monad m => FindJournalEntryQuery m where
    executeFindJournalEntry :: Text -> m (Maybe JournalEntryDTO)

class Monad m => ListJournalEntriesQuery m where
    executeListJournalEntries :: Day -> Day -> Int -> Int -> m [JournalEntryDTO]

class Monad m => SearchJournalEntriesQuery m where
    executeSearchJournalEntries :: Text -> Day -> Day -> m [JournalEntryDTO]

class Monad m => FindCashLogQuery m where
    executeFindCashLog :: Text -> m (Maybe CashLogDTO)

class Monad m => ListCashLogsQuery m where
    executeListCashLogs :: Text -> Day -> Day -> m [CashLogDTO]

class Monad m => GetBankReconciliationQuery m where
    executeGetBankReconciliation :: Text -> Day -> m (Maybe BankReconciliationDTO)

data JournalEntryDTO
data CashLogDTO
data BankReconciliationDTO
