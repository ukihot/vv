module Application.User.Queries.UserQueryPort where

import Data.Text (Text)

-- | 参照専用のDTO。集約(Entity)とは切り離された「見せるため」の構造
data UserReadModel = UserReadModel
  { userId :: Text,
    userName :: Text,
    userEmail :: Text,
    status :: Text
  }

class (Monad m) => UserQueryPort m where
  -- | IDによる単一参照。DBから直接 ReadModel を取得する
  fetchUserById :: Text -> m (Maybe UserReadModel)

  -- | 全件取得などのクエリ
  fetchAllUsers :: m [UserReadModel]