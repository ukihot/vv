{- | ユーザーリポジトリの型定義
Handle パターン (#45, #46) で依存を値として渡す。
型クラス DI を使わない。
-}
module Domain.IAM.User.Repository (UserHandle (..)) where

import Domain.IAM.User (User)
import Domain.IAM.User.Errors (DomainError)
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.ValueObjects.UserId (UserId)

{- | ユーザー集約の永続化ハンドル
CQRSにより、検索系（findBy 等）は一切持たない。
load / save / appendEvent のみ。
-}
data UserHandle m = UserHandle
    { loadUser :: forall s. UserId -> m (Either DomainError (User s))
    , saveUser :: forall s. User s -> m (Either DomainError ())
    , appendUserEvent :: UserId -> UserEventPayload -> m (Either DomainError ())
    }
