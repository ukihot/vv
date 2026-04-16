{- | 仕訳帳集約ルートエンティティ
借貸一致を smart constructor で強制し、
仕訳行為区分を必須属性として付与する。
-}
module Domain.Accounting.JournalEntry (
    -- * 集約
    JournalEntry (..),
    recordEntry,

    -- * エラー
    JournalError (..),

    -- * エンティティ
    module Domain.Accounting.JournalEntry.Entities.JournalLine,
    module Domain.Accounting.JournalEntry.Entities.CarryingAmountBridge,

    -- * 値オブジェクト
    module Domain.Accounting.JournalEntry.ValueObjects.JournalEntryId,
    module Domain.Accounting.JournalEntry.ValueObjects.DrCr,

    -- * サービス
    validateBalance,
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Accounting.JournalEntry.Entities.CarryingAmountBridge
import Domain.Accounting.JournalEntry.Entities.JournalLine
import Domain.Accounting.JournalEntry.Errors (JournalError (..))
import Domain.Accounting.JournalEntry.Services.Validation (validateBalance)
import Domain.Accounting.JournalEntry.ValueObjects.DrCr
import Domain.Accounting.JournalEntry.ValueObjects.JournalEntryId
import Domain.Accounting.JournalEntry.ValueObjects.Version (Version, initialVersion)
import Domain.Shared (JournalEntryKind, RiskClass)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 仕訳集約
-- ─────────────────────────────────────────────────────────────────────────────

data JournalEntry (currency :: Symbol) = JournalEntry
    { entryId :: JournalEntryId
    , entryDate :: Day
    , entryLines :: [JournalLine currency]
    , entryKind :: JournalEntryKind
    , entryRisk :: RiskClass
    , entryMemo :: Text
    , entryEvidenceRef :: Maybe Text
    , entryPriorRef :: Maybe JournalEntryId
    , entryVersion :: Version
    }
    deriving stock (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- ファクトリ
-- ─────────────────────────────────────────────────────────────────────────────

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
                    { entryId = eid
                    , entryDate = date
                    , entryLines = lines
                    , entryKind = kind
                    , entryRisk = risk
                    , entryMemo = memo
                    , entryEvidenceRef = evRef
                    , entryPriorRef = priorRef
                    , entryVersion = initialVersion
                    }
