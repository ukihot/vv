{- | 公正価値測定集約ルートエンティティ (IFRS 13準拠)
公正価値ヒエラルキー、評価技法、インプットデータを管理する。
-}
module Domain.IFRS.FairValue (
    -- * 集約
    FairValueMeasurement (..),
    FairValueHierarchy (..),
    ValuationTechnique (..),

    -- * 値オブジェクト
    module Domain.IFRS.FairValue.ValueObjects.FairValueMeasurementId,
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.FairValue.ValueObjects.FairValueMeasurementId
import Domain.IFRS.FairValue.ValueObjects.Version (Version)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data FairValueHierarchy
    = Level1
    | Level2
    | Level3
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data ValuationTechnique
    = MarketApproach
    | IncomeApproach
    | CostApproach
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data FairValueMeasurement (currency :: Symbol) = FairValueMeasurement
    { fvmId :: FairValueMeasurementId
    , fvmAssetId :: Text
    , fvmMeasurementDate :: Day
    , fvmFairValue :: Money currency
    , fvmHierarchy :: FairValueHierarchy
    , fvmTechnique :: ValuationTechnique
    , fvmInputData :: Text
    , fvmUnobservableInputs :: Maybe Text
    , fvmVersion :: Version
    }
    deriving stock (Show, Eq)
