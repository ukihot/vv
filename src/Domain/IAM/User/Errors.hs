module Domain.IAM.User.Errors (DomainError (..)) where

data DomainError
  = InvalidUserId
  | InvalidUserName
  | InvalidEmail
  | DuplicateEmail
  | IllegalTransition -- #13, #14: 不正な状態遷移
  | AlreadyActivated
  | UserIsInactive -- #3: 無効化済みユーザーへの操作拒否
  | RepositoryError String
  deriving (Show, Eq)