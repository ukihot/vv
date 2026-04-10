module Domain.User.Entities.Root (User (..), UserState (..), getUserId, getUserProfile, activateUser) where
import Domain.User.Events (UserEventPayload (..))
import Domain.User.Entities.Internal.Profile (UserProfile)
import Domain.User.ValueObjects.UserId (UserId)
import Domain.User.ValueObjects.Version (Version(..), nextVersion)

data UserState = Pending | Active | Inactive

-- #3, #4: GADTによる状態機械の静的定義
data User (s :: UserState) where
  UserP :: UserId -> UserProfile -> Version -> User 'Pending
  UserA :: UserId -> UserProfile -> Version -> User 'Active
  UserD :: UserId -> UserProfile -> Version -> User 'Inactive

deriving instance Show (User s)
deriving instance Eq (User s)

getUserId :: User s -> UserId
getUserId (UserP i _ _) = i
getUserId (UserA i _ _) = i
getUserId (UserD i _ _) = i

getUserProfile :: User s -> UserProfile
getUserProfile (UserP _ p _) = p
getUserProfile (UserA _ p _) = p
getUserProfile (UserD _ p _) = p

activateUser :: User 'Pending -> (User 'Active, UserEventPayload)
activateUser (UserP uid profile version) =
  let nextV = nextVersion version
      newUser = UserA uid profile nextV
      event = UserActivated uid
   in (newUser, event)