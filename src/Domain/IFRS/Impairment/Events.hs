module Domain.IFRS.Impairment.Events (
    ImpairmentEventPayload (..),
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.Impairment.ValueObjects.CguId (CguId)
import Domain.IFRS.Impairment.ValueObjects.ImpairmentTestId (ImpairmentTestId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data ImpairmentEventPayload (currency :: Symbol)
    = -- | 減損兆候検出 → AuditTrail集約、FixedAsset集約
      ImpairmentIndicatorDetected CguId Text Day
    | -- | 減損テスト実施 → AuditTrail集約（判断ログ）
      ImpairmentTestPerformed ImpairmentTestId CguId Day (Money currency) (Money currency)
    | -- | 減損損失認識 → FixedAsset集約、DeferredTax集約
      ImpairmentLossRecognized ImpairmentTestId CguId (Money currency) Day
    | -- | 減損戻入 → FixedAsset集約、DeferredTax集約
      ImpairmentReversed ImpairmentTestId CguId (Money currency) Day
    | -- | 使用価値算定 → AuditTrail集約（割引率・CF予測）
      ValueInUseCalculated ImpairmentTestId (Money currency) Rational Day
    deriving (Show, Eq)
