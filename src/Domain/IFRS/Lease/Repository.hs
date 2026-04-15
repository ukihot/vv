module Domain.IFRS.Lease.Repository
    ( LeaseRepository (..)
    )
where

import Domain.IFRS.Lease (Lease)
import Domain.IFRS.Lease.ValueObjects.LeaseId (LeaseId)

class Monad m => LeaseRepository m currency where
    saveLease :: Lease currency -> m ()
    findLeaseById :: LeaseId -> m (Maybe (Lease currency))
