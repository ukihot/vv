module Application.User.Boundary.Output.ActivateUserPort where

import Domain.User.Entities.Root (User, UserState (..))
import Domain.User.Errors (DomainError)

-- | #14: ユースケース単位の Output Port
-- Interactor はこのポートに処理の「評価」を委ねる
class (Monad m) => ActivateUserPort m where
  -- | 成功時の提示
  presentSuccess :: User 'Active -> m ()

  -- | 失敗時の提示
  presentFailure :: DomainError -> m ()