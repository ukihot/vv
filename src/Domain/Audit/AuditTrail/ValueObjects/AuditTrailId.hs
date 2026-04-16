module Domain.Audit.AuditTrail.ValueObjects.AuditTrailId (
    AuditTrailId (..),
    mkAuditTrailId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Audit.AuditTrail.Errors (AuditTrailError (..))

newtype AuditTrailId = AuditTrailId {unAuditTrailId :: Text}
    deriving stock (Show, Eq, Ord)

mkAuditTrailId :: Text -> Either AuditTrailError AuditTrailId
mkAuditTrailId t
    | T.null t = Left InvalidAuditTrailId
    | otherwise = Right (AuditTrailId t)
