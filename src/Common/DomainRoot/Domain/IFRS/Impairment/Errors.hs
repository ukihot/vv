module Domain.IFRS.Impairment.Errors (
    ImpairmentError (..),
)
where

data ImpairmentError
    = InvalidImpairmentTestId
    | InvalidCguId
    | NegativeRecoverableAmount
    | InvalidDiscountRate
    deriving stock (Show, Eq)
