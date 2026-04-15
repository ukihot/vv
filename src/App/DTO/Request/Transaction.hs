module App.DTO.Request.Transaction (
    RegisterJournalEntryRequest (..),
    AttachEvidenceRequest (..),
    CorrectJournalEntryRequest (..),
    CancelJournalEntryRequest (..),
    RegisterAccrualRequest (..),
    RegisterDeferralRequest (..),
    RegisterCashLogRequest (..),
    ReconcileBankStatementRequest (..),
    JournalLineRequest (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

data JournalLineRequest = JournalLineRequest
    { journalLineAccountId :: Text
    , journalLineAmount :: Double
    , journalLineDrCr :: Text -- "Dr" or "Cr"
    }
    deriving (Show, Eq)

data RegisterJournalEntryRequest = RegisterJournalEntryRequest
    { regJournalTransactionDate :: Day
    , regJournalLines :: [JournalLineRequest]
    , regJournalDescription :: Text
    , regJournalEntryType :: Text -- 新規起票、取消、反対、追加、再分類、洗替、見積変更
    }
    deriving (Show, Eq)

data AttachEvidenceRequest = AttachEvidenceRequest
    { attachEvidenceEntryId :: Text
    , attachEvidenceEvidenceId :: Text
    }
    deriving (Show, Eq)

data CorrectJournalEntryRequest = CorrectJournalEntryRequest
    { correctJournalOriginalEntryId :: Text
    , correctJournalCorrections :: [JournalLineRequest]
    , correctJournalReason :: Text
    }
    deriving (Show, Eq)

data CancelJournalEntryRequest = CancelJournalEntryRequest
    { cancelJournalEntryId :: Text
    , cancelJournalReason :: Text
    }
    deriving (Show, Eq)

data RegisterAccrualRequest = RegisterAccrualRequest
    { regAccrualDate :: Day
    , regAccrualAccountId :: Text
    , regAccrualAmount :: Double
    , regAccrualDescription :: Text
    }
    deriving (Show, Eq)

data RegisterDeferralRequest = RegisterDeferralRequest
    { regDeferralDate :: Day
    , regDeferralAccountId :: Text
    , regDeferralAmount :: Double
    , regDeferralPeriods :: Int
    }
    deriving (Show, Eq)

data RegisterCashLogRequest = RegisterCashLogRequest
    { regCashLogDate :: Day
    , regCashLogAccountId :: Text
    , regCashLogAmount :: Double
    , regCashLogDescription :: Text
    }
    deriving (Show, Eq)

data ReconcileBankStatementRequest = ReconcileBankStatementRequest
    { reconBankAccountId :: Text
    , reconDate :: Day
    , reconTransactions :: [(Text, Double)] -- (description, amount)
    }
    deriving (Show, Eq)
