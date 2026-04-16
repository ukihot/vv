{-# LANGUAGE StandaloneDeriving #-}

module Domain.IFRS.DeferredTax.Events (
    DeferredTaxEventPayload (..),
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.DeferredTax (TemporaryDifferenceType)
import Domain.IFRS.DeferredTax.ValueObjects.DeferredTaxItemId (DeferredTaxItemId)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (KnownSymbol, Symbol)

data DeferredTaxEventPayload (currency :: Symbol)
    = -- | 一時差異認識 → AuditTrail集約
      TemporaryDifferenceIdentified
        DeferredTaxItemId
        FiscalYearMonth
        TemporaryDifferenceType
        (Money currency)
        Day
    | -- | 繰延税金資産認識 → AuditTrail集約（回収可能性判断）
      DeferredTaxAssetRecognized DeferredTaxItemId (Money currency) Text Day
    | -- | 繰延税金負債認識
      DeferredTaxLiabilityRecognized DeferredTaxItemId (Money currency) Day
    | -- | 税率変更による再測定 → AuditTrail集約
      DeferredTaxRemeasuredForRateChange DeferredTaxItemId Rational (Money currency) Day
    | -- | 回収可能性再評価 → AuditTrail集約
      RecoverabilityReassessed DeferredTaxItemId (Money currency) Text Day
    | -- | 一時差異解消
      TemporaryDifferenceReversed DeferredTaxItemId (Money currency) Day

deriving stock instance KnownSymbol currency => Show (DeferredTaxEventPayload currency)
deriving stock instance Eq (DeferredTaxEventPayload currency)
