{- | 会計期間管理
月次決算の締め状態を型レベルで表現し、
ロック後の直接変更をコンパイル時に排除する。
-}
module Domain.Accounting.FiscalPeriod
    ( -- * 期間状態
      PeriodState (..)

      -- * 会計期間集約
    , FiscalPeriod (..)
    , FiscalPeriodId (..)
    , mkFiscalPeriodId
    , openPeriod
    , lockPeriod
    , reopenPeriod

      -- * イベント
    , FiscalPeriodEvent (..)

      -- * エラー
    , PeriodError (..)
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Shared (FiscalYearMonth (..), Version, initialVersion, nextVersion)

-- ─────────────────────────────────────────────────────────────────────────────
-- 期間状態
-- ─────────────────────────────────────────────────────────────────────────────

data PeriodState
    = -- | 入力受付中
      Open
    | -- | 締日固定済み (§4.4): 通常入力禁止、補正仕訳のみ許可
      Locked
    deriving (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- 値オブジェクト
-- ─────────────────────────────────────────────────────────────────────────────

newtype FiscalPeriodId = FiscalPeriodId {unFiscalPeriodId :: Text}
    deriving (Show, Eq, Ord)

mkFiscalPeriodId :: Text -> Either PeriodError FiscalPeriodId
mkFiscalPeriodId t
    | T.null t = Left InvalidPeriodId
    | otherwise = Right (FiscalPeriodId t)

-- ─────────────────────────────────────────────────────────────────────────────
-- 集約 (GADT 状態機械)
-- ─────────────────────────────────────────────────────────────────────────────

data FiscalPeriod (s :: PeriodState) where
    FPOpen :: FiscalPeriodId -> FiscalYearMonth -> Version -> FiscalPeriod 'Open
    FPLocked :: FiscalPeriodId -> FiscalYearMonth -> Version -> FiscalPeriod 'Locked

deriving instance Show (FiscalPeriod s)

deriving instance Eq (FiscalPeriod s)

-- ─────────────────────────────────────────────────────────────────────────────
-- ファクトリ
-- ─────────────────────────────────────────────────────────────────────────────

openPeriod :: FiscalPeriodId -> FiscalYearMonth -> (FiscalPeriod 'Open, FiscalPeriodEvent)
openPeriod pid ym =
    ( FPOpen pid ym initialVersion,
      PeriodOpened pid ym
    )

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

-- | 締日固定 §4.4: Open → Locked
lockPeriod :: FiscalPeriod 'Open -> (FiscalPeriod 'Locked, FiscalPeriodEvent)
lockPeriod (FPOpen pid ym v) =
    ( FPLocked pid ym (nextVersion v),
      PeriodLocked pid ym
    )

-- | 再開 (CFO承認後の例外的再オープン)
reopenPeriod :: FiscalPeriod 'Locked -> (FiscalPeriod 'Open, FiscalPeriodEvent)
reopenPeriod (FPLocked pid ym v) =
    ( FPOpen pid ym (nextVersion v),
      PeriodReopened pid ym
    )

-- ─────────────────────────────────────────────────────────────────────────────
-- イベント
-- ─────────────────────────────────────────────────────────────────────────────

data FiscalPeriodEvent
    = PeriodOpened FiscalPeriodId FiscalYearMonth
    | PeriodLocked FiscalPeriodId FiscalYearMonth
    | PeriodReopened FiscalPeriodId FiscalYearMonth
    deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data PeriodError
    = InvalidPeriodId
    | PeriodAlreadyLocked
    | PeriodNotLocked
    deriving (Show, Eq)
