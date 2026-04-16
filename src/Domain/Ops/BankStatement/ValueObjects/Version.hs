-- | Domain.Shared.Version の再エクスポート。
module Domain.Ops.BankStatement.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
