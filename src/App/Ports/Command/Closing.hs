module App.Ports.Command.Closing (
    InitiateClosingPreparationUseCase (..),
    VerifyTransactionCompletenessUseCase (..),
    LockPeriodUseCase (..),
    UnlockPeriodUseCase (..),
    GenerateTrialBalanceUseCase (..),
    DefineClosingCalendarUseCase (..),
    AssignClosingTaskUseCase (..),
    UpdateTaskStatusUseCase (..),
    VerifyClosingChecklistUseCase (..),
)
where

import App.DTO.Request.Closing

-- ============================================================================
-- Closing Command Use Cases
-- Command: RequestDTO -> m ()
-- ============================================================================

class Monad m => InitiateClosingPreparationUseCase m where
    executeInitiateClosingPreparation :: InitiateClosingPreparationRequest -> m ()

class Monad m => VerifyTransactionCompletenessUseCase m where
    executeVerifyTransactionCompleteness :: () -> m () -- Uses context

class Monad m => LockPeriodUseCase m where
    executeLockPeriod :: LockPeriodRequest -> m ()

class Monad m => UnlockPeriodUseCase m where
    executeUnlockPeriod :: UnlockPeriodRequest -> m ()

class Monad m => GenerateTrialBalanceUseCase m where
    executeGenerateTrialBalance :: GenerateTrialBalanceRequest -> m ()

class Monad m => DefineClosingCalendarUseCase m where
    executeDefineClosingCalendar :: DefineClosingCalendarRequest -> m ()

class Monad m => AssignClosingTaskUseCase m where
    executeAssignClosingTask :: AssignClosingTaskRequest -> m ()

class Monad m => UpdateTaskStatusUseCase m where
    executeUpdateTaskStatus :: UpdateTaskStatusRequest -> m ()

class Monad m => VerifyClosingChecklistUseCase m where
    executeVerifyClosingChecklist :: () -> m () -- Uses context
