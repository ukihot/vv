{-# LANGUAGE ImportQualifiedPost #-}

module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (
    AccountCode (..),
    mkAccountCode,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Accounting.ChartOfAccounts.Errors (ChartError (..))

newtype AccountCode = AccountCode {unAccountCode :: Text}
    deriving stock (Show, Eq, Ord)

mkAccountCode :: Text -> Either ChartError AccountCode
mkAccountCode t
    | T.null t = Left EmptyAccountCode
    | otherwise = Right (AccountCode t)
