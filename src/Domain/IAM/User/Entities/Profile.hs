module Domain.IAM.User.Entities.Profile (UserProfile (..)) where

import Domain.IAM.User.ValueObjects.Email (Email)
import Domain.IAM.User.ValueObjects.UserName (UserName)

-- 子エンティティ: ルート以外からは触らせない
data UserProfile = UserProfile
  { profileName :: UserName,
    profileEmail :: Email
  }
  deriving (Show, Eq)
