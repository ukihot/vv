module App.Ports.Output.FinancialStatement (
    BalanceSheetOutputPort (..),
    IncomeStatementOutputPort (..),
    CashFlowStatementOutputPort (..),
    EquityStatementOutputPort (..),
    FinancialStatementPackageOutputPort (..),
)
where

import App.DTO.Response.FinancialStatement
import Data.Text (Text)

-- ============================================================================
-- Financial Statement Output Ports (画面ごとのプレゼンター)
-- ============================================================================

-- | 貸借対照表画面用OutputPort
class Monad m => BalanceSheetOutputPort m where
    presentBalanceSheet :: BalanceSheetResponse -> m ()
    presentBalanceSheetFailure :: Text -> m ()

-- | 損益計算書画面用OutputPort
class Monad m => IncomeStatementOutputPort m where
    presentIncomeStatement :: IncomeStatementResponse -> m ()
    presentIncomeStatementFailure :: Text -> m ()

-- | キャッシュフロー計算書画面用OutputPort
class Monad m => CashFlowStatementOutputPort m where
    presentCashFlowStatement :: CashFlowStatementResponse -> m ()
    presentCashFlowStatementFailure :: Text -> m ()

-- | 持分変動計算書画面用OutputPort
class Monad m => EquityStatementOutputPort m where
    presentEquityStatement :: EquityStatementResponse -> m ()
    presentEquityStatementFailure :: Text -> m ()

-- | 財務諸表パッケージ画面用OutputPort
class Monad m => FinancialStatementPackageOutputPort m where
    presentFinancialStatementPackage :: FinancialStatementPackageResponse -> m ()
    presentFinancialStatementPackageFailure :: Text -> m ()
