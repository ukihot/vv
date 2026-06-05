module Domain.IFRS.Revenue.Errors (
    RevenueError (..),
)
where

data RevenueError
    = InvalidContractId
    | InvalidPerformanceObligationId
    | ZeroStandalonePrice
    | NonPositiveStandalonePrice
    | NegativeAllocatedPrice
    | CannotRecognizeOverTimeObligationAtPoint
    | ResidualApproachRequirementsNotMet
    deriving stock (Show, Eq)
