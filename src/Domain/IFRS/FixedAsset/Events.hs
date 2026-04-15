module Domain.IFRS.FixedAsset.Events (
    FixedAssetEventPayload (..),
)
where

import Data.Time (Day)
import Domain.IFRS.FixedAsset (AssetType, MeasurementModel)
import Domain.IFRS.FixedAsset.ValueObjects.FixedAssetId (FixedAssetId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data FixedAssetEventPayload (currency :: Symbol)
    = -- | 固定資産取得 → DeferredTax集約（一時差異）
      FixedAssetAcquired FixedAssetId AssetType Day (Money currency)
    | -- | 建設仮勘定振替 → DeferredTax集約
      ConstructionInProgressTransferred FixedAssetId (Money currency) Day
    | -- | 減価償却 → DeferredTax集約（償却差異）
      FixedAssetDepreciated FixedAssetId (Money currency) Day
    | -- | 再評価（再評価モデル） → DeferredTax集約、FairValue集約
      FixedAssetRevalued FixedAssetId (Money currency) (Money currency) Day
    | -- | 減損損失認識 → Impairment集約、DeferredTax集約
      FixedAssetImpaired FixedAssetId (Money currency) Day
    | -- | 減損戻入 → Impairment集約、DeferredTax集約
      ImpairmentReversed FixedAssetId (Money currency) Day
    | -- | 測定モデル変更 → AuditTrail集約
      MeasurementModelChanged FixedAssetId MeasurementModel Day
    | -- | 耐用年数変更（見積変更） → AuditTrail集約
      UsefulLifeChanged FixedAssetId Int Day
    | -- | 除却・売却 → DeferredTax集約（一時差異解消）
      FixedAssetDisposed FixedAssetId (Money currency) Day
    deriving (Show, Eq)
