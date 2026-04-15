module Domain.Ops.BankAccount.ValueObjects.BankAccountId (
    BankAccountId (..),
    mkBankAccountId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.BankAccount.Errors (BankAccountError (..))

newtype BankAccountId = BankAccountId {unBankAccountId :: Text}
    deriving (Show, Eq, Ord)

mkBankAccountId :: Text -> Either BankAccountError BankAccountId
mkBankAccountId t
    | T.null t = Left InvalidBankAccountId
    | otherwise = Right (BankAccountId t)
