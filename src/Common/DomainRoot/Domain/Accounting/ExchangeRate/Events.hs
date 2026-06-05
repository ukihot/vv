module Domain.Accounting.ExchangeRate.Events (
    ExchangeRateEventPayload (..),
)
where

import Data.Time (Day)
import Domain.Accounting.ExchangeRate.ValueObjects.RateKind (RateKind)

data ExchangeRateEventPayload
    = ExchangeRateRecorded RateKind Day Rational
    deriving stock (Show, Eq)
