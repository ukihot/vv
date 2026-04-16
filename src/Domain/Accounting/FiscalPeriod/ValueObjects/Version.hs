-- | Domain.Shared.Version の再エクスポート。
module Domain.Accounting.FiscalPeriod.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
