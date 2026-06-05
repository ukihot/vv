module App.Ports.Command.Transaction (
    RegisterJournalEntryUseCase (..),
    AttachEvidenceUseCase (..),
    CorrectJournalEntryUseCase (..),
    CancelJournalEntryUseCase (..),
    RegisterAccrualUseCase (..),
    RegisterDeferralUseCase (..),
    RegisterCashLogUseCase (..),
    ReconcileBankStatementUseCase (..),
)
where

import App.DTO.Request.Transaction

-- ============================================================================
-- Transaction Command Use Cases
-- Command: RequestDTO -> m ()
-- ============================================================================

class Monad m => RegisterJournalEntryUseCase m where
    executeRegisterJournalEntry :: RegisterJournalEntryRequest -> m ()

class Monad m => AttachEvidenceUseCase m where
    executeAttachEvidence :: AttachEvidenceRequest -> m ()

class Monad m => CorrectJournalEntryUseCase m where
    executeCorrectJournalEntry :: CorrectJournalEntryRequest -> m ()

class Monad m => CancelJournalEntryUseCase m where
    executeCancelJournalEntry :: CancelJournalEntryRequest -> m ()

class Monad m => RegisterAccrualUseCase m where
    executeRegisterAccrual :: RegisterAccrualRequest -> m ()

class Monad m => RegisterDeferralUseCase m where
    executeRegisterDeferral :: RegisterDeferralRequest -> m ()

class Monad m => RegisterCashLogUseCase m where
    executeRegisterCashLog :: RegisterCashLogRequest -> m ()

class Monad m => ReconcileBankStatementUseCase m where
    executeReconcileBankStatement :: ReconcileBankStatementRequest -> m ()
