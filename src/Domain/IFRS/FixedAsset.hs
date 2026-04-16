{- | 固定資産集約ルートエンティティ (IAS 16, IAS 38準拠)
有形固定資産・無形資産のコンポーネント単位管理、
償却、減損、再評価を統合管理する。
-}
module Domain.IFRS.FixedAsset (
    -- * 集約
    FixedAsset (..),
    AssetType (..),
    MeasurementModel (..),
    DepreciationMethod (..),

    -- * 値オブジェクト
    module Domain.IFRS.FixedAsset.ValueObjects.FixedAssetId,
    module Domain.IFRS.FixedAsset.ValueObjects.ComponentId,
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)
import Domain.IFRS.FixedAsset.ValueObjects.ComponentId
import Domain.IFRS.FixedAsset.ValueObjects.FixedAssetId
import Domain.IFRS.FixedAsset.ValueObjects.Version (Version, initialVersion)
import Domain.IFRS.Impairment.ValueObjects.CguId (CguId)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data AssetType
    = TangibleAsset
    | IntangibleAsset
    | RightOfUseAsset
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data MeasurementModel
    = CostModel
    | RevaluationModel
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data DepreciationMethod
    = StraightLine
    | DecliningBalance Rational
    | UnitsOfProduction
    deriving stock (Show, Eq)

data FixedAsset (currency :: Symbol) = FixedAsset
    { faId :: FixedAssetId
    , faComponentId :: Maybe ComponentId
    , faAccountCode :: AccountCode
    , faAssetType :: AssetType
    , faMeasurementModel :: MeasurementModel
    , faCguId :: Maybe CguId
    , faAcquisitionDate :: Day
    , faCost :: Money currency
    , faRevaluationAmount :: Maybe (Money currency)
    , faUsefulLife :: Maybe Int
    , faResidualValue :: Money currency
    , faDepreciationMethod :: DepreciationMethod
    , faAccumulatedDepreciation :: Money currency
    , faImpairmentLoss :: Money currency
    , faCarryingAmount :: Money currency
    , faVersion :: Version
    }
    deriving stock (Show, Eq)
