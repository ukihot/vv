module Domain.Accounting.JournalEntry.ValueObjects.DrCr (
    DrCr (..),
)
where

data DrCr = Dr | Cr
    deriving (Show, Eq, Ord, Enum, Bounded)
