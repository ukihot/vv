module Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass (
    MonetaryClass (..),
)
where

data MonetaryClass
    = Monetary
    | NonMonetary
    deriving (Show, Eq, Ord, Enum, Bounded)
