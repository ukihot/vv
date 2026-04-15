module Domain.IFRS.Provision.ValueObjects.Version
    ( Version (..)
    , initialVersion
    , nextVersion
    )
where

newtype Version = Version {unVersion :: Int}
    deriving (Show, Eq, Ord)

initialVersion :: Version
initialVersion = Version 0

nextVersion :: Version -> Version
nextVersion (Version n) = Version (n + 1)
