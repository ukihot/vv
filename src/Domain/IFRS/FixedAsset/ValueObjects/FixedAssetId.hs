module Domain.IFRS.FixedAsset.ValueObjects.FixedAssetId (
    FixedAssetId (..),
    mkFixedAssetId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.FixedAsset.Errors (FixedAssetError (..))

newtype FixedAssetId = FixedAssetId {unFixedAssetId :: Text}
    deriving (Show, Eq, Ord)

mkFixedAssetId :: Text -> Either FixedAssetError FixedAssetId
mkFixedAssetId t
    | T.null t = Left InvalidFixedAssetId
    | otherwise = Right (FixedAssetId t)
