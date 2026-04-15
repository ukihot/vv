module Domain.IFRS.Revenue.Errors
    ( RevenueError (..)
    )
where

data RevenueError
    = InvalidContractId
    | ZeroStandalonePrice
    | CannotRecognizeOverTimeObligationAtPoint
    | ResidualApproachRequirementsNotMet
    deriving (Show, Eq)
