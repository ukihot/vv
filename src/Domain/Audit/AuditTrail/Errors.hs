module Domain.Audit.AuditTrail.Errors (
    AuditTrailError (..),
)
where

data AuditTrailError
    = InvalidAuditTrailId
    | InvalidEntityId
    deriving (Show, Eq)
