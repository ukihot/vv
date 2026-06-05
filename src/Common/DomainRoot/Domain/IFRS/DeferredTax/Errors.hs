module Domain.IFRS.DeferredTax.Errors (
    DeferredTaxError (..),
)
where

data DeferredTaxError
    = InvalidDeferredTaxItemId
    | InvalidTaxRate
    | InvalidTemporaryDifference
    deriving stock (Show, Eq)
