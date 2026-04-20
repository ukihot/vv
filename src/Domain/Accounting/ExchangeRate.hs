{- | 為替レート管理集約ルートエンティティ (IAS 21準拠)
取引日レート・期末日レート・平均レートを型で区別し、
誤ったレート種別の適用をコンパイル時に防ぐ。
-}
module Domain.Accounting.ExchangeRate (
    -- * 集約
    ExchangeRate,
    exchangeRateKind,
    exchangeRateValue,
    exchangeRateDate,
    exchangeRateSource,
    mkSpotRate,
    mkClosingRate,
    mkHistoricalRate,
    mkAverageRate,

    -- * エラー
    ExchangeRateError (..),

    -- * 値オブジェクト
    module Domain.Accounting.ExchangeRate.ValueObjects.RateKind,
    module Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass,

    -- * サービス
    translateAtSpot,
    translateMonetary,
    translateNonMonetaryHistorical,
    translateByAverage,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (Day)
import Domain.Accounting.ExchangeRate.Errors (ExchangeRateError (..))
import Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass
import Domain.Accounting.ExchangeRate.ValueObjects.RateKind
import Domain.Shared (Money, toRationalMoney)
import GHC.TypeLits (Symbol)
import Money qualified

data ExchangeRate (kind :: RateKind) (from :: Symbol) (to :: Symbol) = ExchangeRate
    { exchangeRateKind :: RateKind
    , exchangeRateValue :: Rational
    , exchangeRateDate :: Day
    , exchangeRateSource :: Text
    }
    deriving stock (Show, Eq)

mkRate ::
    RateKind ->
    Rational ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate kind from to)
mkRate kind r d src
    | r <= 0 = Left NonPositiveRate
    | T.null (T.strip src) = Left MissingRateSource
    | otherwise = Right (ExchangeRate kind r d src)

mkSpotRate ::
    Rational ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate 'SpotRate from to)
mkSpotRate = mkRate SpotRate

mkClosingRate ::
    Rational ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate 'ClosingRate from to)
mkClosingRate = mkRate ClosingRate

mkHistoricalRate ::
    Rational ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate 'HistoricalRate from to)
mkHistoricalRate = mkRate HistoricalRate

mkAverageRate ::
    Rational ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate 'AverageRate from to)
mkAverageRate = mkRate AverageRate

-- ─────────────────────────────────────────────────────────────────────────────
-- サービス（循環インポート回避のためファサードに直接定義）
-- ─────────────────────────────────────────────────────────────────────────────

translateAtSpot ::
    ExchangeRate 'SpotRate from to ->
    Money from ->
    Money to
translateAtSpot er amount = Money.dense' (toRationalMoney amount * exchangeRateValue er)

translateMonetary ::
    ExchangeRate 'ClosingRate from to ->
    Money from ->
    Money to
translateMonetary er amount = Money.dense' (toRationalMoney amount * exchangeRateValue er)

translateNonMonetaryHistorical ::
    ExchangeRate 'HistoricalRate from to ->
    Money from ->
    Money to
translateNonMonetaryHistorical er amount = Money.dense' (toRationalMoney amount * exchangeRateValue er)

translateByAverage ::
    ExchangeRate 'AverageRate from to ->
    Money from ->
    Money to
translateByAverage er amount = Money.dense' (toRationalMoney amount * exchangeRateValue er)
