module Domain.Ops.BankAccount.ValueObjects.BankCode (
    BankCode (..),
    mkBankCode,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.BankAccount.Errors (BankAccountError (..))

newtype BankCode = BankCode {unBankCode :: Text}
    deriving stock (Show, Eq, Ord)

mkBankCode :: Text -> Either BankAccountError BankCode
mkBankCode t
    | T.null t = Left InvalidBankCode
    | otherwise = Right (BankCode t)
