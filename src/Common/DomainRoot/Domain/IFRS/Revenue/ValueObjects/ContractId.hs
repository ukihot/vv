module Domain.IFRS.Revenue.ValueObjects.ContractId (
    ContractId,
    mkContractId,
    unContractId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Revenue.Errors (RevenueError (..))

newtype ContractId = ContractId {unContractId :: Text}
    deriving stock (Show, Eq, Ord)

mkContractId :: Text -> Either RevenueError ContractId
mkContractId t
    | T.null normalized = Left InvalidContractId
    | otherwise = Right (ContractId normalized)
    where
        normalized = T.strip t
