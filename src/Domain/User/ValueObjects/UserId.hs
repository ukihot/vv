module Domain.User.ValueObjects.UserId (UserId, mkUserId, unUserId) where

import Data.Text (Text)
import qualified Data.Text as T
import Domain.User.Errors (DomainError (InvalidUserId))

newtype UserId = UserId {unUserId :: Text} deriving (Show, Eq, Ord)

mkUserId :: Text -> Either DomainError UserId
mkUserId t
  | T.null t = Left InvalidUserId
  | otherwise = Right $ UserId t