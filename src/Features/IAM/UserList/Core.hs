{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserList.Core (
    UserListState (..),
    UserListCommand (..),
    UserListEffect (..),
    Step (..),
    initialState,
    handleCommand,
) where

import App.DTO.Response.IAM (UserListResponse)
import Data.Text (Text)

data UserListState = UserListState
    { ulsUsers :: Maybe UserListResponse
    }
    deriving stock (Eq, Show)

data UserListCommand
    = RequestRefresh
    | UsersLoaded UserListResponse
    deriving stock (Eq, Show)

data UserListEffect
    = LoadUsers (Maybe Text) Int Int
    deriving stock (Eq, Show)

data Step s e = Step
    { stepState :: s
    , stepEffects :: [e]
    }
    deriving stock (Eq, Show)

initialState :: UserListState
initialState =
    UserListState
        { ulsUsers = Nothing
        }

handleCommand :: UserListCommand -> UserListState -> Step UserListState UserListEffect
handleCommand command state = case command of
    RequestRefresh -> Step state [LoadUsers Nothing 0 100]
    UsersLoaded response -> Step state {ulsUsers = Just response} []
