module Domain.IAM.Permission.ValueObjects.PermissionId
  ( PermissionId,
    mkPermissionId,
    unPermissionId,
  )
where

import Data.Text (Text)
import qualified Data.Text as T
import Domain.IAM.Permission.Errors (DomainError (InvalidPermissionId))

newtype PermissionId = PermissionId {unPermissionId :: Text}
  deriving stock (Show, Eq, Ord)

mkPermissionId :: Text -> Either DomainError PermissionId
mkPermissionId raw
  | T.null raw = Left InvalidPermissionId
  | otherwise = Right (PermissionId raw)
