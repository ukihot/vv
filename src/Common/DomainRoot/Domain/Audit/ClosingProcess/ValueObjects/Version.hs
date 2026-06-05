-- | Domain.Shared.Version の再エクスポート。
module Domain.Audit.ClosingProcess.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
