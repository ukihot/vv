module Domain.Ops.TaxConfiguration.Events (
    TaxConfigEventPayload (..),
)
where

import Data.Time (Day)
import Domain.Ops.TaxConfiguration.ValueObjects.TaxConfigId (TaxConfigId)
import Domain.Ops.TaxConfiguration.ValueObjects.TaxType (TaxType)

data TaxConfigEventPayload
    = TaxConfigCreated TaxConfigId TaxType Rational Day
    | TaxConfigRateUpdated TaxConfigId Rational
    deriving (Show, Eq)
