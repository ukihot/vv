{- | 棚卸資産集約ルートエンティティ (IAS 2準拠)
原価測定、純実現可能価額、評価損を管理する。
-}
module Domain.IFRS.Inventory (
    -- * 集約
    Inventory (..),
    CostFormula (..),

    -- * 値オブジェクト
    module Domain.IFRS.Inventory.ValueObjects.InventoryId,
)
where

import Data.Text (Text)
import Domain.IFRS.Inventory.ValueObjects.InventoryId
import Domain.IFRS.Inventory.ValueObjects.Version (Version, initialVersion)
import Domain.Shared (Money)
import GHC.TypeLits (Symbol)

data CostFormula
    = FIFO
    | WeightedAverage
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data Inventory (currency :: Symbol) = Inventory
    { inventoryId :: InventoryId
    , inventoryItemCode :: Text
    , inventoryQuantity :: Rational
    , inventoryCost :: Money currency
    , inventoryNetRealizableValue :: Money currency
    , inventoryWriteDown :: Money currency
    , inventoryCostFormula :: CostFormula
    , inventoryVersion :: Version
    }
    deriving stock (Show, Eq)
