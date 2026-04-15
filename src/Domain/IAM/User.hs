module Domain.IAM.User
  ( User (..),
    UserState (..),
    getUserId,
    getUserProfile,
    getUserVersion,
    activateUser,
    suspendUser,
    unsuspendUser,
    deactivateUser,
  )
where

import Domain.IAM.User.Entities.Profile (UserProfile)
import Domain.IAM.User.Events (UserEventPayload (..))
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))
import Domain.IAM.User.ValueObjects.Version (Version, nextVersion)

-- #3, #15: GADTによる状態機械の定義
-- 状態ごとに保持するデータ構造を強制する
data User (s :: UserState) where
  UserP :: UserId -> UserProfile -> Version -> User 'Pending
  UserA :: UserId -> UserProfile -> Version -> User 'Active
  UserS :: UserId -> UserProfile -> Version -> User 'Suspended
  UserI :: UserId -> UserProfile -> Version -> User 'Inactive

deriving instance Show (User s)

deriving instance Eq (User s)

-- --- 共通ゲッター ---

getUserId :: User s -> UserId
getUserId (UserP i _ _) = i
getUserId (UserA i _ _) = i
getUserId (UserS i _ _) = i
getUserId (UserI i _ _) = i

getUserProfile :: User s -> UserProfile
getUserProfile (UserP _ p _) = p
getUserProfile (UserA _ p _) = p
getUserProfile (UserS _ p _) = p
getUserProfile (UserI _ p _) = p

getUserVersion :: User s -> Version
getUserVersion (UserP _ _ v) = v
getUserVersion (UserA _ _ v) = v
getUserVersion (UserS _ _ v) = v
getUserVersion (UserI _ _ v) = v

-- --- 状態遷移 (Transitions) ---

-- | 承認：Pending からのみ可能
activateUser :: User 'Pending -> (User 'Active, UserEventPayload)
activateUser (UserP uid profile version) =
  let nextV = nextVersion version
   in (UserA uid profile nextV, UserActivated uid)

-- | 凍結：Active からのみ可能
suspendUser :: User 'Active -> (User 'Suspended, UserEventPayload)
suspendUser (UserA uid profile version) =
  let nextV = nextVersion version
   in (UserS uid profile nextV, UserSuspended uid)

-- | 凍結解除：Suspended から Active に戻す
unsuspendUser :: User 'Suspended -> (User 'Active, UserEventPayload)
unsuspendUser (UserS uid profile version) =
  let nextV = nextVersion version
   in (UserA uid profile nextV, UserUnsuspended uid)

-- | 無効化：Active または Suspended から可能
-- Pending は「承認前」なので、無効化ではなく「却下」や「削除」として別定義する
deactivateUser :: User s -> Either String (User 'Inactive, UserEventPayload)
deactivateUser user = case user of
  UserA uid profile v -> Right (UserI uid profile (nextVersion v), UserDeactivated uid)
  UserS uid profile v -> Right (UserI uid profile (nextVersion v), UserDeactivated uid)
  _ -> Left "Only Active or Suspended users can be deactivated."
