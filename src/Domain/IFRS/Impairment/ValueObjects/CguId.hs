module Domain.IFRS.Impairment.ValueObjects.CguId (
    CguId (..),
    mkCguId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Impairment.Errors (ImpairmentError (..))

newtype CguId = CguId {unCguId :: Text}
    deriving (Show, Eq, Ord)

mkCguId :: Text -> Either ImpairmentError CguId
mkCguId t
    | T.null t = Left InvalidCguId
    | otherwise = Right (CguId t)
