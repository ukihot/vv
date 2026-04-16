module Domain.IFRS.Lease.Events (
    LeaseEventPayload (..),
)
where

import Data.Time (Day)
import Domain.IFRS.Lease.ValueObjects.LeaseId (LeaseId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data LeaseEventPayload (currency :: Symbol)
    = -- | リース開始 → FixedAsset集約（使用権資産）、DeferredTax集約
      LeaseCommenced LeaseId Day Int Rational (Money currency)
    | -- | リース支払 → JournalEntry集約（利息費用・元本返済）
      LeasePaymentApplied LeaseId (Money currency) (Money currency) Day
    | -- | 使用権資産償却 → DeferredTax集約
      RightOfUseAssetDepreciated LeaseId (Money currency) Day
    | -- | リース負債再測定 → DeferredTax集約
      LeaseLiabilityRemeasured LeaseId (Money currency) Day
    | -- | リース終了 → FixedAsset集約、DeferredTax集約
      LeaseTerminated LeaseId Day
    deriving stock (Show, Eq)
