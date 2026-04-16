module Domain.Ops.TaxConfiguration.ValueObjects.TaxConfigId (
    TaxConfigId (..),
    mkTaxConfigId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.TaxConfiguration.Errors (TaxConfigError (..))

newtype TaxConfigId = TaxConfigId {unTaxConfigId :: Text}
    deriving stock (Show, Eq, Ord)

mkTaxConfigId :: Text -> Either TaxConfigError TaxConfigId
mkTaxConfigId t
    | T.null t = Left InvalidTaxConfigId
    | otherwise = Right (TaxConfigId t)
