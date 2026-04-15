module Domain.IFRS.Revenue.Entities.RevenueRecognitionResult (
    RevenueRecognitionResult (..),
)
where

import Data.Time (Day)
import Domain.IFRS.Revenue.Entities.PerformanceObligation (PerformanceObligationId)
import Domain.IFRS.Revenue.Entities.RevenueJudgmentLog (RevenueJudgmentLog)
import Domain.IFRS.Revenue.ValueObjects.ContractId (ContractId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data RevenueRecognitionResult (currency :: Symbol) = RevenueRecognitionResult
    { rrrContractId :: ContractId
    , rrrObligationId :: PerformanceObligationId
    , rrrRecognizedAmt :: Money currency
    , rrrRecognizedAt :: Day
    , rrrJudgmentLog :: RevenueJudgmentLog currency
    }
    deriving (Show, Eq)
