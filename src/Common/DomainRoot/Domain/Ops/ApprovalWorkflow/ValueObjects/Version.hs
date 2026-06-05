-- | Domain.Shared.Version の再エクスポート。
module Domain.Ops.ApprovalWorkflow.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
