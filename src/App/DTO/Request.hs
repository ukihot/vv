module App.DTO.Request
  ( ActivateUserRequest (..),
  )
where

import Data.Text (Text)

newtype ActivateUserRequest = ActivateUserRequest
  { rawUserId :: Text
  }
