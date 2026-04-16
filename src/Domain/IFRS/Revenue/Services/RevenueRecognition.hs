module Domain.IFRS.Revenue.Services.RevenueRecognition (
    recognizeRevenue,
)
where

import Data.Time (Day)
import Domain.IFRS.Revenue.Entities.PerformanceObligation (
    PerformanceObligation (..),
    SatisfactionPattern (..),
 )
import Domain.IFRS.Revenue.Entities.RevenueJudgmentLog (RevenueJudgmentLog (..))
import Domain.IFRS.Revenue.Entities.RevenueRecognitionResult (RevenueRecognitionResult (..))
import Domain.IFRS.Revenue.Errors (RevenueError (..))

recognizeRevenue ::
    PerformanceObligation currency ->
    Day ->
    RevenueJudgmentLog currency ->
    Either RevenueError (RevenueRecognitionResult currency)
recognizeRevenue po date judgmentLog
    | poPattern po /= AtPointInTime = Left CannotRecognizeOverTimeObligationAtPoint
    | otherwise =
        Right
            RevenueRecognitionResult
                { rrrContractId = rjlContractId judgmentLog
                , rrrObligationId = poId po
                , rrrRecognizedAmt = poAllocatedPrice po
                , rrrRecognizedAt = date
                , rrrJudgmentLog = judgmentLog
                }
