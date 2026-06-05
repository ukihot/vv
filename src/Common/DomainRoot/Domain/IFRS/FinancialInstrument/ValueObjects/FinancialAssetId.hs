module Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (
    FinancialAssetId,
    mkFinancialAssetId,
    unFinancialAssetId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.FinancialInstrument.Errors (FinancialInstrumentError (..))

newtype FinancialAssetId = FinancialAssetId {unFinancialAssetId :: Text}
    deriving stock (Show, Eq, Ord)

mkFinancialAssetId :: Text -> Either FinancialInstrumentError FinancialAssetId
mkFinancialAssetId t
    | T.null normalized = Left InvalidAssetId
    | otherwise = Right (FinancialAssetId normalized)
    where
        normalized = T.strip t
