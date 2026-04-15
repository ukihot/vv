module Domain.Accounting.FiscalPeriod.Events (
    FiscalPeriodEvent (..),
)
where

import Domain.Accounting.FiscalPeriod.ValueObjects.FiscalPeriodId (FiscalPeriodId)
import Domain.Shared (FiscalYearMonth)

data FiscalPeriodEvent
    = PeriodOpened FiscalPeriodId FiscalYearMonth
    | PeriodLocked FiscalPeriodId FiscalYearMonth
    | PeriodReopened FiscalPeriodId FiscalYearMonth
    deriving (Show, Eq)
