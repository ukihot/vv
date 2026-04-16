module Domain.IAM.User.ValueObjects.UserState (UserState (..), userStateToText) where

import Data.Text (Text)

data UserState
    = Pending -- 承認待ち
    | Active -- 承認済み
    | Suspended -- 凍結（照会のみ）
    | Inactive -- 無効
    deriving (Show, Eq, Ord)

-- | 状態の正規文字列表現。DTO や表示層はこれを使う。
userStateToText :: UserState -> Text
userStateToText Pending = "pending"
userStateToText Active = "active"
userStateToText Suspended = "suspended"
userStateToText Inactive = "inactive"
