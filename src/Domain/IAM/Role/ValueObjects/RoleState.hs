module Domain.IAM.Role.ValueObjects.RoleState (RoleState (..)) where

data RoleState
  = Draft
  | Active
  | Inactive
  deriving stock (Show, Eq, Ord)
