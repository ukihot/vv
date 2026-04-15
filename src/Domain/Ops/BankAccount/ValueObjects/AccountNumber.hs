module Domain.Ops.BankAccount.ValueObjects.AccountNumber
    ( AccountNumber (..)
    , mkAccountNumber
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.BankAccount.Errors (BankAccountError (..))

newtype AccountNumber = AccountNumber {unAccountNumber :: Text}
    deriving (Show, Eq, Ord)

mkAccountNumber :: Text -> Either BankAccountError AccountNumber
mkAccountNumber t
    | T.null t = Left InvalidAccountNumber
    | otherwise = Right (AccountNumber t)
