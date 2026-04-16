{- | 銀行明細集約ルートエンティティ
銀行取引明細を管理し、消込処理を追跡する。
-}
module Domain.Ops.BankStatement (
    -- * 集約
    BankStatement (..),

    -- * エンティティ
    module Domain.Ops.BankStatement.Entities.BankTransaction,

    -- * 値オブジェクト
    module Domain.Ops.BankStatement.ValueObjects.BankStatementId,
)
where

import Data.Time (Day)
import Domain.Ops.BankAccount.ValueObjects.BankAccountId (BankAccountId)
import Domain.Ops.BankStatement.Entities.BankTransaction
import Domain.Ops.BankStatement.ValueObjects.BankStatementId
import Domain.Ops.BankStatement.ValueObjects.Version (Version)
import GHC.TypeLits (Symbol)

data BankStatement (currency :: Symbol) = BankStatement
    { bankStatementId :: BankStatementId
    , bankStatementAccountId :: BankAccountId
    , bankStatementDate :: Day
    , bankStatementTransactions :: [BankTransaction currency]
    , bankStatementVersion :: Version
    }
    deriving stock (Show, Eq)
