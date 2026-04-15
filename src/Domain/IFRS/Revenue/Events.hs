module Domain.IFRS.Revenue.Events
    ( RevenueEventPayload (..)
    )
where

import Data.Time (Day)
import Domain.IFRS.Revenue.Entities.PerformanceObligation (PerformanceObligationId)
import Domain.IFRS.Revenue.ValueObjects.ContractId (ContractId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data RevenueEventPayload (currency :: Symbol)
    = RevenueRecognized ContractId PerformanceObligationId (Money currency) Day
    deriving (Show, Eq)
