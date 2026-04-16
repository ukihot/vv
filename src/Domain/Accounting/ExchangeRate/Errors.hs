module Domain.Accounting.ExchangeRate.Errors (
    ExchangeRateError (..),
)
where

data ExchangeRateError
    = NonPositiveRate
    | MissingRateSource
    deriving stock (Show, Eq)
