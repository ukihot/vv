module Domain.Audit.ClosingProcess.Events
    ( ClosingProcessEventPayload (..)
    )
where

import Domain.Audit.ClosingProcess.ValueObjects.ClosingProcessId (ClosingProcessId)
import Domain.Audit.ClosingProcess.ValueObjects.ClosingState (ClosingState)
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.Shared (FiscalYearMonth)

data ClosingProcessEventPayload
    = ClosingProcessStarted ClosingProcessId FiscalYearMonth UserId
    | ClosingProcessStateChanged ClosingProcessId ClosingState UserId
    | ClosingProcessFinalized ClosingProcessId UserId
    deriving (Show, Eq)
