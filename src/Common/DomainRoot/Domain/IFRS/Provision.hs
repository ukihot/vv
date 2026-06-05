{- | 引当金集約ルートエンティティ (IAS 37準拠)
現在の債務、発生確率、最善の見積額を管理する。
-}
module Domain.IFRS.Provision (
    -- * 集約
    Provision (..),
    ProvisionType (..),

    -- * 値オブジェクト
    module Domain.IFRS.Provision.ValueObjects.ProvisionId,
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.Provision.ValueObjects.ProvisionId
import Domain.IFRS.Provision.ValueObjects.Version (Version)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data ProvisionType
    = WarrantyProvision
    | RestructuringProvision
    | LitigationProvision
    | EnvironmentalProvision
    | OneroContractProvision
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data Provision (currency :: Symbol) = Provision
    { provisionId :: ProvisionId
    , provisionType :: ProvisionType
    , provisionRecognitionDate :: Day
    , provisionAmount :: Money currency
    , provisionProbability :: Rational
    , provisionExpectedSettlementDate :: Maybe Day
    , provisionDiscountRate :: Maybe Rational
    , provisionDescription :: Text
    , provisionVersion :: Version
    }
    deriving stock (Show, Eq)
