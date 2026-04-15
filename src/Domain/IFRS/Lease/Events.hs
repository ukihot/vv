module Domain.IFRS.Lease.Events
    ( LeaseEventPayload (..)
    )
where

import Data.Time (Day)
import Domain.IFRS.Lease.ValueObjects.LeaseId (LeaseId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data LeaseEventPayload (currency :: Symbol)
    = LeaseRecorded LeaseId Day Int Rational (Money currency)
    | LeasePaymentApplied LeaseId (Money currency)
    deriving (Show, Eq)
