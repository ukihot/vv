module Domain.IFRS.Impairment.ValueObjects.ImpairmentTestId (
    ImpairmentTestId (..),
    mkImpairmentTestId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Impairment.Errors (ImpairmentError (..))

newtype ImpairmentTestId = ImpairmentTestId {unImpairmentTestId :: Text}
    deriving stock (Show, Eq, Ord)

mkImpairmentTestId :: Text -> Either ImpairmentError ImpairmentTestId
mkImpairmentTestId t
    | T.null t = Left InvalidImpairmentTestId
    | otherwise = Right (ImpairmentTestId t)
