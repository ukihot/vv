module Domain.Org.Organization.ValueObjects.OrganizationId
    ( OrganizationId (..)
    , mkOrganizationId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Org.Organization.Errors (OrganizationError (..))

newtype OrganizationId = OrganizationId {unOrganizationId :: Text}
    deriving (Show, Eq, Ord)

mkOrganizationId :: Text -> Either OrganizationError OrganizationId
mkOrganizationId t
    | T.null t = Left InvalidOrganizationId
    | otherwise = Right (OrganizationId t)
