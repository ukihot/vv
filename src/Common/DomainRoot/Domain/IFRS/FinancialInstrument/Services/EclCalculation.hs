module Domain.IFRS.FinancialInstrument.Services.EclCalculation (
    computeEcl,
    classifyStage,
)
where

import Domain.IFRS.FinancialInstrument.Entities.EclParameters (
    EclParameters,
    ScenarioWeight,
    discountFactor,
    lgd,
    pd12Month,
    pdLifetime,
    scenarioWeights,
    unWeight,
 )
import Domain.IFRS.FinancialInstrument.Errors (FinancialInstrumentError (..))
import Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (EclStage (..))
import Domain.Shared (Money, scaleMoney, toRationalMoney)

classifyStage :: Int -> Bool -> Bool -> EclStage
classifyStage daysOverdue ratingDeteriorated legalDefault
    | legalDefault || daysOverdue > 90 = Stage3
    | daysOverdue > 30 || ratingDeteriorated = Stage2
    | otherwise = Stage1

computeEcl ::
    EclStage ->
    Money currency ->
    EclParameters ->
    Either FinancialInstrumentError (Money currency)
computeEcl stage ead params
    | toRationalMoney ead < 0 = Left NegativeEad
    | not (inUnitInterval (pd12Month params)) = Left InvalidPd
    | not (inUnitInterval (pdLifetime params)) = Left InvalidPd
    | not (inUnitInterval (lgd params)) = Left InvalidLgd
    | discountFactor params <= 0 || discountFactor params > 1 = Left InvalidDiscountFactor
    | not (validScenarioWeights (scenarioWeights params)) = Left InvalidScenarioWeights
    | otherwise = Right $ case stage of
        Stage1 -> scaleMoney (pd12Month params * lgd params) ead
        Stage2 -> scaleMoney (pdLifetime params * lgd params * discountFactor params) ead
        Stage3 -> scaleMoney (pdLifetime params * lgd params * discountFactor params) ead

inUnitInterval :: Rational -> Bool
inUnitInterval value = value >= 0 && value <= 1

validScenarioWeights :: [(scenario, ScenarioWeight)] -> Bool
validScenarioWeights weights =
    not (null weights)
        && all (\(_, weight) -> inUnitInterval (unWeight weight)) weights
        && sum (map (unWeight . snd) weights) == 1
