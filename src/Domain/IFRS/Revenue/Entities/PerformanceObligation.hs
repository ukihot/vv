module Domain.IFRS.Revenue.Entities.PerformanceObligation (
    PerformanceObligation (..),
    PerformanceObligationId (..),
    SatisfactionPattern (..),
    ProgressMethod (..),
)
where

import Data.Text (Text)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

newtype PerformanceObligationId = PerformanceObligationId {unPOId :: Text}
    deriving stock (Show, Eq, Ord)

data SatisfactionPattern
    = AtPointInTime
    | OverTime
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data ProgressMethod
    = InputMethod
    | OutputMethod
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data PerformanceObligation (currency :: Symbol) = PerformanceObligation
    { poId :: PerformanceObligationId
    , poDescription :: Text
    , poPattern :: SatisfactionPattern
    , poProgressMethod :: Maybe ProgressMethod
    , poStandalonePrice :: Money currency
    , poAllocatedPrice :: Money currency
    }
    deriving stock (Show, Eq)
