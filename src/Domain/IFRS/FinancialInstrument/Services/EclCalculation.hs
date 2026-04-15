module Domain.IFRS.FinancialInstrument.Services.EclCalculation (
    computeEcl,
    classifyStage,
)
where

import Domain.IFRS.FinancialInstrument.Entities.EclParameters (EclParameters (..))
import Domain.IFRS.FinancialInstrument.Errors (FinancialInstrumentError (..))
import Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (EclStage (..))
import Domain.Shared (Money, scaleMoney)

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
    | lgd params < 0 || lgd params > 1 = Left InvalidLgd
    | otherwise = Right $ case stage of
        Stage1 -> scaleMoney (pd12Month params * lgd params) ead
        Stage2 -> scaleMoney (pdLifetime params * lgd params * discountFactor params) ead
        Stage3 -> scaleMoney (pdLifetime params * lgd params * discountFactor params) ead
