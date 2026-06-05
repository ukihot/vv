module Domain.Org.Organization.Events (
    OrganizationEventPayload (..),
)
where

import Domain.Org.Organization.ValueObjects.OrganizationId (OrganizationId)
import Domain.Org.Organization.ValueObjects.OrganizationName (OrganizationName)

data OrganizationEventPayload
    = OrganizationCreated OrganizationId OrganizationName
    | OrganizationNameUpdated OrganizationId OrganizationName
    | OrganizationActivated OrganizationId
    | OrganizationDeactivated OrganizationId
    deriving stock (Show, Eq)
