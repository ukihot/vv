{- | 為替レート管理集約ルートエンティティ (IAS 21準拠)
取引日レート・期末日レート・平均レートを型で区別し、
誤ったレート種別の適用をコンパイル時に防ぐ。
-}
module Domain.Accounting.ExchangeRate (
    -- * 集約
    ExchangeRate (..),
    mkExchangeRate,

    -- * 値オブジェクト
    module Domain.Accounting.ExchangeRate.ValueObjects.RateKind,
    module Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass,
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Accounting.ExchangeRate.Errors (ExchangeRateError (..))
import Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass
import Domain.Accounting.ExchangeRate.ValueObjects.RateKind
import GHC.TypeLits (Symbol)

data ExchangeRate (from :: Symbol) (to :: Symbol) = ExchangeRate
    { rateValue :: Rational
    , rateKind :: RateKind
    , rateDate :: Day
    , rateSource :: Text
    }
    deriving (Show, Eq)

mkExchangeRate ::
    Rational ->
    RateKind ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate from to)
mkExchangeRate r k d src
    | r <= 0 = Left NonPositiveRate
    | otherwise = Right (ExchangeRate r k d src)
