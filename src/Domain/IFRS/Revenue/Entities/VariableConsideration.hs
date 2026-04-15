module Domain.IFRS.Revenue.Entities.VariableConsideration (
    VariableConsideration (..),
    VariableConsiderationMethod (..),
)
where

import Data.Text (Text)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data VariableConsiderationMethod
    = ExpectedValueMethod
    | MostLikelyAmount
    deriving (Show, Eq, Ord, Enum, Bounded)

data VariableConsideration (currency :: Symbol) = VariableConsideration
    { vcDescription :: Text
    , vcMethod :: VariableConsiderationMethod
    , vcEstimatedAmount :: Money currency
    , vcConstraintNote :: Text
    }
    deriving (Show, Eq)
