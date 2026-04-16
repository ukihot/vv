-- | Domain.Shared.Version の再エクスポート。
module Domain.Org.Organization.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
