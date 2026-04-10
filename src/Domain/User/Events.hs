module Domain.User.Events (UserEventPayload (..)) where

import Domain.User.ValueObjects.Email (Email)
import Domain.User.ValueObjects.UserId (UserId)
import Domain.User.ValueObjects.UserName (UserName)

-- #23: イベントは業務の事実に対応させる。
data UserEventPayload
  = UserRegistered UserId UserName Email
  | UserActivated UserId
  | UserSuspended UserId   | UserUnsuspended UserId
  | UserDeactivated UserId
  | UserEmailCorrected UserId Email
  | UserNameCorrected UserId UserName
  deriving (Show, Eq)