module App.DTO.Response.Closing (
    ClosingStatusResponse (..),
    TrialBalanceResponse (..),
    TrialBalanceLineResponse (..),
    ClosingChecklistResponse (..),
    ChecklistItemResponse (..),
    ClosingCalendarResponse (..),
    ClosingTaskResponse (..),
    PeriodLockResponse (..),
)
where

import Data.Text (Text)
import Data.Time (Day, UTCTime)

data ClosingStatusResponse = ClosingStatusResponse
    { closingStatusRespId :: Text
    , closingStatusRespYear :: Int
    , closingStatusRespMonth :: Int
    , closingStatusRespStatus :: Text -- "preparation", "in_progress", "review", "finalized"
    , closingStatusRespPhase :: Text
    , closingStatusRespInitiatedBy :: Text
    , closingStatusRespInitiatedAt :: UTCTime
    , closingStatusRespFinalizedBy :: Maybe Text
    , closingStatusRespFinalizedAt :: Maybe UTCTime
    }
    deriving (Show, Eq)

data TrialBalanceLineResponse = TrialBalanceLineResponse
    { trialBalanceLineAccountCode :: Text
    , trialBalanceLineAccountName :: Text
    , trialBalanceLineDebit :: Double
    , trialBalanceLineCredit :: Double
    }
    deriving (Show, Eq)

data TrialBalanceResponse = TrialBalanceResponse
    { trialBalanceRespId :: Text
    , trialBalanceRespYear :: Int
    , trialBalanceRespMonth :: Int
    , trialBalanceRespLines :: [TrialBalanceLineResponse]
    , trialBalanceRespTotalDebit :: Double
    , trialBalanceRespTotalCredit :: Double
    , trialBalanceRespIsBalanced :: Bool
    , trialBalanceRespGeneratedAt :: UTCTime
    }
    deriving (Show, Eq)

data ChecklistItemResponse = ChecklistItemResponse
    { checklistItemRespName :: Text
    , checklistItemRespDescription :: Text
    , checklistItemRespStatus :: Text -- "pending", "completed", "skipped"
    , checklistItemRespCompletedBy :: Maybe Text
    , checklistItemRespCompletedAt :: Maybe UTCTime
    }
    deriving (Show, Eq)

data ClosingChecklistResponse = ClosingChecklistResponse
    { closingChecklistRespClosingId :: Text
    , closingChecklistRespItems :: [ChecklistItemResponse]
    , closingChecklistRespCompletionRate :: Double -- 0.0 to 1.0
    }
    deriving (Show, Eq)

data ClosingTaskResponse = ClosingTaskResponse
    { closingTaskRespId :: Text
    , closingTaskRespName :: Text
    , closingTaskRespDeadline :: Day
    , closingTaskRespAssignee :: Text
    , closingTaskRespStatus :: Text -- "pending", "in_progress", "completed", "blocked"
    , closingTaskRespCompletedAt :: Maybe UTCTime
    }
    deriving (Show, Eq)

data ClosingCalendarResponse = ClosingCalendarResponse
    { closingCalendarRespId :: Text
    , closingCalendarRespYear :: Int
    , closingCalendarRespMonth :: Int
    , closingCalendarRespTasks :: [ClosingTaskResponse]
    , closingCalendarRespCreatedAt :: UTCTime
    }
    deriving (Show, Eq)

data PeriodLockResponse = PeriodLockResponse
    { periodLockRespYear :: Int
    , periodLockRespMonth :: Int
    , periodLockRespIsLocked :: Bool
    , periodLockRespLockedBy :: Maybe Text
    , periodLockRespLockedAt :: Maybe UTCTime
    , periodLockRespUnlockedBy :: Maybe Text
    , periodLockRespUnlockedAt :: Maybe UTCTime
    , periodLockRespUnlockReason :: Maybe Text
    }
    deriving (Show, Eq)
