-- | Accounting / IFRS test fixtures
module Support.Accounting.Fixtures (
    -- * Chart of accounts
    sampleCashAccount,
    sampleArAccount,
    sampleRevenueAccount,

    -- * Fiscal period
    sampleFiscalYearMonth,
    sampleFiscalPeriodId,

    -- * Exchange rates
    sampleUsdJpyClosingRate,
    sampleUsdJpyHistoricalRate,

    -- * Journal entry
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

    -- * Helpers
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
    ExchangeRate,
    RateKind (ClosingRate, HistoricalRate),
    mkClosingRate,
    mkHistoricalRate,
 )
import Domain.Accounting.FiscalPeriod (FiscalPeriodId, mkFiscalPeriodId)
import Domain.Accounting.JournalEntry (
    DrCr (..),
    JournalEntryId,
    JournalLine (..),
    mkJournalEntryId,
 )
import Domain.IFRS.FinancialInstrument (
    EclParameters,
    EconomicScenario (..),
    FinancialAssetId,
    mkEclParameters,
    mkFinancialAssetId,
    mkScenarioWeight,
 )
import Domain.IFRS.Lease (LeaseId, mkLeaseId)
import Domain.IFRS.Revenue (
    ContractId,
    PerformanceObligationId,
    mkContractId,
    mkPerformanceObligationId,
 )
import Domain.Shared (FiscalYearMonth, fiscalYearMonth, mkMoney')
import Test.Tasty.HUnit (assertFailure)

shouldRight :: Show e => String -> Either e a -> IO a
shouldRight _ (Right value) = pure value
shouldRight label (Left err) = assertFailure (label <> ": " <> show err)

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

sampleFiscalYearMonth :: FiscalYearMonth
sampleFiscalYearMonth =
    case fiscalYearMonth 2026 3 of
        Left err -> error ("invalid fiscal year month fixture: " <> show err)
        Right value -> value

sampleFiscalPeriodId :: IO FiscalPeriodId
sampleFiscalPeriodId = shouldRight "period id" (mkFiscalPeriodId "2026-03")

sampleUsdJpyClosingRate :: IO (ExchangeRate 'ClosingRate "USD" "JPY")
sampleUsdJpyClosingRate =
    shouldRight "usd/jpy closing rate" $
        mkClosingRate 150 (fromGregorian 2026 3 31) "BOJ"

sampleUsdJpyHistoricalRate :: IO (ExchangeRate 'HistoricalRate "USD" "JPY")
sampleUsdJpyHistoricalRate =
    shouldRight "usd/jpy historical rate" $
        mkHistoricalRate 145 (fromGregorian 2026 1 15) "BOJ"

sampleJournalEntryId :: IO JournalEntryId
sampleJournalEntryId = shouldRight "entry id" (mkJournalEntryId "JE-2026-001")

sampleDebitLine :: IO (JournalLine "JPY")
sampleDebitLine = do
    code <- shouldRight "debit code" (mkAccountCode "1100")
    pure
        JournalLine
            { lineAccount = code
            , lineDrCr = Dr
            , lineAmount = mkMoney' 100000
            }

sampleCreditLine :: IO (JournalLine "JPY")
sampleCreditLine = do
    code <- shouldRight "credit code" (mkAccountCode "4000")
    pure
        JournalLine
            { lineAccount = code
            , lineDrCr = Cr
            , lineAmount = mkMoney' 100000
            }

sampleContractId :: IO ContractId
sampleContractId = shouldRight "contract id" (mkContractId "CTR-2026-001")

samplePoId :: PerformanceObligationId
samplePoId =
    case mkPerformanceObligationId "PO-001" of
        Left err -> error ("invalid performance obligation id fixture: " <> show err)
        Right value -> value

sampleFinancialAssetId :: IO FinancialAssetId
sampleFinancialAssetId = shouldRight "financial asset id" (mkFinancialAssetId "FA-2026-001")

sampleEclParams :: EclParameters
sampleEclParams =
    case do
        baseWeight <- mkScenarioWeight 0.6
        optimisticWeight <- mkScenarioWeight 0.2
        pessimisticWeight <- mkScenarioWeight 0.2
        mkEclParameters
            0.01
            0.05
            0.45
            0.95
            [ (BaseScenario, baseWeight)
            , (OptimisticScenario, optimisticWeight)
            , (PessimisticScenario, pessimisticWeight)
            ] of
        Left err -> error ("invalid ecl parameter fixture: " <> show err)
        Right value -> value

sampleLeaseId :: IO LeaseId
sampleLeaseId = shouldRight "lease id" (mkLeaseId "LS-2026-001")
