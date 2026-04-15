module Domain.IAM.Role.ValueObjects.RoleId (RoleId, mkRoleId, unRoleId) where

import Data.Text (Text)
import qualified Data.Text as T
import Domain.IAM.Role.Errors (DomainError (InvalidRoleId))

newtype RoleId = RoleId {unRoleId :: Text}
  deriving stock (Show, Eq, Ord)

mkRoleId :: Text -> Either DomainError RoleId
mkRoleId raw
  | T.null raw = Left InvalidRoleId
  | otherwise = Right (RoleId raw)
