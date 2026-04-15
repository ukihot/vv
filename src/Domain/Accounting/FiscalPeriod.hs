{- | 会計期間管理集約ルートエンティティ
月次決算の締め状態を型レベルで表現し、
ロック後の直接変更をコンパイル時に排除する。
-}
module Domain.Accounting.FiscalPeriod
    ( -- * 集約
      FiscalPeriod (..)
    , PeriodState (..)
    , SomeFiscalPeriod (..)

      -- * 値オブジェクト
    , module Domain.Accounting.FiscalPeriod.ValueObjects.FiscalPeriodId

      -- * 状態遷移
    , openPeriod
    , lockPeriod
    , reopenPeriod
    )
where

import Domain.Accounting.FiscalPeriod.Events (FiscalPeriodEvent (..))
import Domain.Accounting.FiscalPeriod.ValueObjects.FiscalPeriodId
import Domain.Accounting.FiscalPeriod.ValueObjects.PeriodState (PeriodState (..))
import Domain.Accounting.FiscalPeriod.ValueObjects.Version (Version, initialVersion, nextVersion)
import Domain.Shared (FiscalYearMonth)

-- ─────────────────────────────────────────────────────────────────────────────
-- 集約 GADT
-- ─────────────────────────────────────────────────────────────────────────────

data FiscalPeriod (s :: PeriodState) where
    FPOpen :: FiscalPeriodId -> FiscalYearMonth -> Version -> FiscalPeriod 'Open
    FPLocked :: FiscalPeriodId -> FiscalYearMonth -> Version -> FiscalPeriod 'Locked

deriving instance Show (FiscalPeriod s)
deriving instance Eq (FiscalPeriod s)

data SomeFiscalPeriod where
    SomeFP :: FiscalPeriod s -> SomeFiscalPeriod

deriving instance Show SomeFiscalPeriod

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

openPeriod :: FiscalPeriodId -> FiscalYearMonth -> (FiscalPeriod 'Open, FiscalPeriodEvent)
openPeriod pid ym =
    ( FPOpen pid ym initialVersion,
      PeriodOpened pid ym
    )

lockPeriod :: FiscalPeriod 'Open -> (FiscalPeriod 'Locked, FiscalPeriodEvent)
lockPeriod (FPOpen pid ym v) =
    ( FPLocked pid ym (nextVersion v),
      PeriodLocked pid ym
    )

reopenPeriod :: FiscalPeriod 'Locked -> (FiscalPeriod 'Open, FiscalPeriodEvent)
reopenPeriod (FPLocked pid ym v) =
    ( FPOpen pid ym (nextVersion v),
      PeriodReopened pid ym
    )
