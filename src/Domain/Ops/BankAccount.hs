{- | 銀行口座集約ルートエンティティ
銀行口座情報を管理する。
-}
module Domain.Ops.BankAccount (
    -- * 集約
    BankAccount (..),

    -- * 値オブジェクト
    module Domain.Ops.BankAccount.ValueObjects.BankAccountId,
    module Domain.Ops.BankAccount.ValueObjects.AccountNumber,
    module Domain.Ops.BankAccount.ValueObjects.BankCode,
)
where

import Data.Text (Text)
import Domain.Ops.BankAccount.ValueObjects.AccountNumber
import Domain.Ops.BankAccount.ValueObjects.BankAccountId
import Domain.Ops.BankAccount.ValueObjects.BankCode
import Domain.Ops.BankAccount.ValueObjects.Version (Version, initialVersion)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data BankAccount (currency :: Symbol) = BankAccount
    { bankAccountId :: BankAccountId
    , bankAccountNumber :: AccountNumber
    , bankAccountBankCode :: BankCode
    , bankAccountBankName :: Text
    , bankAccountBranchName :: Text
    , bankAccountHolderName :: Text
    , bankAccountBalance :: Money currency
    , bankAccountVersion :: Version
    }
    deriving stock (Show, Eq)
