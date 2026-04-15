module Domain.Audit.AuditTrail.Repository
    ( AuditTrailRepository (..)
    )
where

import Data.Text (Text)
import Data.Time (UTCTime)
import Domain.Audit.AuditTrail (AuditTrail)
import Domain.Audit.AuditTrail.ValueObjects.AuditTrailId (AuditTrailId)

class Monad m => AuditTrailRepository m where
    saveAuditTrail :: AuditTrail -> m ()
    findAuditTrailById :: AuditTrailId -> m (Maybe AuditTrail)
    findAuditTrailsByEntity :: Text -> m [AuditTrail]
    findAuditTrailsByTimeRange :: UTCTime -> UTCTime -> m [AuditTrail]
