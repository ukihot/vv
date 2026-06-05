module App.Ports.Command.Ledger (
    AggregateToGeneralLedgerUseCase (..),
    AggregateToSubsidiaryLedgerUseCase (..),
    ReconcileLedgersUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Ledger Aggregation (元帳集約)
-- ============================================================================

class Monad m => AggregateToGeneralLedgerUseCase m where
    executeAggregateToGeneralLedger :: Day -> Day -> m (Either Text ()) -- fromDate, toDate

class Monad m => AggregateToSubsidiaryLedgerUseCase m where
    executeAggregateToSubsidiaryLedger :: Text -> Day -> Day -> m (Either Text ())

-- accountId, fromDate, toDate

class Monad m => ReconcileLedgersUseCase m where
    executeReconcileLedgers :: Text -> Day -> m (Either Text [(Text, Double)])

-- accountId, date -> differences
