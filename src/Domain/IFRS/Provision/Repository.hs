module Domain.IFRS.Provision.Repository
    ( ProvisionRepository (..)
    )
where

import Domain.IFRS.Provision (Provision, ProvisionType)
import Domain.IFRS.Provision.ValueObjects.ProvisionId (ProvisionId)

class Monad m => ProvisionRepository m currency where
    saveProvision :: Provision currency -> m ()
    findProvisionById :: ProvisionId -> m (Maybe (Provision currency))
    findProvisionsByType :: ProvisionType -> m [Provision currency]
