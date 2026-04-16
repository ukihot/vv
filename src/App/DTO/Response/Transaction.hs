module App.DTO.Response.Transaction (
    JournalEntryResponse (..),
    JournalLineResponse (..),
    CashLogResponse (..),
    BankReconciliationResponse (..),
    JournalEntryListResponse (..),
)
where

import Data.Text (Text)
import Data.Time (Day, UTCTime)

data JournalLineResponse = JournalLineResponse
    { journalLineRespAccountId :: Text
    , journalLineRespAccountName :: Text
    , journalLineRespAmount :: Double
    , journalLineRespDrCr :: Text
    }
    deriving stock (Show, Eq)

data JournalEntryResponse = JournalEntryResponse
    { journalEntryRespId :: Text
    , journalEntryRespTransactionDate :: Day
    , journalEntryRespLines :: [JournalLineResponse]
    , journalEntryRespDescription :: Text
    , journalEntryRespEntryType :: Text
    , journalEntryRespStatus :: Text -- "draft", "posted", "locked"
    , journalEntryRespEvidenceIds :: [Text]
    , journalEntryRespCreatedBy :: Text
    , journalEntryRespCreatedAt :: UTCTime
    , journalEntryRespApprovedBy :: Maybe Text
    , journalEntryRespApprovedAt :: Maybe UTCTime
    }
    deriving stock (Show, Eq)

data CashLogResponse = CashLogResponse
    { cashLogRespId :: Text
    , cashLogRespDate :: Day
    , cashLogRespAccountId :: Text
    , cashLogRespAccountName :: Text
    , cashLogRespAmount :: Double
    , cashLogRespDescription :: Text
    , cashLogRespBalance :: Double
    }
    deriving stock (Show, Eq)

data BankReconciliationResponse = BankReconciliationResponse
    { bankReconRespId :: Text
    , bankReconRespBankAccountId :: Text
    , bankReconRespDate :: Day
    , bankReconRespBookBalance :: Double
    , bankReconRespBankBalance :: Double
    , bankReconRespDifference :: Double
    , bankReconRespStatus :: Text -- "pending", "reconciled", "discrepancy"
    }
    deriving stock (Show, Eq)

data JournalEntryListResponse = JournalEntryListResponse
    { journalEntryListItems :: [JournalEntryResponse]
    , journalEntryListTotal :: Int
    , journalEntryListOffset :: Int
    , journalEntryListLimit :: Int
    }
    deriving stock (Show, Eq)
