module Domain.Accounting.JournalEntry.Entities.JournalLine
    ( JournalLine (..)
    )
where

import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)
import Domain.Accounting.JournalEntry.ValueObjects.DrCr (DrCr)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data JournalLine (currency :: Symbol) = JournalLine
    { lineAccount :: AccountCode,
      lineDrCr :: DrCr,
      lineAmount :: Money currency
    }
    deriving (Show, Eq)
