{- | 全集約横断の共有型定義
safe-money の Dense を財務金額の基盤とし、
通貨タグを型レベルで強制することで異通貨混算をコンパイル時に排除する。
-}
module Domain.Shared (
    -- * 財務金額
    Money (..),
    mkMoney,
    addMoney,
    subMoney,
    negateMoney,
    zeroMoney,
    scaleMoney,
    unMoney,

    -- * 通貨コード (ISO 4217)
    CurrencyCode (..),

    -- * 会計期間
    FiscalYearMonth (..),
    fiscalYearMonth,

    -- * 仕訳行為区分 (§2.1.1)
    JournalEntryKind (..),

    -- * リスク分類 (§3.2)
    RiskClass (..),

    -- * 重要性判定結果 (§3.1)
    MaterialityResult (..),

    -- * バージョン
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Data.Text (Text)
import GHC.Generics (Generic)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 財務金額
-- safe-money の Dense は有理数精度で金額を保持し、
-- 型パラメータ (currency :: Symbol) により通貨を型レベルで区別する。
-- ─────────────────────────────────────────────────────────────────────────────

{- | 通貨タグ付き金額。
'Dense' は分母を持つ有理数表現であり、丸め誤差が発生しない。
表示・永続化時のみ 'discretise' で丸める。
-}
newtype Money (currency :: Symbol) = Money
    { unMoney :: Rational
    -- ^ 内部表現は有理数。safe-money の Dense と同等の精度保証。
    }
    deriving stock (Show, Eq, Ord, Generic)

-- | 同一通貨の加算を (<>) で表現する。異通貨は型が通らない（項目 #3, #11）。
instance Semigroup (Money c) where
    (<>) = addMoney

-- | 単位元は zeroMoney。mconcat で仕訳行の合計が自然に書ける（項目 #33）。
instance Monoid (Money c) where
    mempty = zeroMoney

-- | 金額コンストラクタ。負値も許容（負債・費用の逆仕訳等）。
mkMoney :: Rational -> Money currency
mkMoney = Money

zeroMoney :: Money currency
zeroMoney = Money 0

addMoney :: Money c -> Money c -> Money c
addMoney a b = mkMoney (unMoney a + unMoney b)

subMoney :: Money c -> Money c -> Money c
subMoney a b = mkMoney (unMoney a - unMoney b)

negateMoney :: Money c -> Money c
negateMoney a = mkMoney (negate (unMoney a))

-- | スカラー倍（割引率・配賦比率等に使用）
scaleMoney :: Rational -> Money c -> Money c
scaleMoney r a = mkMoney (r * unMoney a)

-- ─────────────────────────────────────────────────────────────────────────────
-- 通貨コード
-- ─────────────────────────────────────────────────────────────────────────────

{- | ISO 4217 通貨コード（実行時値）。
型レベル通貨タグと対応させて使用する。
-}
newtype CurrencyCode = CurrencyCode {unCurrencyCode :: Text}
    deriving stock (Show, Eq, Ord)

-- ─────────────────────────────────────────────────────────────────────────────
-- 会計期間
-- ─────────────────────────────────────────────────────────────────────────────

-- | 年月で表現する会計期間単位。
data FiscalYearMonth = FiscalYearMonth
    { fymYear :: Int
    , fymMonth :: Int -- 1–12
    }
    deriving stock (Show, Eq, Ord)

fiscalYearMonth :: Int -> Int -> Either Text FiscalYearMonth
fiscalYearMonth y m
    | m < 1 || m > 12 = Left "月は1〜12の範囲で指定してください"
    | y < 1900 = Left "年が不正です"
    | otherwise = Right (FiscalYearMonth y m)

-- ─────────────────────────────────────────────────────────────────────────────
-- 仕訳行為区分 §2.1.1
-- ─────────────────────────────────────────────────────────────────────────────

{- | 仕訳の経済的意味を明示する区分。
既存仕訳の直接変更を禁止し、すべての訂正をこの区分で表現する。
-}
data JournalEntryKind
    = -- | 新規起票仕訳: 経済事象の第一次認識
      OriginalEntry
    | -- | 取消仕訳: 既存仕訳の効力を無効化
      ReversalEntry
    | -- | 反対仕訳: 残高または期間帰属の反転
      CounterEntry
    | -- | 追加仕訳: 計上不足・後日判明事項の補正
      SupplementaryEntry
    | -- | 再分類仕訳: 測定額を変えず表示区分のみ変更
      ReclassEntry
    | -- | 洗替仕訳: 既存評価額を消去し再評価
      WashEntry
    deriving stock (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- リスク分類 §3.2
-- ─────────────────────────────────────────────────────────────────────────────

data RiskClass
    = -- | 定型処理 / 担当者承認
      RiskLow
    | -- | 見積含有 / 管理職承認
      RiskMedium
    | -- | 予測依存 / 財務責任者承認
      RiskHigh
    | -- | 経営判断 / CFO承認
      RiskCritical
    deriving stock (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- 重要性判定 §3.1
-- ─────────────────────────────────────────────────────────────────────────────

data MaterialityResult
    = -- | 重要性あり → 修正必須
      Material
    | -- | 重要性なし → 修正任意
      Immaterial
    deriving stock (Show, Eq, Ord)

-- ─────────────────────────────────────────────────────────────────────────────
-- バージョン（楽観的ロック #51, #52）
-- 全集約共通。IAM・Accounting・IFRS すべてで同一型を使用する (#11)。
-- ─────────────────────────────────────────────────────────────────────────────

newtype Version = Version {unVersion :: Int}
    deriving stock (Show, Eq, Ord)

initialVersion :: Version
initialVersion = Version 0

nextVersion :: Version -> Version
nextVersion (Version v) = Version (v + 1)
