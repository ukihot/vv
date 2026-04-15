module Domain.Ops.TaxConfiguration.Repository
    ( TaxConfigurationRepository (..)
    )
where

import Data.Time (Day)
import Domain.Ops.TaxConfiguration (TaxConfiguration)
import Domain.Ops.TaxConfiguration.ValueObjects.TaxConfigId (TaxConfigId)
import Domain.Ops.TaxConfiguration.ValueObjects.TaxType (TaxType)

class Monad m => TaxConfigurationRepository m where
    saveTaxConfiguration :: TaxConfiguration -> m ()
    findTaxConfigById :: TaxConfigId -> m (Maybe TaxConfiguration)
    findTaxConfigByTypeAndDate :: TaxType -> Day -> m (Maybe TaxConfiguration)
