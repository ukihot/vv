module Domain.Accounting.FiscalPeriod.Repository (
    FiscalPeriodRepository (..),
)
where

import Domain.Accounting.FiscalPeriod (FiscalPeriod, SomeFiscalPeriod)
import Domain.Accounting.FiscalPeriod.ValueObjects.FiscalPeriodId (FiscalPeriodId)
import Domain.Shared (FiscalYearMonth)

class Monad m => FiscalPeriodRepository m where
    saveFiscalPeriod :: SomeFiscalPeriod -> m ()
    findFiscalPeriodById :: FiscalPeriodId -> m (Maybe SomeFiscalPeriod)
    findFiscalPeriodByYearMonth :: FiscalYearMonth -> m (Maybe SomeFiscalPeriod)
