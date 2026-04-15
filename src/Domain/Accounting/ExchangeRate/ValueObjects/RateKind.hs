module Domain.Accounting.ExchangeRate.ValueObjects.RateKind
    ( RateKind (..)
    )
where

data RateKind
    = SpotRate
    | ClosingRate
    | HistoricalRate
    | AverageRate
    deriving (Show, Eq, Ord, Enum, Bounded)
