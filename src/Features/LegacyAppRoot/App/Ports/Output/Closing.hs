module App.Ports.Output.Closing (
    ClosingStatusOutputPort (..),
    TrialBalanceOutputPort (..),
    ClosingChecklistOutputPort (..),
    ClosingCalendarOutputPort (..),
    PeriodLockOutputPort (..),
)
where

import App.DTO.Response.Closing
import Data.Text (Text)

-- ============================================================================
-- Closing Output Ports (画面ごとのプレゼンター)
-- ============================================================================

-- | 締状況画面用OutputPort
class Monad m => ClosingStatusOutputPort m where
    presentClosingStatus :: ClosingStatusResponse -> m ()
    presentClosingStatusFailure :: Text -> m ()

-- | 試算表画面用OutputPort
class Monad m => TrialBalanceOutputPort m where
    presentTrialBalance :: TrialBalanceResponse -> m ()
    presentTrialBalanceFailure :: Text -> m ()

-- | 締チェックリスト画面用OutputPort
class Monad m => ClosingChecklistOutputPort m where
    presentClosingChecklist :: ClosingChecklistResponse -> m ()
    presentClosingChecklistFailure :: Text -> m ()

-- | クロージングカレンダー画面用OutputPort
class Monad m => ClosingCalendarOutputPort m where
    presentClosingCalendar :: ClosingCalendarResponse -> m ()
    presentClosingCalendarFailure :: Text -> m ()

-- | 期間ロック管理画面用OutputPort
class Monad m => PeriodLockOutputPort m where
    presentPeriodLock :: PeriodLockResponse -> m ()
    presentPeriodLockFailure :: Text -> m ()
