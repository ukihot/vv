{- | Domain.Shared.Version の再エクスポート。
IAM 集約は共通 Version 型を使用する (#11: 型の粒度統一)
-}
module Domain.IAM.User.ValueObjects.Version (
    Version (..),
    initialVersion,
    nextVersion,
)
where

import Domain.Shared (Version (..), initialVersion, nextVersion)
