module Domain.Accounting.FiscalPeriod.ValueObjects.FiscalPeriodId (
    FiscalPeriodId,
    mkFiscalPeriodId,
    unFiscalPeriodId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Accounting.FiscalPeriod.Errors (PeriodError (..))

newtype FiscalPeriodId = FiscalPeriodId {unFiscalPeriodId :: Text}
    deriving stock (Show, Eq, Ord)

mkFiscalPeriodId :: Text -> Either PeriodError FiscalPeriodId
mkFiscalPeriodId t
    | T.null normalized = Left InvalidPeriodId
    | otherwise = Right (FiscalPeriodId normalized)
    where
        normalized = T.strip t
