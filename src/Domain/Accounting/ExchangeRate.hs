{- | 為替レート管理集約ルートエンティティ (IAS 21準拠)
取引日レート・期末日レート・平均レートを型で区別し、
誤ったレート種別の適用をコンパイル時に防ぐ。
-}
module Domain.Accounting.ExchangeRate (
    -- * 集約
    ExchangeRate (..),
    mkExchangeRate,

    -- * エラー
    ExchangeRateError (..),

    -- * 値オブジェクト
    module Domain.Accounting.ExchangeRate.ValueObjects.RateKind,
    module Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass,

    -- * サービス
    translateMoney,
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Accounting.ExchangeRate.Errors (ExchangeRateError (..))
import Domain.Accounting.ExchangeRate.ValueObjects.MonetaryClass
import Domain.Accounting.ExchangeRate.ValueObjects.RateKind
import Domain.Shared (Money, toRationalMoney)
import GHC.TypeLits (Symbol)
import Money qualified

data ExchangeRate (from :: Symbol) (to :: Symbol) = ExchangeRate
    { rateValue :: Rational
    , rateKind :: RateKind
    , rateDate :: Day
    , rateSource :: Text
    }
    deriving stock (Show, Eq)

mkExchangeRate ::
    Rational ->
    RateKind ->
    Day ->
    Text ->
    Either ExchangeRateError (ExchangeRate from to)
mkExchangeRate r k d src
    | r <= 0 = Left NonPositiveRate
    | otherwise = Right (ExchangeRate r k d src)

-- ─────────────────────────────────────────────────────────────────────────────
-- サービス（循環インポート回避のためファサードに直接定義）
-- ─────────────────────────────────────────────────────────────────────────────

translateMoney ::
    ExchangeRate from to ->
    Money from ->
    Money to
translateMoney er m = Money.dense' (toRationalMoney m * rateValue er)
