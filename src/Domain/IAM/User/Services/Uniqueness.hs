module Domain.IAM.User.Services.Uniqueness (DuplicateChecker, validateUniqueEmail) where

import Domain.IAM.User.Errors (DomainError (DuplicateEmail))
import Domain.IAM.User.ValueObjects.Email (Email)

-- #33: Portとして定義し、Application層から注入可能にする
type DuplicateChecker m = Email -> m Bool

validateUniqueEmail :: (Monad m) => DuplicateChecker m -> Email -> m (Either DomainError ())
validateUniqueEmail check email = do
  exists <- check email
  pure $ if exists then Left DuplicateEmail else Right ()