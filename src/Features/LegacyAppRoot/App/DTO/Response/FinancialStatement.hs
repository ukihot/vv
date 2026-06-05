module App.DTO.Response.FinancialStatement (
    BalanceSheetResponse (..),
    IncomeStatementResponse (..),
    CashFlowStatementResponse (..),
    EquityStatementResponse (..),
    FinancialStatementPackageResponse (..),
    BSLineItemResponse (..),
    ISLineItemResponse (..),
    CFLineItemResponse (..),
)
where

import Data.Text (Text)
import Data.Time (Day, UTCTime)

-- Balance Sheet
data BSLineItemResponse = BSLineItemResponse
    { bsLineItemCategory :: Text -- "Assets", "Liabilities", "Equity"
    , bsLineItemSubcategory :: Text -- "Current Assets", "Non-current Assets", etc.
    , bsLineItemAccountName :: Text
    , bsLineItemAmount :: Double
    }
    deriving stock (Show, Eq)

data BalanceSheetResponse = BalanceSheetResponse
    { balanceSheetRespId :: Text
    , balanceSheetRespYear :: Int
    , balanceSheetRespMonth :: Int
    , balanceSheetRespAsOfDate :: Day
    , balanceSheetRespLineItems :: [BSLineItemResponse]
    , balanceSheetRespTotalAssets :: Double
    , balanceSheetRespTotalLiabilities :: Double
    , balanceSheetRespTotalEquity :: Double
    , balanceSheetRespGeneratedAt :: UTCTime
    }
    deriving stock (Show, Eq)

-- Income Statement
data ISLineItemResponse = ISLineItemResponse
    { isLineItemCategory :: Text -- "Revenue", "Cost of Sales", "Operating Expenses", etc.
    , isLineItemAccountName :: Text
    , isLineItemAmount :: Double
    }
    deriving stock (Show, Eq)

data IncomeStatementResponse = IncomeStatementResponse
    { incomeStatementRespId :: Text
    , incomeStatementRespYear :: Int
    , incomeStatementRespMonth :: Int
    , incomeStatementRespPeriodFrom :: Day
    , incomeStatementRespPeriodTo :: Day
    , incomeStatementRespLineItems :: [ISLineItemResponse]
    , incomeStatementRespRevenue :: Double
    , incomeStatementRespGrossProfit :: Double
    , incomeStatementRespOperatingProfit :: Double
    , incomeStatementRespNetProfit :: Double
    , incomeStatementRespGeneratedAt :: UTCTime
    }
    deriving stock (Show, Eq)

-- Cash Flow Statement
data CFLineItemResponse = CFLineItemResponse
    { cfLineItemCategory :: Text -- "Operating", "Investing", "Financing"
    , cfLineItemDescription :: Text
    , cfLineItemAmount :: Double
    }
    deriving stock (Show, Eq)

data CashFlowStatementResponse = CashFlowStatementResponse
    { cashFlowRespId :: Text
    , cashFlowRespYear :: Int
    , cashFlowRespMonth :: Int
    , cashFlowRespPeriodFrom :: Day
    , cashFlowRespPeriodTo :: Day
    , cashFlowRespMethod :: Text -- "direct" or "indirect"
    , cashFlowRespLineItems :: [CFLineItemResponse]
    , cashFlowRespOperatingCF :: Double
    , cashFlowRespInvestingCF :: Double
    , cashFlowRespFinancingCF :: Double
    , cashFlowRespNetCashFlow :: Double
    , cashFlowRespOpeningCash :: Double
    , cashFlowRespClosingCash :: Double
    , cashFlowRespGeneratedAt :: UTCTime
    }
    deriving stock (Show, Eq)

-- Equity Statement
data EquityStatementResponse = EquityStatementResponse
    { equityStatementRespId :: Text
    , equityStatementRespYear :: Int
    , equityStatementRespMonth :: Int
    , equityStatementRespOpeningBalance :: Double
    , equityStatementRespNetProfit :: Double
    , equityStatementRespDividends :: Double
    , equityStatementRespOtherChanges :: Double
    , equityStatementRespClosingBalance :: Double
    , equityStatementRespGeneratedAt :: UTCTime
    }
    deriving stock (Show, Eq)

-- Complete Package
data FinancialStatementPackageResponse = FinancialStatementPackageResponse
    { fsPackageRespId :: Text
    , fsPackageRespYear :: Int
    , fsPackageRespMonth :: Int
    , fsPackageRespBalanceSheet :: BalanceSheetResponse
    , fsPackageRespIncomeStatement :: IncomeStatementResponse
    , fsPackageRespCashFlowStatement :: CashFlowStatementResponse
    , fsPackageRespEquityStatement :: EquityStatementResponse
    , fsPackageRespStatus :: Text -- "draft", "review", "approved", "published"
    , fsPackageRespGeneratedAt :: UTCTime
    }
    deriving stock (Show, Eq)
