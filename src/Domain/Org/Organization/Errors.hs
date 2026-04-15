module Domain.Org.Organization.Errors (
    OrganizationError (..),
)
where

data OrganizationError
    = InvalidOrganizationId
    | InvalidOrganizationName
    | InvalidTaxId
    deriving (Show, Eq)
