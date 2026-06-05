module App.Ports.Command.Audit (
    RecordAuditTrailUseCase (..),
    InitiateClosingProcessUseCase (..),
    FinalizeClosingProcessUseCase (..),
    IdentifyPriorPeriodErrorUseCase (..),
    CorrectPriorPeriodErrorUseCase (..),
    RestateComparativeInformationUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (UTCTime)

-- ============================================================================
-- Audit Trail (監査証跡)
-- ============================================================================

class Monad m => RecordAuditTrailUseCase m where
    executeRecordAuditTrail :: Text -> Text -> Text -> Text -> UTCTime -> m (Either Text Text)

-- userId, action, entityType, entityId, timestamp -> auditId

class Monad m => InitiateClosingProcessUseCase m where
    executeInitiateClosingProcess :: Int -> Int -> Text -> m (Either Text Text)

-- year, month, initiatorId -> closingProcessId

class Monad m => FinalizeClosingProcessUseCase m where
    executeFinalizeClosingProcess :: Text -> Text -> m (Either Text ())

-- closingProcessId, finalizerId

-- ============================================================================
-- Prior Period Error Correction (前期誤謬修正 - IAS 8)
-- ============================================================================

class Monad m => IdentifyPriorPeriodErrorUseCase m where
    executeIdentifyPriorPeriodError :: Text -> Int -> Int -> Text -> m (Either Text Text)

-- description, year, month, identifierId -> errorId

class Monad m => CorrectPriorPeriodErrorUseCase m where
    executeCorrectPriorPeriodError :: Text -> [(Text, Double, Text)] -> Text -> m (Either Text Text)

-- errorId, corrections, reason -> correctionId

class Monad m => RestateComparativeInformationUseCase m where
    executeRestateComparativeInformation :: Text -> Int -> m (Either Text Text)

-- errorId, priorYear -> restatementId
