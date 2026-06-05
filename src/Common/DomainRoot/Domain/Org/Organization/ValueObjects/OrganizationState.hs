module Domain.Org.Organization.ValueObjects.OrganizationState (
    OrganizationState (..),
)
where

data OrganizationState
    = -- | 設定中
      Setup
    | -- | 稼働中
      Active
    | -- | 休止中
      Inactive
    deriving stock (Show, Eq, Ord, Enum, Bounded)
