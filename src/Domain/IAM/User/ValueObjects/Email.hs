module Domain.IAM.User.ValueObjects.Email (Email, mkEmail, unEmail) where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.User.Errors (DomainError (InvalidEmail))

newtype Email = Email {unEmail :: Text} deriving stock (Show, Eq)

mkEmail :: Text -> Either DomainError Email
mkEmail t
    | "@" `T.isInfixOf` t = Right $ Email t
    | otherwise = Left InvalidEmail
