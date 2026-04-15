module Domain.IFRS.Lease.Errors
    ( LeaseError (..)
    )
where

data LeaseError
    = InvalidLeaseId
    | NegativeLeaseTerm
    | NonPositiveDiscountRate
    deriving (Show, Eq)
