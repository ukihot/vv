module Domain.IFRS.FinancialInstrument.Events
    ( FinancialInstrumentEventPayload (..)
    )
where

import Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (EclStage)
import Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (FinancialAssetId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data FinancialInstrumentEventPayload (currency :: Symbol)
    = FinancialAssetRecorded FinancialAssetId (Money currency) Rational
    | EclStageChanged FinancialAssetId EclStage EclStage (Money currency)
    deriving (Show, Eq)
