module Application.User.DTOs.Response.ActivateUserResponse where

import Data.Text (Text)

-- | 出力データ。成功/失敗の結果とメッセージを返す
data ActivateUserResponse
  = ActivateUserSuccess Text
  | ActivateUserFailure Text
  deriving (Show, Eq)