module Domain.IFRS.Inventory.ValueObjects.InventoryId (
    InventoryId (..),
    mkInventoryId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.IFRS.Inventory.Errors (InventoryError (..))

newtype InventoryId = InventoryId {unInventoryId :: Text}
    deriving stock (Show, Eq, Ord)

mkInventoryId :: Text -> Either InventoryError InventoryId
mkInventoryId t
    | T.null t = Left InvalidInventoryId
    | otherwise = Right (InventoryId t)
