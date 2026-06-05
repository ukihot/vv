-- | Domain.Shared.Version の再エクスポート。
module Domain.Ops.BankAccount.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
