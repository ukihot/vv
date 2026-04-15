module Domain.Accounting.JournalEntry.Errors (
    JournalError (..),
)
where

data JournalError
    = InvalidEntryId
    | ImbalancedEntry Rational Rational
    | EmptyLines
    | MissingEvidenceForNonAccrual
    deriving (Show, Eq)
