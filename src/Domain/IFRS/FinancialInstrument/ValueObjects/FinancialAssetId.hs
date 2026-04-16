module Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (
    FinancialAssetId (..),
    mkFinancialAssetId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.FinancialInstrument.Errors (FinancialInstrumentError (..))

newtype FinancialAssetId = FinancialAssetId {unFinancialAssetId :: Text}
    deriving stock (Show, Eq, Ord)

mkFinancialAssetId :: Text -> Either FinancialInstrumentError FinancialAssetId
mkFinancialAssetId t
    | T.null t = Left InvalidAssetId
    | otherwise = Right (FinancialAssetId t)
