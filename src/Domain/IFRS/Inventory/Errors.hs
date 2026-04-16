module Domain.IFRS.Inventory.Errors (
    InventoryError (..),
)
where

data InventoryError
    = InvalidInventoryId
    | NegativeQuantity
    | InvalidCostFormula
    deriving stock (Show, Eq)
