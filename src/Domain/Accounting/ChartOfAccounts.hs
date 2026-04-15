-- | 勘定科目体系 (Chart of Accounts)
-- IFRS の財務諸表表示区分と勘定科目を型安全に管理する。
module Domain.Accounting.ChartOfAccounts
  ( -- * 勘定科目
    AccountCode (..),
    AccountName (..),
    AccountClass (..),
    AccountNature (..),
    Account (..),
    mkAccountCode,
    mkAccountName,

    -- * 財務諸表表示区分
    StatementSection (..),
    CurrentNonCurrent (..),

    -- * エラー
    ChartError (..),
  )
where

import Data.Text (Text)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- 値オブジェクト
-- ─────────────────────────────────────────────────────────────────────────────

newtype AccountCode = AccountCode {unAccountCode :: Text}
  deriving (Show, Eq, Ord)

newtype AccountName = AccountName {unAccountName :: Text}
  deriving (Show, Eq, Ord)

mkAccountCode :: Text -> Either ChartError AccountCode
mkAccountCode t
  | T.null t = Left EmptyAccountCode
  | otherwise = Right (AccountCode t)

mkAccountName :: Text -> Either ChartError AccountName
mkAccountName t
  | T.null t = Left EmptyAccountName
  | otherwise = Right (AccountName t)

-- ─────────────────────────────────────────────────────────────────────────────
-- 勘定分類
-- ─────────────────────────────────────────────────────────────────────────────

-- | IFRS 財務諸表上の大分類
data AccountClass
  = -- | 資産
    AssetAccount
  | -- | 負債
    LiabilityAccount
  | -- | 資本
    EquityAccount
  | -- | 収益
    RevenueAccount
  | -- | 費用
    ExpenseAccount
  | -- | その他の包括利益 (OCI)
    OciAccount
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | 借方増加 / 貸方増加の性質
data AccountNature
  = -- | 資産・費用: 借方で増加
    DebitNormal
  | -- | 負債・資本・収益: 貸方で増加
    CreditNormal
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | 財政状態計算書の流動・非流動区分
data CurrentNonCurrent
  = -- | 流動
    Current
  | -- | 非流動
    NonCurrent
  | -- | 損益計算書項目等（区分不要）
    NotApplicable
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | 財務諸表表示セクション
data StatementSection
  = SoFP_CurrentAsset
  | SoFP_NonCurrentAsset
  | SoFP_CurrentLiability
  | SoFP_NonCurrentLiability
  | SoFP_Equity
  | PL_Revenue
  | PL_CostOfSales
  | PL_GrossProfit
  | PL_OperatingExpense
  | PL_OperatingProfit
  | PL_FinanceIncome
  | PL_FinanceCost
  | PL_OtherIncome
  | PL_OtherExpense
  | PL_TaxExpense
  | OCI_Section
  deriving (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- 勘定科目エンティティ
-- ─────────────────────────────────────────────────────────────────────────────

data Account = Account
  { accountCode :: AccountCode,
    accountName :: AccountName,
    accountClass :: AccountClass,
    accountNature :: AccountNature,
    accountSection :: StatementSection,
    accountCNC :: CurrentNonCurrent
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data ChartError
  = EmptyAccountCode
  | EmptyAccountName
  deriving (Show, Eq)
