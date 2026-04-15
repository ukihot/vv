module Domain.Org.Organization.ValueObjects.TaxId (
    TaxId (..),
    mkTaxId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Org.Organization.Errors (OrganizationError (..))

newtype TaxId = TaxId {unTaxId :: Text}
    deriving (Show, Eq, Ord)

mkTaxId :: Text -> Either OrganizationError TaxId
mkTaxId t
    | T.null t = Left InvalidTaxId
    | otherwise = Right (TaxId t)
