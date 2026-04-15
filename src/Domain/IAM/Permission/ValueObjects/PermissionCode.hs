module Domain.IAM.Permission.ValueObjects.PermissionCode
  ( PermissionCode,
    mkPermissionCode,
    unPermissionCode,
  )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.Permission.Errors (DomainError (InvalidPermissionCode))

newtype PermissionCode = PermissionCode {unPermissionCode :: Text}
  deriving stock (Show, Eq, Ord)

mkPermissionCode :: Text -> Either DomainError PermissionCode
mkPermissionCode raw
  | T.null raw || T.any (== ' ') raw = Left InvalidPermissionCode
  | otherwise = Right (PermissionCode raw)
