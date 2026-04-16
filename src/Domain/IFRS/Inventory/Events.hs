{-# LANGUAGE StandaloneDeriving #-}

module Domain.IFRS.Inventory.Events (
    InventoryEventPayload (..),
)
where

import Data.Time (Day)
import Domain.IFRS.Inventory (CostFormula)
import Domain.IFRS.Inventory.ValueObjects.InventoryId (InventoryId)
import Domain.Shared (Money)
import GHC.TypeLits (KnownSymbol, Symbol)

data InventoryEventPayload (currency :: Symbol)
    = -- | 棚卸資産受入 → DeferredTax集約
      InventoryReceived InventoryId Rational (Money currency) Day
    | -- | 棚卸資産払出 → Revenue集約（売上原価）
      InventoryIssued InventoryId Rational (Money currency) Day
    | -- | 評価損計上 → DeferredTax集約
      InventoryWrittenDown InventoryId (Money currency) (Money currency) Day
    | -- | 評価損戻入 → DeferredTax集約
      InventoryWriteDownReversed InventoryId (Money currency) Day
    | -- | 原価計算方法変更 → AuditTrail集約
      CostFormulaChanged InventoryId CostFormula Day
    | -- | 純実現可能価額再評価 → AuditTrail集約
      NetRealizableValueReassessed InventoryId (Money currency) Day

deriving stock instance KnownSymbol currency => Show (InventoryEventPayload currency)
deriving stock instance Eq (InventoryEventPayload currency)
