module Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass (
    MonetaryClass (..),
)
where

data MonetaryClass
    = Monetary
    | NonMonetary
    deriving stock (Show, Eq, Ord, Enum, Bounded)
