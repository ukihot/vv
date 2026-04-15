module Domain.Org.Organization.Repository (
    OrganizationRepository (..),
)
where

import Domain.Org.Organization (Organization)
import Domain.Org.Organization.ValueObjects.OrganizationId (OrganizationId)

class Monad m => OrganizationRepository m where
    saveOrganization :: Organization -> m ()
    findOrganizationById :: OrganizationId -> m (Maybe Organization)
    listAllOrganizations :: m [Organization]
