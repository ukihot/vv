module Domain.Ops.BankStatement.ValueObjects.BankStatementId
    ( BankStatementId (..)
    , mkBankStatementId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.BankStatement.Errors (BankStatementError (..))

newtype BankStatementId = BankStatementId {unBankStatementId :: Text}
    deriving (Show, Eq, Ord)

mkBankStatementId :: Text -> Either BankStatementError BankStatementId
mkBankStatementId t
    | T.null t = Left InvalidStatementId
    | otherwise = Right (BankStatementId t)
