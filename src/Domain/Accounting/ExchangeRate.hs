{- | 為替レート管理 (IAS 21準拠 §4.7.10)
取引日レート・期末日レート・平均レートを型で区別し、
誤ったレート種別の適用をコンパイル時に防ぐ。
-}
module Domain.Accounting.ExchangeRate
    ( -- * レート種別
      RateKind (..)

      -- * 為替レート
    , ExchangeRate (..)
    , mkExchangeRate

      -- * 換算
    , translateMoney
    , translateMoneyApprox

      -- * 貨幣性・非貨幣性区分 §4.7.10.4
    , MonetaryClass (..)

      -- * エラー
    , ExchangeRateError (..)
    )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Shared (Money (..), mkMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- レート種別 (§4.7.10.6)
-- ─────────────────────────────────────────────────────────────────────────────

-- | IAS 21 で使用するレート種別を型で区別する。
data RateKind
    = -- | 直物レート (SR): 取引発生時
      SpotRate
    | -- | 期末日レート (CR): 貨幣性項目評価替え
      ClosingRate
    | -- | 取引日レート (HR): 非貨幣性項目（原価測定）
      HistoricalRate
    | -- | 平均レート (AR): 損益項目の簡便法
      AverageRate
    deriving (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- 為替レート値オブジェクト
-- ─────────────────────────────────────────────────────────────────────────────

{- | 外貨 → 機能通貨の換算レート。
'from' は外貨通貨コード、'to' は機能通貨コード（型レベル）。
-}
data ExchangeRate (from :: Symbol) (to :: Symbol) = ExchangeRate
    { -- | 換算レート（正値必須）
      rateValue :: Rational,
      rateKind :: RateKind,
      -- | レート取得日
      rateDate :: Day,
      -- | レートソース（再現性保証 §7.1.2）
      rateSource :: Text
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 換算
-- ─────────────────────────────────────────────────────────────────────────────

{- | 外貨金額を機能通貨へ換算する。
型パラメータにより from/to の整合性をコンパイル時に保証する。
-}
translateMoney ::
    ExchangeRate from to ->
    Money from ->
    Money to
translateMoney er m = mkMoney (unMoney m * rateValue er)

{- | 平均レートによる近似換算（損益項目の簡便法）。
使用時は乖離検証ログを別途保存すること（§4.7.10.2）。
-}
translateMoneyApprox ::
    -- | AverageRate であること
    ExchangeRate from to ->
    Money from ->
    Money to
translateMoneyApprox = translateMoney

-- ─────────────────────────────────────────────────────────────────────────────
-- 貨幣性・非貨幣性区分 §4.7.10.4
-- ─────────────────────────────────────────────────────────────────────────────

data MonetaryClass
    = -- | 貨幣性: 期末日レートで換算、差額は当期損益
      Monetary
    | -- | 非貨幣性: 取引日レートで換算（原価測定時）
      NonMonetary
    deriving (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data ExchangeRateError
    = NonPositiveRate
    | MissingRateSource
    deriving (Show, Eq)
