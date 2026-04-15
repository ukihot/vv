module App.DTO.Request.Closing (
    InitiateClosingPreparationRequest (..),
    LockPeriodRequest (..),
    UnlockPeriodRequest (..),
    GenerateTrialBalanceRequest (..),
    DefineClosingCalendarRequest (..),
    AssignClosingTaskRequest (..),
    UpdateTaskStatusRequest (..),
    ClosingTaskDefinition (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

data InitiateClosingPreparationRequest = InitiateClosingPreparationRequest
    { initClosingYear :: Int
    , initClosingMonth :: Int
    }
    deriving (Show, Eq)

data LockPeriodRequest = LockPeriodRequest
    { lockPeriodYear :: Int
    , lockPeriodMonth :: Int
    , lockPeriodUserId :: Text
    }
    deriving (Show, Eq)

data UnlockPeriodRequest = UnlockPeriodRequest
    { unlockPeriodYear :: Int
    , unlockPeriodMonth :: Int
    , unlockPeriodUserId :: Text
    , unlockPeriodReason :: Text
    }
    deriving (Show, Eq)

data GenerateTrialBalanceRequest = GenerateTrialBalanceRequest
    { genTrialBalanceYear :: Int
    , genTrialBalanceMonth :: Int
    }
    deriving (Show, Eq)

data ClosingTaskDefinition = ClosingTaskDefinition
    { taskName :: Text
    , taskDeadline :: Day
    , taskAssignee :: Text
    }
    deriving (Show, Eq)

data DefineClosingCalendarRequest = DefineClosingCalendarRequest
    { defineCalendarYear :: Int
    , defineCalendarMonth :: Int
    , defineCalendarTasks :: [ClosingTaskDefinition]
    }
    deriving (Show, Eq)

data AssignClosingTaskRequest = AssignClosingTaskRequest
    { assignTaskCalendarId :: Text
    , assignTaskTaskId :: Text
    , assignTaskAssigneeId :: Text
    }
    deriving (Show, Eq)

data UpdateTaskStatusRequest = UpdateTaskStatusRequest
    { updateTaskStatusTaskId :: Text
    , updateTaskStatusStatus :: Text -- "pending", "in_progress", "completed", "blocked"
    , updateTaskStatusUserId :: Text
    }
    deriving (Show, Eq)
