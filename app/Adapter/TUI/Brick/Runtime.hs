module Adapter.TUI.Brick.Runtime
    ( BackendState (..)
    , BackendM
    , StoredUser (..)
    , bootstrapState
    , runActivateUser
    )
where

import App.DTO.Request (ActivateUserRequest (..))
import App.Ports.Output (ActivateUserPort (..))
import App.UseCase.IAM (executeActivateUser)
import Control.Monad.State (MonadIO, MonadState, StateT, get, modify, runStateT)
import Data.Map qualified as M
import Data.Text (Text)
import Data.Text qualified as T
import Domain.IAM.User (User (..), getUserId)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Repository (UserRepository (..))
import Domain.IAM.User.Services.Factory (registerUser)
import Domain.IAM.User.ValueObjects.Email (mkEmail)
import Domain.IAM.User.ValueObjects.UserId (mkUserId, unUserId)
import Domain.IAM.User.ValueObjects.UserName (mkUserName)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))
import Unsafe.Coerce (unsafeCoerce)

data StoredUser
    = StoredPending (User 'Pending)
    | StoredActive (User 'Active)
    | StoredSuspended (User 'Suspended)
    | StoredInactive (User 'Inactive)

data BackendState = BackendState
    { users :: M.Map Text StoredUser,
      logs :: [Text]
    }

toStoredUser :: User s -> StoredUser
toStoredUser (UserP uid prof ver) = StoredPending (UserP uid prof ver)
toStoredUser (UserA uid prof ver) = StoredActive (UserA uid prof ver)
toStoredUser (UserS uid prof ver) = StoredSuspended (UserS uid prof ver)
toStoredUser (UserI uid prof ver) = StoredInactive (UserI uid prof ver)

newtype BackendM a = BackendM {unBackendM :: StateT BackendState IO a}
    deriving newtype (Functor, Applicative, Monad, MonadState BackendState, MonadIO)

instance UserRepository BackendM where
    loadUser uid = do
        st <- get
        pure $ case M.lookup (unUserId uid) (users st) of
            Just (StoredPending user) -> Right (unsafeCoerce user)
            Just (StoredActive _) -> Left AlreadyActivated
            Just (StoredSuspended _) -> Left IllegalTransition
            Just (StoredInactive _) -> Left UserIsInactive
            Nothing -> Left (RepositoryError ("User not found: " <> T.unpack (unUserId uid)))

    saveUser user = do
        modify $ \st ->
            st
                { users = M.insert (unUserId (getUserId user)) (toStoredUser user) (users st)
                }
        pure (Right ())

instance ActivateUserPort BackendM where
    presentSuccess user =
        appendLog ("[OK] Activated user: " <> unUserId (getUserId user))

    presentFailure err =
        appendLog ("[ERROR] " <> formatDomainError err)

appendLog :: Text -> BackendM ()
appendLog entry = modify $ \st -> st {logs = logs st <> [entry]}

formatDomainError :: DomainError -> Text
formatDomainError = \case
    InvalidUserId -> "User ID is invalid."
    InvalidUserName -> "User name is invalid."
    InvalidEmail -> "Email is invalid."
    DuplicateEmail -> "Email already exists."
    IllegalTransition -> "This user cannot be activated from the current state."
    AlreadyActivated -> "This user is already active."
    UserIsInactive -> "This user is inactive."
    RepositoryError msg -> "Repository error: " <> T.pack msg

bootstrapState :: Either DomainError BackendState
bootstrapState = do
    uid <- mkUserId "user-777"
    name <- mkUserName "Gemini CEO"
    email <- mkEmail "ceo@example.com"
    let (user, _) = registerUser uid name email
    pure $
        BackendState
            { users = M.fromList [(unUserId uid, StoredPending user)],
              logs =
                [ "Ready. Enter a user id and press Enter.",
                  "Seeded pending user: user-777"
                ]
            }

runActivateUser :: BackendState -> Text -> IO BackendState
runActivateUser st rawUserId = do
    (_, nextState) <-
        runStateT
            (unBackendM (executeActivateUser (ActivateUserRequest rawUserId)))
            st
    pure nextState
