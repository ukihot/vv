module Domain.IAM.Role.ValueObjects.RoleName (RoleName, mkRoleName, unRoleName) where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.Role.Errors (DomainError (InvalidRoleName))

newtype RoleName = RoleName {unRoleName :: Text}
  deriving stock (Show, Eq, Ord)

mkRoleName :: Text -> Either DomainError RoleName
mkRoleName raw
  | T.null raw || T.length raw > 100 = Left InvalidRoleName
  | otherwise = Right (RoleName raw)
