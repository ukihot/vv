module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountName
    ( AccountName (..)
    , mkAccountName
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Accounting.ChartOfAccounts.Errors (ChartError (..))

newtype AccountName = AccountName {unAccountName :: Text}
    deriving (Show, Eq, Ord)

mkAccountName :: Text -> Either ChartError AccountName
mkAccountName t
    | T.null t = Left EmptyAccountName
    | otherwise = Right (AccountName t)
