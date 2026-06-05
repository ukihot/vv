-- | Domain.Shared.Version の再エクスポート。
module Domain.Audit.AuditTrail.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
