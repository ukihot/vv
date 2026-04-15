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
    deriving (Show, Eq, Ord)

data SatisfactionPattern
    = AtPointInTime
    | OverTime
    deriving (Show, Eq, Ord, Enum, Bounded)

data ProgressMethod
    = InputMethod
    | OutputMethod
    deriving (Show, Eq, Ord, Enum, Bounded)

data PerformanceObligation (currency :: Symbol) = PerformanceObligation
    { poId :: PerformanceObligationId
    , poDescription :: Text
    , poPattern :: SatisfactionPattern
    , poProgressMethod :: Maybe ProgressMethod
    , poStandalonePrice :: Money currency
    , poAllocatedPrice :: Money currency
    }
    deriving (Show, Eq)
