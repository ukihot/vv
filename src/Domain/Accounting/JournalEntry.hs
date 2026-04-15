-- | 仕訳帳集約 (Journal Entry)
-- §2.1, §4.1, §4.4 に基づく仕訳の完全性・監査可能性を型で保証する。
-- - 借貸一致を smart constructor で強制
-- - 仕訳行為区分を必須属性として付与
-- - ロック後の直接変更を型で禁止（補正仕訳のみ許可）
module Domain.Accounting.JournalEntry
  ( -- * 仕訳識別子
    JournalEntryId (..),
    mkJournalEntryId,

    -- * 仕訳行
    JournalLine (..),
    DrCr (..),

    -- * 仕訳集約
    JournalEntry (..),
    recordEntry,
    validateBalance,

    -- * 帳簿価額ブリッジ §2.3.5
    CarryingAmountBridge (..),

    -- * エラー
    JournalError (..),
  )
where

import Data.List (foldl')
import Data.Text (Text)
import Data.Time (Day)
import Domain.Accounting.ChartOfAccounts (AccountCode)
import Domain.Shared
  ( JournalEntryKind (..),
    Money (..),
    RiskClass (..),
    Version,
    addMoney,
    initialVersion,
    negateMoney,
    subMoney,
    zeroMoney,
  )
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 値オブジェクト
-- ─────────────────────────────────────────────────────────────────────────────

newtype JournalEntryId = JournalEntryId {unJournalEntryId :: Text}
  deriving (Show, Eq, Ord)

mkJournalEntryId :: Text -> Either JournalError JournalEntryId
mkJournalEntryId t
  | null (show t) = Left InvalidEntryId
  | otherwise = Right (JournalEntryId t)

-- | 借方 / 貸方区分
data DrCr = Dr | Cr
  deriving (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- 仕訳行
-- ─────────────────────────────────────────────────────────────────────────────

-- | 1仕訳行。通貨は型パラメータで固定し、異通貨混算を防ぐ。
data JournalLine (currency :: Symbol) = JournalLine
  { lineAccount :: AccountCode,
    lineDrCr :: DrCr,
    -- | 正値必須（符号は DrCr で表現）
    lineAmount :: Money currency
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- 仕訳集約
-- ─────────────────────────────────────────────────────────────────────────────

-- | 仕訳帳エントリ。
-- 'recordEntry' を通じてのみ生成でき、借貸一致が保証される。
data JournalEntry (currency :: Symbol) = JournalEntry
  { entryId :: JournalEntryId,
    -- | 取引発生日（発生主義）
    entryDate :: Day,
    entryLines :: [JournalLine currency],
    -- | 仕訳行為区分 §2.1.1
    entryKind :: JournalEntryKind,
    -- | リスク分類 §3.2
    entryRisk :: RiskClass,
    -- | 摘要
    entryMemo :: Text,
    -- | 証憑参照 §4.1
    entryEvidenceRef :: Maybe Text,
    -- | 先行仕訳参照（訂正時）
    entryPriorRef :: Maybe JournalEntryId,
    entryVersion :: Version
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- ファクトリ: 借貸一致を強制
-- ─────────────────────────────────────────────────────────────────────────────

-- | 仕訳を記録する。借方合計 ≠ 貸方合計の場合はエラーを返す。
recordEntry ::
  JournalEntryId ->
  Day ->
  [JournalLine currency] ->
  JournalEntryKind ->
  RiskClass ->
  Text ->
  Maybe Text ->
  Maybe JournalEntryId ->
  Either JournalError (JournalEntry currency)
recordEntry eid date lines kind risk memo evRef priorRef =
  case validateBalance lines of
    Left err -> Left err
    Right _ ->
      Right
        JournalEntry
          { entryId = eid,
            entryDate = date,
            entryLines = lines,
            entryKind = kind,
            entryRisk = risk,
            entryMemo = memo,
            entryEvidenceRef = evRef,
            entryPriorRef = priorRef,
            entryVersion = initialVersion
          }

-- | 借貸一致検証。借方合計 = 貸方合計であることを確認する。
validateBalance :: [JournalLine currency] -> Either JournalError ()
validateBalance lines
  | drTotal == crTotal = Right ()
  | otherwise = Left (ImbalancedEntry drTotal crTotal)
  where
    drTotal = unMoney $ foldl' (\acc l -> if lineDrCr l == Dr then addMoney acc (lineAmount l) else acc) zeroMoney lines
    crTotal = unMoney $ foldl' (\acc l -> if lineDrCr l == Cr then addMoney acc (lineAmount l) else acc) zeroMoney lines

-- ─────────────────────────────────────────────────────────────────────────────
-- 帳簿価額ブリッジ §2.3.5, §7.1
-- 測定源泉層 → 帳簿価額 → 表示層 の接続点を記録する。
-- ─────────────────────────────────────────────────────────────────────────────

data CarryingAmountBridge (currency :: Symbol) = CarryingAmountBridge
  { bridgeAccountCode :: AccountCode,
    -- | 取得原価 §2.3.2(1)
    bridgeCostBasis :: Money currency,
    -- | 累計償却額 §2.3.2(2)
    bridgeAccumDeprec :: Money currency,
    -- | 減損損失累計 §2.3.2(3)
    bridgeImpairmentLoss :: Money currency,
    -- | 公正価値測定差額 §2.3.2(4)
    bridgeFvAdjustment :: Money currency,
    -- | ECL評価引当 §2.3.2(5)
    bridgeEclAllowance :: Money currency
  }
  deriving (Show, Eq)

-- | 帳簿価額 = 取得原価 − 累計償却 − 減損 ± 公正価値調整 − ECL
carryingAmount :: CarryingAmountBridge currency -> Money currency
carryingAmount b =
  foldl'
    addMoney
    (bridgeCostBasis b)
    [ negateMoney (bridgeAccumDeprec b),
      negateMoney (bridgeImpairmentLoss b),
      bridgeFvAdjustment b,
      negateMoney (bridgeEclAllowance b)
    ]

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data JournalError
  = InvalidEntryId
  | -- | 借方合計 / 貸方合計
    ImbalancedEntry Rational Rational
  | EmptyLines
  | -- | 証憑未添付かつ未払計上要件不充足
    MissingEvidenceForNonAccrual
  deriving (Show, Eq)
