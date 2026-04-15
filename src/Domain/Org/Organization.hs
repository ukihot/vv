{- | 組織集約ルートエンティティ
会社・事業所などの組織情報を管理する。
-}
module Domain.Org.Organization (
    -- * 集約
    Organization (..),
    OrganizationState (..),
    SomeOrganization (..),

    -- * エンティティ
    module Domain.Org.Organization.Entities.Address,

    -- * 値オブジェクト
    module Domain.Org.Organization.ValueObjects.OrganizationId,
    module Domain.Org.Organization.ValueObjects.OrganizationName,
    module Domain.Org.Organization.ValueObjects.TaxId,

    -- * 状態遷移
    createOrganization,
    activateOrganization,
    deactivateOrganization,
)
where

import Data.Text (Text)
import Domain.Org.Organization.Entities.Address
import Domain.Org.Organization.Events (OrganizationEventPayload (..))
import Domain.Org.Organization.ValueObjects.OrganizationId
import Domain.Org.Organization.ValueObjects.OrganizationName
import Domain.Org.Organization.ValueObjects.OrganizationState (OrganizationState (..))
import Domain.Org.Organization.ValueObjects.TaxId
import Domain.Org.Organization.ValueObjects.Version (Version, initialVersion, nextVersion)

-- ─────────────────────────────────────────────────────────────────────────────
-- 組織集約 GADT
-- ─────────────────────────────────────────────────────────────────────────────

data Organization (s :: OrganizationState) where
    OrgSetup ::
        OrganizationId ->
        OrganizationName ->
        Maybe TaxId ->
        Maybe Address ->
        Version ->
        Organization 'Setup
    OrgActive ::
        OrganizationId ->
        OrganizationName ->
        TaxId ->
        Address ->
        Text ->
        Version ->
        Organization 'Active
    OrgInactive ::
        OrganizationId ->
        OrganizationName ->
        TaxId ->
        Address ->
        Text ->
        Version ->
        Organization 'Inactive

deriving instance Show (Organization s)
deriving instance Eq (Organization s)

data SomeOrganization where
    SomeOrg :: Organization s -> SomeOrganization

deriving instance Show SomeOrganization

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

createOrganization ::
    OrganizationId ->
    OrganizationName ->
    (Organization 'Setup, OrganizationEventPayload)
createOrganization orgId orgName =
    ( OrgSetup orgId orgName Nothing Nothing initialVersion
    , OrganizationCreated orgId orgName
    )

activateOrganization ::
    TaxId ->
    Address ->
    Text ->
    Organization 'Setup ->
    (Organization 'Active, OrganizationEventPayload)
activateOrganization taxId address functionalCurrency (OrgSetup orgId orgName _ _ v) =
    ( OrgActive orgId orgName taxId address functionalCurrency (nextVersion v)
    , OrganizationActivated orgId
    )

deactivateOrganization ::
    Organization 'Active ->
    (Organization 'Inactive, OrganizationEventPayload)
deactivateOrganization (OrgActive orgId orgName taxId address functionalCurrency v) =
    ( OrgInactive orgId orgName taxId address functionalCurrency (nextVersion v)
    , OrganizationDeactivated orgId
    )
