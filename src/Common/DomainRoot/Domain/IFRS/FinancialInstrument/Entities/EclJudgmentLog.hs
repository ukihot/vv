module Domain.IFRS.FinancialInstrument.Entities.EclJudgmentLog (
    EclJudgmentLog (..),
)
where

import Data.Text (Text)
import Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (EclStage)
import Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (FinancialAssetId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data EclJudgmentLog (currency :: Symbol) = EclJudgmentLog
    { ejlAssetId :: FinancialAssetId
    , ejlPreviousStage :: EclStage
    , ejlNewStage :: EclStage
    , ejlEclAmount :: Money currency
    , ejlMovementReason :: Text
    }
    deriving stock (Show, Eq)
