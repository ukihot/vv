module Domain.IAM.Permission.ValueObjects.PermissionState (PermissionState (..)) where

data PermissionState
  = Draft
  | Active
  | Retired
  deriving stock (Show, Eq, Ord)
