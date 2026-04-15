module Domain.IAM.Permission.ValueObjects.PermissionName (
    PermissionName,
    mkPermissionName,
    unPermissionName,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.Permission.Errors (DomainError (InvalidPermissionName))

newtype PermissionName = PermissionName {unPermissionName :: Text}
    deriving stock (Show, Eq, Ord)

mkPermissionName :: Text -> Either DomainError PermissionName
mkPermissionName raw
    | T.null raw || T.length raw > 100 = Left InvalidPermissionName
    | otherwise = Right (PermissionName raw)
