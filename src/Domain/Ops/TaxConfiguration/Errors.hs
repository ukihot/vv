module Domain.Ops.TaxConfiguration.Errors
    ( TaxConfigError (..)
    )
where

data TaxConfigError
    = InvalidTaxConfigId
    | InvalidTaxRate
    | InvalidTaxType
    deriving (Show, Eq)
