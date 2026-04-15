module Domain.Audit.ClosingProcess.Errors
    ( ClosingProcessError (..)
    )
where

data ClosingProcessError
    = InvalidClosingProcessId
    | InvalidStateTransition
    | PeriodNotLocked
    deriving (Show, Eq)
