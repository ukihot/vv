module Domain.IFRS.FairValue.Events (
    FairValueEventPayload (..),
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.FairValue (FairValueHierarchy, ValuationTechnique)
import Domain.IFRS.FairValue.ValueObjects.FairValueMeasurementId (FairValueMeasurementId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data FairValueEventPayload (currency :: Symbol)
    = -- | 公正価値測定 → FixedAsset集約、FinancialInstrument集約、AuditTrail集約
      FairValueMeasured
        FairValueMeasurementId
        Text
        Day
        (Money currency)
        FairValueHierarchy
        ValuationTechnique
    | -- | 公正価値再測定 → 関連集約
      FairValueRemeasured FairValueMeasurementId (Money currency) Day
    | -- | ヒエラルキーレベル変更 → AuditTrail集約
      FairValueHierarchyChanged FairValueMeasurementId FairValueHierarchy FairValueHierarchy Day
    | -- | 評価技法変更 → AuditTrail集約
      ValuationTechniqueChanged FairValueMeasurementId ValuationTechnique Text Day
    | -- | 観察不能インプット使用 → AuditTrail集約（Level3）
      UnobservableInputsUsed FairValueMeasurementId Text Day
    deriving (Show, Eq)
