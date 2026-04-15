module Domain.Accounting.JournalEntry.Repository (
    JournalEntryRepository (..),
)
where

import Data.Time (Day)
import Domain.Accounting.JournalEntry (JournalEntry)
import Domain.Accounting.JournalEntry.ValueObjects.JournalEntryId (JournalEntryId)

class Monad m => JournalEntryRepository m currency where
    saveJournalEntry :: JournalEntry currency -> m ()
    findJournalEntryById :: JournalEntryId -> m (Maybe (JournalEntry currency))
    findJournalEntriesByDate :: Day -> m [JournalEntry currency]
