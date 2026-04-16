module Domain.Audit.ClosingProcess.Repository (
    ClosingProcessRepository (..),
)
where

import Domain.Audit.ClosingProcess (SomeClosingProcess)
import Domain.Audit.ClosingProcess.ValueObjects.ClosingProcessId (ClosingProcessId)
import Domain.Shared (FiscalYearMonth)

class Monad m => ClosingProcessRepository m where
    saveClosingProcess :: SomeClosingProcess -> m ()
    findClosingProcessById :: ClosingProcessId -> m (Maybe SomeClosingProcess)
    findClosingProcessByPeriod :: FiscalYearMonth -> m (Maybe SomeClosingProcess)
