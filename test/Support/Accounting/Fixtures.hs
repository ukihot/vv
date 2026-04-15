-- | Accounting / IFRS テスト用フィクスチャ
module Support.Accounting.Fixtures (
    -- * 勘定科目
    sampleCashAccount,
    sampleArAccount,
    sampleRevenueAccount,

    -- * 会計期間
    sampleFiscalYearMonth,
    sampleFiscalPeriodId,

    -- * 為替レート
    sampleUsdJpyClosingRate,
    sampleUsdJpyHistoricalRate,

    -- * 仕訳
    sampleJournalEntryId,
    sampleDebitLine,
    sampleCreditLine,

    -- * IFRS 15
    sampleContractId,
    samplePoId,

    -- * IFRS 9
    sampleFinancialAssetId,
    sampleEclParams,

    -- * IFRS 16
    sampleLeaseId,

    -- * ヘルパー
    shouldRight,
)
where

import Data.Time (fromGregorian)
import Domain.Accounting.ChartOfAccounts (
    Account (..),
    AccountClass (..),
    AccountNature (..),
    CurrentNonCurrent (..),
    StatementSection (..),
    mkAccountCode,
    mkAccountName,
 )
import Domain.Accounting.ExchangeRate (
    ExchangeRate (..),
    RateKind (..),
    mkExchangeRate,
 )
import Domain.Accounting.FiscalPeriod (FiscalPeriodId (..), mkFiscalPeriodId)
import Domain.Accounting.JournalEntry (
    DrCr (..),
    JournalEntryId (..),
    JournalLine (..),
    mkJournalEntryId,
 )
import Domain.IFRS.FinancialInstrument (
    EclParameters (..),
    EconomicScenario (..),
    FinancialAssetId (..),
    ScenarioWeight (..),
    mkFinancialAssetId,
 )
import Domain.IFRS.Lease (LeaseId (..), mkLeaseId)
import Domain.IFRS.Revenue (
    ContractId (..),
    PerformanceObligationId (..),
    mkContractId,
 )
import Domain.Shared (FiscalYearMonth (..), mkMoney)
import Test.Tasty.HUnit (assertFailure)

-- ─────────────────────────────────────────────────────────────────────────────
-- ヘルパー
-- ─────────────────────────────────────────────────────────────────────────────

shouldRight :: Show e => String -> Either e a -> IO a
shouldRight _ (Right v) = pure v
shouldRight label (Left e) = assertFailure (label <> ": " <> show e)

-- ─────────────────────────────────────────────────────────────────────────────
-- 勘定科目
-- ─────────────────────────────────────────────────────────────────────────────

sampleCashAccount :: IO Account
sampleCashAccount = do
    code <- shouldRight "cash code" (mkAccountCode "1000")
    name <- shouldRight "cash name" (mkAccountName "現金及び預金")
    pure
        Account
            { accountCode = code
            , accountName = name
            , accountClass = AssetAccount
            , accountNature = DebitNormal
            , accountSection = SoFP_CurrentAsset
            , accountCNC = Current
            }

sampleArAccount :: IO Account
sampleArAccount = do
    code <- shouldRight "ar code" (mkAccountCode "1100")
    name <- shouldRight "ar name" (mkAccountName "売掛金")
    pure
        Account
            { accountCode = code
            , accountName = name
            , accountClass = AssetAccount
            , accountNature = DebitNormal
            , accountSection = SoFP_CurrentAsset
            , accountCNC = Current
            }

sampleRevenueAccount :: IO Account
sampleRevenueAccount = do
    code <- shouldRight "rev code" (mkAccountCode "4000")
    name <- shouldRight "rev name" (mkAccountName "売上高")
    pure
        Account
            { accountCode = code
            , accountName = name
            , accountClass = RevenueAccount
            , accountNature = CreditNormal
            , accountSection = PL_Revenue
            , accountCNC = NotApplicable
            }

-- ─────────────────────────────────────────────────────────────────────────────
-- 会計期間
-- ─────────────────────────────────────────────────────────────────────────────

sampleFiscalYearMonth :: FiscalYearMonth
sampleFiscalYearMonth = FiscalYearMonth 2026 3

sampleFiscalPeriodId :: IO FiscalPeriodId
sampleFiscalPeriodId = shouldRight "period id" (mkFiscalPeriodId "2026-03")

-- ─────────────────────────────────────────────────────────────────────────────
-- 為替レート
-- ─────────────────────────────────────────────────────────────────────────────

sampleUsdJpyClosingRate :: IO (ExchangeRate "USD" "JPY")
sampleUsdJpyClosingRate =
    shouldRight "usd/jpy cr" $
        mkExchangeRate 150 ClosingRate (fromGregorian 2026 3 31) "BOJ"

sampleUsdJpyHistoricalRate :: IO (ExchangeRate "USD" "JPY")
sampleUsdJpyHistoricalRate =
    shouldRight "usd/jpy hr" $
        mkExchangeRate 145 HistoricalRate (fromGregorian 2026 1 15) "BOJ"

-- ─────────────────────────────────────────────────────────────────────────────
-- 仕訳
-- ─────────────────────────────────────────────────────────────────────────────

sampleJournalEntryId :: IO JournalEntryId
sampleJournalEntryId = shouldRight "entry id" (mkJournalEntryId "JE-2026-001")

sampleDebitLine :: IO (JournalLine "JPY")
sampleDebitLine = do
    code <- shouldRight "dr code" (mkAccountCode "1100")
    pure
        JournalLine
            { lineAccount = code
            , lineDrCr = Dr
            , lineAmount = mkMoney 100000
            }

sampleCreditLine :: IO (JournalLine "JPY")
sampleCreditLine = do
    code <- shouldRight "cr code" (mkAccountCode "4000")
    pure
        JournalLine
            { lineAccount = code
            , lineDrCr = Cr
            , lineAmount = mkMoney 100000
            }

-- ─────────────────────────────────────────────────────────────────────────────
-- IFRS 15
-- ─────────────────────────────────────────────────────────────────────────────

sampleContractId :: IO ContractId
sampleContractId = shouldRight "contract id" (mkContractId "CTR-2026-001")

samplePoId :: PerformanceObligationId
samplePoId = PerformanceObligationId "PO-001"

-- ─────────────────────────────────────────────────────────────────────────────
-- IFRS 9
-- ─────────────────────────────────────────────────────────────────────────────

sampleFinancialAssetId :: IO FinancialAssetId
sampleFinancialAssetId = shouldRight "fa id" (mkFinancialAssetId "FA-2026-001")

sampleEclParams :: EclParameters
sampleEclParams =
    EclParameters
        { pd12Month = 0.01 -- 1%
        , pdLifetime = 0.05 -- 5%
        , lgd = 0.45 -- 45%
        , discountFactor = 0.95
        , scenarioWeights =
            [ (BaseScenario, ScenarioWeight 0.6)
            , (OptimisticScenario, ScenarioWeight 0.2)
            , (PessimisticScenario, ScenarioWeight 0.2)
            ]
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- IFRS 16
-- ─────────────────────────────────────────────────────────────────────────────

sampleLeaseId :: IO LeaseId
sampleLeaseId = shouldRight "lease id" (mkLeaseId "LS-2026-001")
