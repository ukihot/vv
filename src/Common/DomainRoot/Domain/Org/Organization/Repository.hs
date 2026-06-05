module Domain.Org.Organization.Repository (
    OrganizationRepository (..),
)
where

import Domain.Org.Organization (SomeOrganization)
import Domain.Org.Organization.ValueObjects.OrganizationId (OrganizationId)

class Monad m => OrganizationRepository m where
    saveOrganization :: SomeOrganization -> m ()
    findOrganizationById :: OrganizationId -> m (Maybe SomeOrganization)
    listAllOrganizations :: m [SomeOrganization]
