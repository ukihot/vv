module Domain.IFRS.Revenue.Events (
    RevenueEventPayload (..),
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.Revenue.Entities.PerformanceObligation (PerformanceObligationId)
import Domain.IFRS.Revenue.ValueObjects.ContractId (ContractId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data RevenueEventPayload (currency :: Symbol)
    = -- | 契約識別 → AuditTrail集約（判断ログ）
      ContractIdentified ContractId Day Text
    | -- | 履行義務識別 → AuditTrail集約
      PerformanceObligationIdentified ContractId PerformanceObligationId Text Day
    | -- | 取引価格配分 → AuditTrail集約
      TransactionPriceAllocated ContractId [(PerformanceObligationId, Money currency)] Day
    | -- | 収益認識 → Segment集約、DeferredTax集約
      RevenueRecognized ContractId PerformanceObligationId (Money currency) Day
    | -- | 変動対価見積変更 → AuditTrail集約
      VariableConsiderationRemeasured ContractId (Money currency) Day
    | -- | 契約変更 → AuditTrail集約
      ContractModified ContractId Text Day
    deriving stock (Show, Eq)
