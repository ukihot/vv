module Domain.Accounting.FiscalPeriod.ValueObjects.PeriodState (
    PeriodState (..),
)
where

data PeriodState
    = Open
    | Locked
    deriving stock (Show, Eq, Ord, Enum, Bounded)
