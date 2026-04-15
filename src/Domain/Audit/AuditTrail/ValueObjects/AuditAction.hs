module Domain.Audit.AuditTrail.ValueObjects.AuditAction (
    AuditAction (..),
)
where

data AuditAction
    = Created
    | Updated
    | Deleted
    | Approved
    | Rejected
    | Locked
    | Unlocked
    deriving (Show, Eq, Ord, Enum, Bounded)
