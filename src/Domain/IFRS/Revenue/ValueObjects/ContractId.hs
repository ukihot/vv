module Domain.IFRS.Revenue.ValueObjects.ContractId (
    ContractId (..),
    mkContractId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Revenue.Errors (RevenueError (..))

newtype ContractId = ContractId {unContractId :: Text}
    deriving (Show, Eq, Ord)

mkContractId :: Text -> Either RevenueError ContractId
mkContractId t
    | T.null t = Left InvalidContractId
    | otherwise = Right (ContractId t)
