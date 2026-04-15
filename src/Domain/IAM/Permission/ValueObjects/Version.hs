module Domain.IAM.Permission.ValueObjects.Version
  ( Version (..),
    initialVersion,
    nextVersion,
  )
where

newtype Version = Version {unVersion :: Int}
  deriving stock (Show, Eq, Ord)

initialVersion :: Version
initialVersion = Version 0

nextVersion :: Version -> Version
nextVersion (Version value) = Version (value + 1)
