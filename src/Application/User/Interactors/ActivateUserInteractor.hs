module Application.User.Interactors.ActivateUserInteractor where

import Application.User.Boundary.Input.ActivateUserUseCase
import Application.User.Boundary.Output.ActivateUserPort (ActivateUserPort (..))
import Application.User.DTOs.Request.ActivateUserRequest (ActivateUserRequest (..))
import Control.Monad.Except (ExceptT (..), runExceptT)
import Domain.User.Entities.Root (activateUser)
import Domain.User.Errors (DomainError (..))
import Domain.User.Repository (UserRepository (..))
import Domain.User.ValueObjects.UserId (mkUserId)

instance (Monad m, UserRepository m, ActivateUserPort m) => ActivateUserUseCase m where
  execute req =
    -- 処理の結果（Either）を Port に「委ねる」処理を末尾に配置
    either presentFailure presentSuccess =<< runExceptT pipeline
    where
      pipeline = do
        -- UserIdのバリデーション（純粋なEitherをExceptTに持ち上げる）
        uid <- ExceptT . pure $ mkUserId (targetUserId req)

        -- 集約の復元（m (Either DomainError (User s)) をそのまま合成）
        pendingUser <- ExceptT $ loadUser uid

        -- ビジネスロジックの実行
        let (activeUser, _event) = activateUser pendingUser

        -- 永続化
        ExceptT $ saveUser activeUser

        -- 成功時の戻り値
        pure activeUser