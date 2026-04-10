module Domain.IAM.User.ValueObjects.UserName (UserName, mkUserName, unUserName) where

import Data.Text (Text)
import qualified Data.Text as T
import Domain.IAM.User.Errors (DomainError (InvalidUserName))

newtype UserName = UserName {unUserName :: Text} deriving (Show, Eq)

mkUserName :: Text -> Either DomainError UserName
mkUserName t
  | T.null t || T.length t > 100 = Left InvalidUserName
  | otherwise = Right $ UserName t