module Domain.IFRS.Revenue.ValueObjects.AllocationMethod
    ( AllocationMethod (..)
    )
where

data AllocationMethod
    = RelativeStandalonePrice
    | AdjustedMarketAssessment
    | ExpectedCostPlusMargin
    | ResidualApproach
    deriving (Show, Eq, Ord, Enum, Bounded)
