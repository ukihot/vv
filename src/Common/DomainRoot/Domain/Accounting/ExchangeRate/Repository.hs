module Domain.Accounting.ExchangeRate.Repository (
    ExchangeRateRepository (..),
)
where

import Data.Time (Day)
import Domain.Accounting.ExchangeRate (ExchangeRate)

class Monad m => ExchangeRateRepository m kind from to where
    saveExchangeRate :: ExchangeRate kind from to -> m ()
    findExchangeRateByDate :: Day -> m (Maybe (ExchangeRate kind from to))
