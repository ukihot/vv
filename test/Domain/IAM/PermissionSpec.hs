module Domain.IAM.PermissionSpec (tests) where

import Domain.IAM.Permission
  ( activatePermission,
    getPermissionId,
    getPermissionProfile,
    getPermissionVersion,
    retirePermission,
  )
import Domain.IAM.Permission.Entities.Profile (PermissionProfile (..))
import Domain.IAM.Permission.Events (PermissionEventPayload (..))
import Domain.IAM.Permission.Services.Factory (definePermission)
import Domain.IAM.Permission.ValueObjects.Version qualified as PermissionVersion
import Support.IAM.Fixtures
  ( shouldMakePermissionCode,
    shouldMakePermissionId,
    shouldMakePermissionName,
    shouldMakeUserId,
  )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, testCase)

tests :: TestTree
tests =
  testGroup
    "Permission"
    [ testGroup
        "Factory"
        [ testCase "definePermission seeds a draft permission with initial version" case_definePermissionSeedsDraftPermission
        ],
      testGroup
        "Transitions"
        [ testCase "permission lifecycle activates then retires" case_permissionLifecycle
        ]
    ]

case_definePermissionSeedsDraftPermission :: Assertion
case_definePermissionSeedsDraftPermission = do
  permissionId <- shouldMakePermissionId "perm-user-read"
  permissionName <- shouldMakePermissionName "Read user"
  permissionCode <- shouldMakePermissionCode "user.read"
  let (permission, event) = definePermission permissionId permissionName permissionCode
  assertEqual "permission id" permissionId (getPermissionId permission)
  assertEqual "permission profile" (PermissionProfile permissionName permissionCode) (getPermissionProfile permission)
  assertEqual "permission version" (PermissionVersion.Version 0) (getPermissionVersion permission)
  assertEqual "permission defined event" (PermissionDefined permissionId permissionName permissionCode) event

case_permissionLifecycle :: Assertion
case_permissionLifecycle = do
  actorId <- shouldMakeUserId "user-001"
  permissionId <- shouldMakePermissionId "perm-user-read"
  permissionName <- shouldMakePermissionName "Read user"
  permissionCode <- shouldMakePermissionCode "user.read"
  let (draftPermission, _) = definePermission permissionId permissionName permissionCode
      (activePermission, activatedEvent) = activatePermission actorId draftPermission
      (retiredPermission, retiredEvent) = retirePermission actorId activePermission
  assertEqual "permission activated event" (PermissionActivated actorId permissionId) activatedEvent
  assertEqual "permission retired version" (PermissionVersion.Version 2) (getPermissionVersion retiredPermission)
  assertEqual "permission retired event" (PermissionRetired actorId permissionId) retiredEvent
