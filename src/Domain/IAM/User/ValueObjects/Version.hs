module Domain.IAM.User.ValueObjects.Version
  ( Version (..),
    initialVersion,
    nextVersion,
  )
where

-- #1, #11: ゼロコストの newtype で型を分離
-- #51, #52: 比較が必要なため Eq, Ord を派生
newtype Version = Version {unVersion :: Int}
  deriving (Show, Eq, Ord)

-- | 最初のイベントのための初期値
initialVersion :: Version
initialVersion = Version 0

-- | バージョンを一つ進める
-- Event Sourcing において、新しい事実を積むたびにインクリメントされる
nextVersion :: Version -> Version
nextVersion (Version v) = Version (v + 1)
