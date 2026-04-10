module Application.User.DTOs.Request.ActivateUserRequest where

import Data.Text (Text)

-- | 入力データ。Domain層に依存しないプリミティブな構成
data ActivateUserRequest = ActivateUserRequest
  { targetUserId :: Text
  }
  deriving (Show, Eq)