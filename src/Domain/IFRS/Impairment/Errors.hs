module Domain.IFRS.Impairment.Errors
    ( ImpairmentError (..)
    )
where

data ImpairmentError
    = InvalidImpairmentTestId
    | InvalidCguId
    | NegativeRecoverableAmount
    | InvalidDiscountRate
    deriving (Show, Eq)
