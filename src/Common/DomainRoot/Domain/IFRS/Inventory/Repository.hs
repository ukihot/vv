module Domain.IFRS.Inventory.Repository (
    InventoryRepository (..),
)
where

import Data.Text (Text)
import Domain.IFRS.Inventory (Inventory)
import Domain.IFRS.Inventory.ValueObjects.InventoryId (InventoryId)

class Monad m => InventoryRepository m currency where
    saveInventory :: Inventory currency -> m ()
    findInventoryById :: InventoryId -> m (Maybe (Inventory currency))
    findInventoryByItemCode :: Text -> m (Maybe (Inventory currency))
