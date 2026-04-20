module Domain.IFRS.FinancialInstrument.Entities.EclParameters (
    EclParameters,
    EconomicScenario (..),
    ScenarioWeight,
    mkScenarioWeight,
    unWeight,
    mkEclParameters,
    pd12Month,
    pdLifetime,
    lgd,
    discountFactor,
    scenarioWeights,
)
where

import Domain.IFRS.FinancialInstrument.Errors (FinancialInstrumentError (..))

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

mkScenarioWeight :: Rational -> Either FinancialInstrumentError ScenarioWeight
mkScenarioWeight weight
    | weight < 0 || weight > 1 = Left InvalidScenarioWeights
    | otherwise = Right (ScenarioWeight weight)

mkEclParameters ::
    Rational ->
    Rational ->
    Rational ->
    Rational ->
    [(EconomicScenario, ScenarioWeight)] ->
    Either FinancialInstrumentError EclParameters
mkEclParameters pd12 pdLife lossGivenDefault df weights
    | not (inUnitInterval pd12) = Left InvalidPd
    | not (inUnitInterval pdLife) = Left InvalidPd
    | not (inUnitInterval lossGivenDefault) = Left InvalidLgd
    | df <= 0 || df > 1 = Left InvalidDiscountFactor
    | not (validScenarioWeights weights) = Left InvalidScenarioWeights
    | otherwise =
        Right
            EclParameters
                { pd12Month = pd12
                , pdLifetime = pdLife
                , lgd = lossGivenDefault
                , discountFactor = df
                , scenarioWeights = weights
                }

inUnitInterval :: Rational -> Bool
inUnitInterval value = value >= 0 && value <= 1

validScenarioWeights :: [(EconomicScenario, ScenarioWeight)] -> Bool
validScenarioWeights weights =
    not (null weights)
        && all (\(_, weight) -> inUnitInterval (unWeight weight)) weights
        && sum (map (unWeight . snd) weights) == 1
