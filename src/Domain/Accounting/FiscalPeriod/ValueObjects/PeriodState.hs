module Domain.Accounting.FiscalPeriod.ValueObjects.PeriodState (
    PeriodState (..),
)
where

data PeriodState
    = Open
    | Locked
    deriving (Show, Eq, Ord, Enum, Bounded)
