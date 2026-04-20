module Domain.IFRS.Revenue.Entities.PerformanceObligation (
    PerformanceObligation,
    PerformanceObligationId,
    mkPerformanceObligationId,
    unPerformanceObligationId,
    mkPerformanceObligation,
    withAllocatedPrice,
    poId,
    poDescription,
    poPattern,
    poProgressMethod,
    poStandalonePrice,
    poAllocatedPrice,
    SatisfactionPattern (..),
    ProgressMethod (..),
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Revenue.Errors (RevenueError (..))
import Domain.Shared (Money)
import Domain.Shared qualified as Shared
import GHC.TypeLits (Symbol)

newtype PerformanceObligationId = PerformanceObligationId {unPerformanceObligationId :: Text}
    deriving stock (Show, Eq, Ord)

mkPerformanceObligationId :: Text -> Either RevenueError PerformanceObligationId
mkPerformanceObligationId raw
    | T.null normalized = Left InvalidPerformanceObligationId
    | otherwise = Right (PerformanceObligationId normalized)
    where
        normalized = T.strip raw

data SatisfactionPattern
    = AtPointInTime
    | OverTime
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data ProgressMethod
    = InputMethod
    | OutputMethod
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data PerformanceObligation (currency :: Symbol) = PerformanceObligation
    { obligationId :: PerformanceObligationId
    , obligationDescription :: Text
    , obligationPattern :: SatisfactionPattern
    , obligationProgressMethod :: Maybe ProgressMethod
    , obligationStandalonePrice :: Money currency
    , obligationAllocatedPrice :: Money currency
    }
    deriving stock (Show, Eq)

mkPerformanceObligation ::
    PerformanceObligationId ->
    Text ->
    SatisfactionPattern ->
    Maybe ProgressMethod ->
    Money currency ->
    Either RevenueError (PerformanceObligation currency)
mkPerformanceObligation obligationId description pattern_ progressMethod standalonePrice
    | Shared.toRationalMoney standalonePrice <= 0 = Left NonPositiveStandalonePrice
    | otherwise =
        Right
            PerformanceObligation
                { obligationId = obligationId
                , obligationDescription = description
                , obligationPattern = pattern_
                , obligationProgressMethod = progressMethod
                , obligationStandalonePrice = standalonePrice
                , obligationAllocatedPrice = Shared.zeroMoney
                }

withAllocatedPrice ::
    Money currency ->
    PerformanceObligation currency ->
    Either RevenueError (PerformanceObligation currency)
withAllocatedPrice allocated obligation
    | Shared.toRationalMoney allocated < 0 = Left NegativeAllocatedPrice
    | otherwise = Right obligation {obligationAllocatedPrice = allocated}

poId :: PerformanceObligation currency -> PerformanceObligationId
poId = obligationId

poDescription :: PerformanceObligation currency -> Text
poDescription = obligationDescription

poPattern :: PerformanceObligation currency -> SatisfactionPattern
poPattern = obligationPattern

poProgressMethod :: PerformanceObligation currency -> Maybe ProgressMethod
poProgressMethod = obligationProgressMethod

poStandalonePrice :: PerformanceObligation currency -> Money currency
poStandalonePrice = obligationStandalonePrice

poAllocatedPrice :: PerformanceObligation currency -> Money currency
poAllocatedPrice = obligationAllocatedPrice
