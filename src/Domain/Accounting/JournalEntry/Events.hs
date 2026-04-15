module Domain.Accounting.JournalEntry.Events (
    JournalEntryEventPayload (..),
)
where

import Data.Time (Day)
import Domain.Accounting.JournalEntry.ValueObjects.JournalEntryId (JournalEntryId)
import Domain.Shared (JournalEntryKind)

data JournalEntryEventPayload
    = JournalEntryRecorded JournalEntryId Day JournalEntryKind
    deriving (Show, Eq)
