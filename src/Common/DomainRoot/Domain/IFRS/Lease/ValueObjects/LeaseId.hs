module Domain.IFRS.Lease.ValueObjects.LeaseId (
    LeaseId,
    mkLeaseId,
    unLeaseId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Lease.Errors (LeaseError (..))

newtype LeaseId = LeaseId {unLeaseId :: Text}
    deriving stock (Show, Eq, Ord)

mkLeaseId :: Text -> Either LeaseError LeaseId
mkLeaseId t
    | T.null normalized = Left InvalidLeaseId
    | otherwise = Right (LeaseId normalized)
    where
        normalized = T.strip t
