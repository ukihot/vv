module App.Ports.Query.Closing where

import Data.Text (Text)

class Monad m => GetClosingStatusQuery m where
    executeGetClosingStatus :: Int -> Int -> m (Maybe ClosingStatusDTO)

class Monad m => ListPeriodLocksQuery m where
    executeListPeriodLocks :: m [PeriodLockDTO]

class Monad m => GetTrialBalanceQuery m where
    executeGetTrialBalance :: Int -> Int -> m (Maybe TrialBalanceDTO)

class Monad m => GetClosingChecklistQuery m where
    executeGetClosingChecklist :: Text -> m [ChecklistItemDTO]

class Monad m => GetClosingCalendarQuery m where
    executeGetClosingCalendar :: Int -> Int -> m (Maybe ClosingCalendarDTO)

class Monad m => ListClosingTasksQuery m where
    executeListClosingTasks :: Text -> m [ClosingTaskDTO]

class Monad m => GetTaskStatusQuery m where
    executeGetTaskStatus :: Text -> m (Maybe TaskStatusDTO)

data ClosingStatusDTO
data PeriodLockDTO
data TrialBalanceDTO
data ChecklistItemDTO
data ClosingCalendarDTO
data ClosingTaskDTO
data TaskStatusDTO
