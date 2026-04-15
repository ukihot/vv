module App.Ports.Output.Transaction (
    RegisterJournalEntryOutputPort (..),
    JournalEntryListOutputPort (..),
    JournalEntryDetailOutputPort (..),
    CashLogListOutputPort (..),
    BankReconciliationOutputPort (..),
)
where

import App.DTO.Response.Transaction
import Data.Text (Text)

-- ============================================================================
-- Transaction Output Ports (画面ごとのプレゼンター)
-- ============================================================================

-- | 仕訳登録画面用OutputPort
class Monad m => RegisterJournalEntryOutputPort m where
    presentRegisterJournalEntrySuccess :: JournalEntryResponse -> m ()
    presentRegisterJournalEntryFailure :: Text -> m ()

-- | 仕訳一覧画面用OutputPort
class Monad m => JournalEntryListOutputPort m where
    presentJournalEntryList :: JournalEntryListResponse -> m ()
    presentJournalEntryListFailure :: Text -> m ()

-- | 仕訳詳細画面用OutputPort
class Monad m => JournalEntryDetailOutputPort m where
    presentJournalEntryDetail :: JournalEntryResponse -> m ()
    presentJournalEntryDetailFailure :: Text -> m ()

-- | キャッシュログ一覧画面用OutputPort
class Monad m => CashLogListOutputPort m where
    presentCashLogList :: [CashLogResponse] -> m ()
    presentCashLogListFailure :: Text -> m ()

-- | 銀行照合画面用OutputPort
class Monad m => BankReconciliationOutputPort m where
    presentBankReconciliation :: BankReconciliationResponse -> m ()
    presentBankReconciliationFailure :: Text -> m ()
