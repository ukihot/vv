module App.Ports.Query.FinancialStatement where

import Data.Text (Text)
import Data.Time (Day)

class Monad m => GetBalanceSheetQuery m where
    executeGetBalanceSheet :: Int -> Int -> m (Maybe BalanceSheetDTO)

class Monad m => GetIncomeStatementQuery m where
    executeGetIncomeStatement :: Int -> Int -> m (Maybe IncomeStatementDTO)

class Monad m => GetCashFlowStatementQuery m where
    executeGetCashFlowStatement :: Int -> Int -> m (Maybe CashFlowStatementDTO)

class Monad m => GetEquityStatementQuery m where
    executeGetEquityStatement :: Int -> Int -> m (Maybe EquityStatementDTO)

class Monad m => GetFinancialStatementPackageQuery m where
    executeGetFinancialStatementPackage :: Int -> Int -> m (Maybe FinancialStatementPackageDTO)

class Monad m => GetAccountClassificationQuery m where
    executeGetAccountClassification :: Text -> Day -> m (Maybe ClassificationDTO)

class Monad m => GetNoteDraftQuery m where
    executeGetNoteDraft :: Text -> m (Maybe NoteDraftDTO)

class Monad m => ListNoteDisclosuresQuery m where
    executeListNoteDisclosures :: Int -> Int -> m [NoteDisclosureDTO]

class Monad m => GetDisclosureChecklistQuery m where
    executeGetDisclosureChecklist :: Text -> m [DisclosureItemDTO]

data BalanceSheetDTO
data IncomeStatementDTO
data CashFlowStatementDTO
data EquityStatementDTO
data FinancialStatementPackageDTO
data ClassificationDTO
data NoteDraftDTO
data NoteDisclosureDTO
data DisclosureItemDTO
