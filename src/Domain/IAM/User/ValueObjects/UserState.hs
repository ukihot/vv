module Domain.IAM.User.ValueObjects.UserState (UserState (..)) where

data UserState
    = Pending -- 承認待ち
    | Active -- 承認済み
    | Suspended -- 凍結（照会のみ）
    | Inactive -- 無効
    deriving (Show, Eq, Ord)
