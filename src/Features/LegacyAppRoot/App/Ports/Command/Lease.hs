module App.Ports.Command.Lease (
    RegisterLeaseContractUseCase (..),
    MeasureRightOfUseAssetUseCase (..),
    MeasureLeaseLiabilityUseCase (..),
    RemeasureLeaseUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Lease Accounting (リース会計 - IFRS 16)
-- ============================================================================

class Monad m => RegisterLeaseContractUseCase m where
    executeRegisterLeaseContract :: Text -> Day -> Int -> Double -> Double -> m (Either Text Text)

-- contractNumber, commencementDate, leaseTerm, monthlyPayment, discountRate -> leaseId

class Monad m => MeasureRightOfUseAssetUseCase m where
    executeMeasureRightOfUseAsset :: Text -> Day -> m (Either Text Double)

-- leaseId, date -> rouAssetAmount

class Monad m => MeasureLeaseLiabilityUseCase m where
    executeMeasureLeaseLiability :: Text -> Day -> m (Either Text Double)

-- leaseId, date -> leaseLiabilityAmount

class Monad m => RemeasureLeaseUseCase m where
    executeRemeasureLease :: Text -> Day -> Text -> m (Either Text Text)

-- leaseId, date, reason -> remeasurementId
