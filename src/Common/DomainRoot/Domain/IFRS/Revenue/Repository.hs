module Domain.IFRS.Revenue.Repository (
    RevenueRepository (..),
)
where

import Domain.IFRS.Revenue.Entities.RevenueRecognitionResult (RevenueRecognitionResult)
import Domain.IFRS.Revenue.ValueObjects.ContractId (ContractId)

class Monad m => RevenueRepository m currency where
    saveRevenueRecognition :: RevenueRecognitionResult currency -> m ()
    findRevenueByContractId :: ContractId -> m [RevenueRecognitionResult currency]
