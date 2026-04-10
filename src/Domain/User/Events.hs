module Domain.User.Events (UserEventPayload (..)) where

import Domain.User.ValueObjects.Email (Email)
import Domain.User.ValueObjects.UserId (UserId)
import Domain.User.ValueObjects.UserName (UserName)

-- #23: 何が起きたかを具体的に定義
data UserEventPayload
  = UserRegistered UserId UserName Email
  | UserActivated UserId
  | UserEmailCorrected UserId Email
  deriving (Show)