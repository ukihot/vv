module Domain.IFRS.Provision.Events
    ( ProvisionEventPayload (..)
    )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.Provision (ProvisionType)
import Domain.IFRS.Provision.ValueObjects.ProvisionId (ProvisionId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data ProvisionEventPayload (currency :: Symbol)
    = -- | 引当金認識 → DeferredTax集約、AuditTrail集約
      ProvisionRecognized ProvisionId ProvisionType Day (Money currency) Rational
    | -- | 引当金再測定 → DeferredTax集約、AuditTrail集約
      ProvisionRemeasured ProvisionId (Money currency) Text Day
    | -- | 時の経過による割引戻し → DeferredTax集約
      ProvisionUnwound ProvisionId (Money currency) Day
    | -- | 引当金使用 → DeferredTax集約
      ProvisionUtilized ProvisionId (Money currency) Day
    | -- | 引当金取崩 → DeferredTax集約
      ProvisionReversed ProvisionId (Money currency) Day
    | -- | 発生確率変更 → AuditTrail集約
      ProvisionProbabilityChanged ProvisionId Rational Day
    deriving (Show, Eq)
