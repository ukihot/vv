module Domain.IFRS.Revenue.Entities.RevenueJudgmentLog (
    RevenueJudgmentLog (..),
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.Revenue.Entities.PerformanceObligation (ProgressMethod)
import Domain.IFRS.Revenue.Entities.VariableConsideration (VariableConsideration)
import Domain.IFRS.Revenue.ValueObjects.AllocationMethod (AllocationMethod)
import Domain.IFRS.Revenue.ValueObjects.ContractId (ContractId)
import GHC.TypeLits (Symbol)

data RevenueJudgmentLog (currency :: Symbol) = RevenueJudgmentLog
    { rjlContractId :: ContractId
    , rjlStep1ContractExists :: Bool
    , rjlStep2ObligationBasis :: Text
    , rjlStep3AllocationMethod :: AllocationMethod
    , rjlStep3VariableConsideration :: Maybe (VariableConsideration currency)
    , rjlStep5ProgressMethod :: Maybe ProgressMethod
    , rjlJudgmentDate :: Day
    }
    deriving stock (Show, Eq)
