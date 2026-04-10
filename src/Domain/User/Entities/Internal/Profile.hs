module Domain.User.Entities.Internal.Profile (UserProfile (..)) where

import Domain.User.ValueObjects.Email (Email)
import Domain.User.ValueObjects.UserName (UserName)

-- 子エンティティ: ルート以外からは触らせない
data UserProfile = UserProfile
  { profileName :: UserName,
    profileEmail :: Email
  }
  deriving (Show, Eq)