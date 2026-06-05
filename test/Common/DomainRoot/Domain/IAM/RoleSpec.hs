module Domain.IAM.RoleSpec (tests) where

import Domain.IAM.Role (
    activateRole,
    assignPermissionToRole,
    deactivateRole,
    getRoleId,
    getRoleProfile,
    getRoleVersion,
    revokePermissionFromRole,
 )
import Domain.IAM.Role.Entities.Profile (RoleProfile (..))
import Domain.IAM.Role.Events (RoleEventPayload (..))
import Domain.IAM.Role.Services.Factory (createRole)
import Domain.IAM.Role.ValueObjects.Version qualified as RoleVersion
import Support.IAM.Fixtures (
    shouldMakePermissionId,
    shouldMakeRoleId,
    shouldMakeRoleName,
    shouldMakeUserId,
 )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, testCase)

tests :: TestTree
tests =
    testGroup
        "Role"
        [ testGroup
            "Factory"
            [ testCase "createRole seeds a draft role with empty permission set" case_createRoleSeedsDraftRole
            ]
        , testGroup
            "Transitions"
            [ testCase "active role can assign and revoke permissions" case_rolePermissionWorkflow
            ]
        ]

case_createRoleSeedsDraftRole :: Assertion
case_createRoleSeedsDraftRole = do
    roleId <- shouldMakeRoleId "role-admin"
    roleName <- shouldMakeRoleName "Administrators"
    let (role, event) = createRole roleId roleName
    assertEqual "role id" roleId (getRoleId role)
    assertEqual "role profile" (RoleProfile roleName []) (getRoleProfile role)
    assertEqual "role version" (RoleVersion.Version 0) (getRoleVersion role)
    assertEqual "role created event" (RoleCreated roleId roleName) event

case_rolePermissionWorkflow :: Assertion
case_rolePermissionWorkflow = do
    actorId <- shouldMakeUserId "user-001"
    roleId <- shouldMakeRoleId "role-admin"
    roleName <- shouldMakeRoleName "Administrators"
    permissionId <- shouldMakePermissionId "perm-user-read"
    let (draftRole, _) = createRole roleId roleName
        (activeRole, activatedEvent) = activateRole actorId draftRole
        (grantedRole, grantedEvent) = assignPermissionToRole actorId permissionId activeRole
        (cleanRole, revokedEvent) = revokePermissionFromRole actorId permissionId grantedRole
        (inactiveRole, deactivatedEvent) = deactivateRole actorId cleanRole
    assertEqual "role activated event" (RoleActivated actorId roleId) activatedEvent
    assertEqual
        "role granted profile"
        (RoleProfile roleName [permissionId])
        (getRoleProfile grantedRole)
    assertEqual "role granted event" (PermissionAssignedToRole actorId roleId permissionId) grantedEvent
    assertEqual "role cleaned profile" (RoleProfile roleName []) (getRoleProfile cleanRole)
    assertEqual
        "role revoked event"
        (PermissionRevokedFromRole actorId roleId permissionId)
        revokedEvent
    assertEqual "role inactive version" (RoleVersion.Version 4) (getRoleVersion inactiveRole)
    assertEqual "role deactivated event" (RoleDeactivated actorId roleId) deactivatedEvent
