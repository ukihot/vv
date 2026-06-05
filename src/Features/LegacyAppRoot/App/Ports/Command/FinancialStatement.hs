module App.Ports.Command.FinancialStatement (
    GenerateFinancialStatementsUseCase (..),
    GenerateBalanceSheetUseCase (..),
    GenerateIncomeStatementUseCase (..),
    GenerateCashFlowStatementUseCase (..),
    GenerateEquityStatementUseCase (..),
    ClassifyAccountsUseCase (..),
    GenerateNoteDraftUseCase (..),
    VerifyDisclosureCompletenessUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Financial Statement Generation (財務諸表生成)
-- ============================================================================

class Monad m => GenerateFinancialStatementsUseCase m where
    executeGenerateFinancialStatements :: Int -> Int -> m (Either Text Text)

-- year, month -> fsId

class Monad m => GenerateBalanceSheetUseCase m where
    executeGenerateBalanceSheet :: Int -> Int -> m (Either Text Text)

-- year, month -> bsId

class Monad m => GenerateIncomeStatementUseCase m where
    executeGenerateIncomeStatement :: Int -> Int -> m (Either Text Text)

-- year, month -> isId

class Monad m => GenerateCashFlowStatementUseCase m where
    executeGenerateCashFlowStatement :: Int -> Int -> Text -> m (Either Text Text)

-- year, month, method (direct/indirect) -> cfsId

class Monad m => GenerateEquityStatementUseCase m where
    executeGenerateEquityStatement :: Int -> Int -> m (Either Text Text)

-- year, month -> equityId

class Monad m => ClassifyAccountsUseCase m where
    executeClassifyAccounts :: Text -> Day -> m (Either Text [(Text, Text)])

-- accountId, date -> classifications

-- ============================================================================
-- Note Disclosure (注記生成)
-- ============================================================================

class Monad m => GenerateNoteDraftUseCase m where
    executeGenerateNoteDraft :: Int -> Int -> [Text] -> m (Either Text Text)

-- year, month, noteTypes -> noteDraftId

class Monad m => VerifyDisclosureCompletenessUseCase m where
    executeVerifyDisclosureCompleteness :: Text -> m (Either Text [(Text, Bool)])

-- fsId -> disclosure checklist
