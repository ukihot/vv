module App.Ports.Output.Ledger (
    GeneralLedgerOutputPort (..),
    SubsidiaryLedgerOutputPort (..),
    AccountBalanceOutputPort (..),
    LedgerReconciliationOutputPort (..),
)
where

import App.DTO.Response.Ledger
import Data.Text (Text)

-- ============================================================================
-- Ledger Output Ports (画面ごとのプレゼンター)
-- ============================================================================

-- | 総勘定元帳画面用OutputPort
class Monad m => GeneralLedgerOutputPort m where
    presentGeneralLedger :: GeneralLedgerResponse -> m ()
    presentGeneralLedgerFailure :: Text -> m ()

-- | 補助元帳画面用OutputPort
class Monad m => SubsidiaryLedgerOutputPort m where
    presentSubsidiaryLedger :: SubsidiaryLedgerResponse -> m ()
    presentSubsidiaryLedgerFailure :: Text -> m ()

-- | 勘定残高照会画面用OutputPort
class Monad m => AccountBalanceOutputPort m where
    presentAccountBalance :: AccountBalanceResponse -> m ()
    presentAccountBalanceFailure :: Text -> m ()

-- | 元帳照合画面用OutputPort
class Monad m => LedgerReconciliationOutputPort m where
    presentLedgerReconciliation :: ReconciliationResponse -> m ()
    presentLedgerReconciliationFailure :: Text -> m ()
