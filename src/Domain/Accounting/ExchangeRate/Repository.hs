module Domain.Accounting.ExchangeRate.Repository
    ( ExchangeRateRepository (..)
    )
where

import Data.Time (Day)
import Domain.Accounting.ExchangeRate (ExchangeRate)
import Domain.Accounting.ExchangeRate.ValueObjects.RateKind (RateKind)

class Monad m => ExchangeRateRepository m from to where
    saveExchangeRate :: ExchangeRate from to -> m ()
    findExchangeRateByDate :: RateKind -> Day -> m (Maybe (ExchangeRate from to))
