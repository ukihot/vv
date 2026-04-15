module Domain.IFRS.FairValue.Errors (
    FairValueError (..),
)
where

data FairValueError
    = InvalidFairValueMeasurementId
    | InvalidHierarchyLevel
    | MissingUnobservableInputs
    deriving (Show, Eq)
