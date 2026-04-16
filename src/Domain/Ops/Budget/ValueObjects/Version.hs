-- | Domain.Shared.Version の再エクスポート。
module Domain.Ops.Budget.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
