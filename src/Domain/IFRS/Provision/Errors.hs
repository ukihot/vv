module Domain.IFRS.Provision.Errors (
    ProvisionError (..),
)
where

data ProvisionError
    = InvalidProvisionId
    | InvalidProbability
    | InvalidDiscountRate
    deriving (Show, Eq)
