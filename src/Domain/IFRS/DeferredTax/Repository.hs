module Domain.IFRS.DeferredTax.Repository (
    DeferredTaxRepository (..),
)
where

import Domain.IFRS.DeferredTax (DeferredTaxItem)
import Domain.IFRS.DeferredTax.ValueObjects.DeferredTaxItemId (DeferredTaxItemId)
import Domain.Shared (FiscalYearMonth)

class Monad m => DeferredTaxRepository m currency where
    saveDeferredTaxItem :: DeferredTaxItem currency -> m ()
    findDeferredTaxItemById :: DeferredTaxItemId -> m (Maybe (DeferredTaxItem currency))
    findDeferredTaxItemsByPeriod :: FiscalYearMonth -> m [DeferredTaxItem currency]
