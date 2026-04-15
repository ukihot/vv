module Domain.Accounting.FiscalPeriod.Errors (
    PeriodError (..),
)
where

data PeriodError
    = InvalidPeriodId
    | PeriodAlreadyLocked
    | PeriodNotLocked
    deriving (Show, Eq)
