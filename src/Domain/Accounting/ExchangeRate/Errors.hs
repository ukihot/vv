module Domain.Accounting.ExchangeRate.Errors
    ( ExchangeRateError (..)
    )
where

data ExchangeRateError
    = NonPositiveRate
    | MissingRateSource
    deriving (Show, Eq)
