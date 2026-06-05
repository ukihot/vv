module Domain.IFRS.FinancialInstrument.Errors (
    FinancialInstrumentError (..),
)
where

data FinancialInstrumentError
    = InvalidAssetId
    | InvalidLgd
    | InvalidPd
    | InvalidDiscountFactor
    | InvalidScenarioWeights
    | NegativeEad
    deriving stock (Show, Eq)
