-- | Domain.Shared.Version の再エクスポート。
module Domain.IFRS.FixedAsset.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
