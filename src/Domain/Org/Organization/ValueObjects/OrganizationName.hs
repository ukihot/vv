module Domain.Org.Organization.ValueObjects.OrganizationName (
    OrganizationName (..),
    mkOrganizationName,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Org.Organization.Errors (OrganizationError (..))

newtype OrganizationName = OrganizationName {unOrganizationName :: Text}
    deriving (Show, Eq, Ord)

mkOrganizationName :: Text -> Either OrganizationError OrganizationName
mkOrganizationName t
    | T.null t = Left InvalidOrganizationName
    | otherwise = Right (OrganizationName t)
