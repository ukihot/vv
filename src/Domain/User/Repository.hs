module Domain.User.Repository where

import Domain.User.Entities.Root (User)
import Domain.User.Errors (DomainError)
import Domain.User.ValueObjects.UserId (UserId)

-- | #14, #16: 集約の復元と保存のみを責務とするリポジトリ
-- CQRSにより、検索系（Query）はここに含まない
class (Monad m) => UserRepository m where
  -- | 特定の状態(s)を指定して集約をロードする
  -- #4: 有効化コマンドなら 'Pending' を、修正コマンドなら 'Active' を、
  -- 呼び出し側のコンテキストが求める「状態」を型安全に復元する
  loadUser :: forall s. UserId -> m (Either DomainError (User s))

  -- | 変更された集約の状態を永続化する
  -- 状態(s)に関わらず、保存の責務を果たす
  saveUser :: User s -> m (Either DomainError ())