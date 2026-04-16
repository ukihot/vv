module Domain.IFRS.DeferredTax.ValueObjects.DeferredTaxItemId (
    DeferredTaxItemId (..),
    mkDeferredTaxItemId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.DeferredTax.Errors (DeferredTaxError (..))

newtype DeferredTaxItemId = DeferredTaxItemId {unDeferredTaxItemId :: Text}
    deriving stock (Show, Eq, Ord)

mkDeferredTaxItemId :: Text -> Either DeferredTaxError DeferredTaxItemId
mkDeferredTaxItemId t
    | T.null t = Left InvalidDeferredTaxItemId
    | otherwise = Right (DeferredTaxItemId t)
