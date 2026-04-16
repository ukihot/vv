module Domain.IFRS.Revenue.ValueObjects.AllocationMethod (
    AllocationMethod (..),
)
where

data AllocationMethod
    = RelativeStandalonePrice
    | AdjustedMarketAssessment
    | ExpectedCostPlusMargin
    | ResidualApproach
    deriving stock (Show, Eq, Ord, Enum, Bounded)
