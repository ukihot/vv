module Domain.IFRS.FinancialInstrument.Events (
    FinancialInstrumentEventPayload (..),
)
where

import Data.Time (Day)
import Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (EclStage)
import Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (FinancialAssetId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data FinancialInstrumentEventPayload (currency :: Symbol)
    = -- | 金融資産認識 → DeferredTax集約（一時差異発生）
      FinancialAssetRecorded FinancialAssetId Day (Money currency) Rational
    | -- | ECLステージ変更 → DeferredTax集約、AuditTrail集約
      EclStageChanged FinancialAssetId EclStage EclStage (Money currency) Day
    | -- | ECL引当金計上 → DeferredTax集約（一時差異）
      EclAllowanceRecognized FinancialAssetId (Money currency) Day
    | -- | 金融資産減損 → Impairment集約、DeferredTax集約
      FinancialAssetImpaired FinancialAssetId (Money currency) Day
    | -- | 金融資産除却 → DeferredTax集約（一時差異解消）
      FinancialAssetDerecognized FinancialAssetId Day
    deriving stock (Show, Eq)
