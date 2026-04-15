module Domain.Accounting.JournalEntry.Services.Validation (
    validateBalance,
)
where

import Data.List (foldl')
import Domain.Accounting.JournalEntry.Entities.JournalLine (JournalLine (..))
import Domain.Accounting.JournalEntry.Errors (JournalError (..))
import Domain.Accounting.JournalEntry.ValueObjects.DrCr (DrCr (..))
import Domain.Shared (Money, addMoney, unMoney, zeroMoney)

validateBalance :: [JournalLine currency] -> Either JournalError ()
validateBalance lines
    | drTotal == crTotal = Right ()
    | otherwise = Left (ImbalancedEntry drTotal crTotal)
    where
        drTotal =
            unMoney $
                foldl' (\acc l -> if lineDrCr l == Dr then addMoney acc (lineAmount l) else acc) zeroMoney lines
        crTotal =
            unMoney $
                foldl' (\acc l -> if lineDrCr l == Cr then addMoney acc (lineAmount l) else acc) zeroMoney lines
