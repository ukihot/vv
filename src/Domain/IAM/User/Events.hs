module Domain.IAM.User.Events (UserEventPayload (..)) where

import Domain.IAM.User.ValueObjects.Email (Email)
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.IAM.User.ValueObjects.UserName (UserName)

-- #23: イベントは業務の事実に対応させる。
data UserEventPayload
  = UserRegistered UserId UserName Email
  | UserActivated UserId
  | UserSuspended UserId
  | UserUnsuspended UserId
  | UserDeactivated UserId
  | UserEmailCorrected UserId Email
  | UserNameCorrected UserId UserName
  deriving (Show, Eq)