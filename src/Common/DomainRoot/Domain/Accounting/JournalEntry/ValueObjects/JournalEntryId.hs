module Domain.Accounting.JournalEntry.ValueObjects.JournalEntryId (
    JournalEntryId,
    mkJournalEntryId,
    unJournalEntryId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Accounting.JournalEntry.Errors (JournalError (..))

newtype JournalEntryId = JournalEntryId {unJournalEntryId :: Text}
    deriving stock (Show, Eq, Ord)

mkJournalEntryId :: Text -> Either JournalError JournalEntryId
mkJournalEntryId t
    | T.null normalized = Left InvalidEntryId
    | otherwise = Right (JournalEntryId normalized)
    where
        normalized = T.strip t
