module Domain.IFRS.FinancialInstrument.Errors (
    FinancialInstrumentError (..),
)
where

data FinancialInstrumentError
    = InvalidAssetId
    | InvalidLgd
    | InvalidPd
    | NegativeEad
    deriving stock (Show, Eq)
