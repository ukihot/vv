module App.Ports.Output
  ( ActivateUserPort (..),
  )
where

import Domain.IAM.User (User)
import Domain.IAM.User.Errors (DomainError)
import Domain.IAM.User.ValueObjects.UserState (UserState (Active))

class (Monad m) => ActivateUserPort m where
  presentSuccess :: User 'Active -> m ()
  presentFailure :: DomainError -> m ()
