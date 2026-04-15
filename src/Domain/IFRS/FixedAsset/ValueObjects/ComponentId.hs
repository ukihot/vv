module Domain.IFRS.FixedAsset.ValueObjects.ComponentId
    ( ComponentId (..)
    , mkComponentId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.FixedAsset.Errors (FixedAssetError (..))

newtype ComponentId = ComponentId {unComponentId :: Text}
    deriving (Show, Eq, Ord)

mkComponentId :: Text -> Either FixedAssetError ComponentId
mkComponentId t
    | T.null t = Left InvalidComponentId
    | otherwise = Right (ComponentId t)
