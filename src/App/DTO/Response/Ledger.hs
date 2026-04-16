module App.DTO.Response.Ledger (
    AccountBalanceResponse (..),
    GeneralLedgerResponse (..),
    SubsidiaryLedgerResponse (..),
    LedgerTransactionResponse (..),
    ReconciliationResponse (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

data AccountBalanceResponse = AccountBalanceResponse
    { accountBalanceRespAccountId :: Text
    , accountBalanceRespAccountCode :: Text
    , accountBalanceRespAccountName :: Text
    , accountBalanceRespDebitBalance :: Double
    , accountBalanceRespCreditBalance :: Double
    , accountBalanceRespNetBalance :: Double
    , accountBalanceRespAsOfDate :: Day
    }
    deriving stock (Show, Eq)

data GeneralLedgerResponse = GeneralLedgerResponse
    { generalLedgerRespDate :: Day
    , generalLedgerRespAccounts :: [AccountBalanceResponse]
    , generalLedgerRespTotalDebit :: Double
    , generalLedgerRespTotalCredit :: Double
    }
    deriving stock (Show, Eq)

data LedgerTransactionResponse = LedgerTransactionResponse
    { ledgerTxnRespDate :: Day
    , ledgerTxnRespDescription :: Text
    , ledgerTxnRespDebit :: Maybe Double
    , ledgerTxnRespCredit :: Maybe Double
    , ledgerTxnRespBalance :: Double
    , ledgerTxnRespJournalEntryId :: Text
    }
    deriving stock (Show, Eq)

data SubsidiaryLedgerResponse = SubsidiaryLedgerResponse
    { subsidiaryLedgerRespAccountId :: Text
    , subsidiaryLedgerRespAccountName :: Text
    , subsidiaryLedgerRespTransactions :: [LedgerTransactionResponse]
    , subsidiaryLedgerRespOpeningBalance :: Double
    , subsidiaryLedgerRespClosingBalance :: Double
    , subsidiaryLedgerRespPeriodFrom :: Day
    , subsidiaryLedgerRespPeriodTo :: Day
    }
    deriving stock (Show, Eq)

data ReconciliationResponse = ReconciliationResponse
    { reconRespAccountId :: Text
    , reconRespDate :: Day
    , reconRespGeneralLedgerBalance :: Double
    , reconRespSubsidiaryLedgerBalance :: Double
    , reconRespDifference :: Double
    , reconRespStatus :: Text -- "matched", "discrepancy"
    , reconRespDiscrepancies :: [(Text, Double)]
    }
    deriving stock (Show, Eq)
