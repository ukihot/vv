module Domain.Audit.AuditTrail.Events
    ( AuditTrailEventPayload (..)
    )
where

import Data.Text (Text)
import Data.Time (UTCTime)
import Domain.Audit.AuditTrail.ValueObjects.AuditAction (AuditAction)
import Domain.Audit.AuditTrail.ValueObjects.AuditTrailId (AuditTrailId)

data AuditTrailEventPayload
    = AuditTrailRecorded AuditTrailId Text AuditAction UTCTime
    deriving (Show, Eq)
