{- | 減損集約ルートエンティティ (IAS 36準拠)
資金生成単位（CGU）単位での減損判定・測定・戻入を管理する。
-}
module Domain.IFRS.Impairment
    ( -- * 集約
      ImpairmentTest (..)
    , ImpairmentIndicator (..)

      -- * 値オブジェクト
    , module Domain.IFRS.Impairment.ValueObjects.ImpairmentTestId
    , module Domain.IFRS.Impairment.ValueObjects.CguId
    )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.IFRS.Impairment.ValueObjects.CguId
import Domain.IFRS.Impairment.ValueObjects.ImpairmentTestId
import Domain.IFRS.Impairment.ValueObjects.Version (Version, initialVersion)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data ImpairmentIndicator
    = ExternalIndicator Text
    | InternalIndicator Text
    | NoIndicator
    deriving (Show, Eq)

data ImpairmentTest (currency :: Symbol) = ImpairmentTest
    { impairmentTestId :: ImpairmentTestId,
      impairmentCguId :: CguId,
      impairmentTestDate :: Day,
      impairmentCarryingAmount :: Money currency,
      impairmentRecoverableAmount :: Money currency,
      impairmentValueInUse :: Maybe (Money currency),
      impairmentFairValueLessCosts :: Maybe (Money currency),
      impairmentLossAmount :: Money currency,
      impairmentIndicators :: [ImpairmentIndicator],
      impairmentDiscountRate :: Rational,
      impairmentCashFlowProjection :: Text,
      impairmentVersion :: Version
    }
    deriving (Show, Eq)
