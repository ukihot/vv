module Domain.Accounting.JournalEntry.ValueObjects.DrCr (
    DrCr (..),
)
where

data DrCr = Dr | Cr
    deriving stock (Show, Eq, Ord, Enum, Bounded)
