module Domain.IFRS.FinancialInstrument.Entities.EclParameters (
    EclParameters (..),
    EconomicScenario (..),
    ScenarioWeight (..),
)
where

data EconomicScenario
    = BaseScenario
    | OptimisticScenario
    | PessimisticScenario
    deriving stock (Show, Eq, Ord, Enum, Bounded)

newtype ScenarioWeight = ScenarioWeight {unWeight :: Rational}
    deriving stock (Show, Eq, Ord)

data EclParameters = EclParameters
    { pd12Month :: Rational
    , pdLifetime :: Rational
    , lgd :: Rational
    , discountFactor :: Rational
    , scenarioWeights :: [(EconomicScenario, ScenarioWeight)]
    }
    deriving stock (Show, Eq)
