module Domain.Audit.ClosingProcess.ValueObjects.ClosingProcessId
    ( ClosingProcessId (..)
    , mkClosingProcessId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Audit.ClosingProcess.Errors (ClosingProcessError (..))

newtype ClosingProcessId = ClosingProcessId {unClosingProcessId :: Text}
    deriving (Show, Eq, Ord)

mkClosingProcessId :: Text -> Either ClosingProcessError ClosingProcessId
mkClosingProcessId t
    | T.null t = Left InvalidClosingProcessId
    | otherwise = Right (ClosingProcessId t)
