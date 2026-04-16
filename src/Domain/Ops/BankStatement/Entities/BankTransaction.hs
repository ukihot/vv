module Domain.Ops.BankStatement.Entities.BankTransaction (
    BankTransaction (..),
    TransactionType (..),
)
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data TransactionType
    = Deposit
    | Withdrawal
    | Transfer
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data BankTransaction (currency :: Symbol) = BankTransaction
    { transactionDate :: Day
    , transactionType :: TransactionType
    , transactionAmount :: Money currency
    , transactionDescription :: Text
    , transactionReconciled :: Bool
    }
    deriving stock (Show, Eq)
