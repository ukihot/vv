module Domain.Accounting.FiscalPeriod.ValueObjects.FiscalPeriodId
    ( FiscalPeriodId (..)
    , mkFiscalPeriodId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Accounting.FiscalPeriod.Errors (PeriodError (..))

newtype FiscalPeriodId = FiscalPeriodId {unFiscalPeriodId :: Text}
    deriving (Show, Eq, Ord)

mkFiscalPeriodId :: Text -> Either PeriodError FiscalPeriodId
mkFiscalPeriodId t
    | T.null t = Left InvalidPeriodId
    | otherwise = Right (FiscalPeriodId t)
