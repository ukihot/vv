{- | 税務設定集約ルートエンティティ
税率・税区分などの税務設定を管理する。
-}
module Domain.Ops.TaxConfiguration (
    -- * 集約
    TaxConfiguration (..),

    -- * 値オブジェクト
    module Domain.Ops.TaxConfiguration.ValueObjects.TaxConfigId,
    module Domain.Ops.TaxConfiguration.ValueObjects.TaxType,
)
where

import Data.Time (Day)
import Domain.Ops.TaxConfiguration.ValueObjects.TaxConfigId
import Domain.Ops.TaxConfiguration.ValueObjects.TaxType
import Domain.Ops.TaxConfiguration.ValueObjects.Version (Version)

data TaxConfiguration = TaxConfiguration
    { taxConfigId :: TaxConfigId
    , taxConfigType :: TaxType
    , taxConfigRate :: Rational
    , taxConfigEffectiveFrom :: Day
    , taxConfigEffectiveTo :: Maybe Day
    , taxConfigVersion :: Version
    }
    deriving stock (Show, Eq)
