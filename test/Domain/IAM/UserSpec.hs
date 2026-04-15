module Domain.IAM.UserSpec (tests) where

import Domain.IAM.User
  ( activateUser,
    deactivateUser,
    getUserId,
    getUserProfile,
    getUserVersion,
    suspendUser,
    unsuspendUser,
  )
import Domain.IAM.User.Entities.Profile (UserProfile (..))
import Domain.IAM.User.Events (UserEventPayload (..))
import Domain.IAM.User.Services.Factory (registerUser)
import Domain.IAM.User.ValueObjects.Version (Version (..), initialVersion)
import Hedgehog (Property, forAll, property, (===))
import Support.Assert (assertRight)
import Support.IAM.Fixtures
  ( genEmail,
    genUserId,
    genUserName,
    samplePendingUser,
    shouldMakeEmail,
    shouldMakeUserId,
    shouldMakeUserName,
  )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
  testGroup
    "User"
    [ testGroup
        "Factory"
        [ testCase "registerUser seeds a pending user with initial version" case_registerUserSeedsPendingUser
        ],
      testGroup
        "Transitions"
        [ testCase "activateUser preserves identity and profile while incrementing version" case_activateUserPreservesIdentity,
          testCase "suspend and unsuspend form a reversible active workflow" case_suspendAndUnsuspendWorkflow,
          testCase "deactivateUser accepts active and suspended users" case_deactivateAcceptsActiveAndSuspended,
          testCase "deactivateUser rejects pending users" case_deactivateRejectsPending
        ],
      testGroup
        "Properties"
        [ testProperty "registerUser echoes input into aggregate and event" prop_registerUserEchoesInputs,
          testProperty "full lifecycle keeps user id/profile and bumps version at each step" prop_lifecyclePreservesInvariant
        ]
    ]

case_registerUserSeedsPendingUser :: Assertion
case_registerUserSeedsPendingUser = do
  uid <- shouldMakeUserId "user-001"
  name <- shouldMakeUserName "Alice"
  email <- shouldMakeEmail "alice@example.com"
  let (user, event) = registerUser uid name email
  assertEqual "registered id" uid (getUserId user)
  assertEqual "registered profile" (UserProfile name email) (getUserProfile user)
  assertEqual "initial version" initialVersion (getUserVersion user)
  assertEqual "registration event" (UserRegistered uid name email) event

case_activateUserPreservesIdentity :: Assertion
case_activateUserPreservesIdentity = do
  pendingUser <- samplePendingUser
  let (activeUser, event) = activateUser pendingUser
  assertEqual "activated id" (getUserId pendingUser) (getUserId activeUser)
  assertEqual "activated profile" (getUserProfile pendingUser) (getUserProfile activeUser)
  assertEqual "activated version" (Version 1) (getUserVersion activeUser)
  assertEqual "activation event" (UserActivated (getUserId pendingUser)) event

case_suspendAndUnsuspendWorkflow :: Assertion
case_suspendAndUnsuspendWorkflow = do
  pendingUser <- samplePendingUser
  let (activeUser, _) = activateUser pendingUser
      (suspendedUser, suspendedEvent) = suspendUser activeUser
      (reactivatedUser, unsuspendedEvent) = unsuspendUser suspendedUser
  assertEqual "suspended version" (Version 2) (getUserVersion suspendedUser)
  assertEqual "suspended event" (UserSuspended (getUserId activeUser)) suspendedEvent
  assertEqual "reactivated id" (getUserId activeUser) (getUserId reactivatedUser)
  assertEqual "reactivated profile" (getUserProfile activeUser) (getUserProfile reactivatedUser)
  assertEqual "reactivated version" (Version 3) (getUserVersion reactivatedUser)
  assertEqual "unsuspended event" (UserUnsuspended (getUserId suspendedUser)) unsuspendedEvent

case_deactivateAcceptsActiveAndSuspended :: Assertion
case_deactivateAcceptsActiveAndSuspended = do
  pendingUser <- samplePendingUser
  let (activeUser, _) = activateUser pendingUser
  inactiveFromActive <- assertRight "deactivate active" (deactivateUser activeUser)
  assertEqual "inactive version from active" (Version 2) (getUserVersion (fst inactiveFromActive))
  assertEqual "inactive event from active" (UserDeactivated (getUserId activeUser)) (snd inactiveFromActive)

  let (suspendedUser, _) = suspendUser activeUser
  inactiveFromSuspended <- assertRight "deactivate suspended" (deactivateUser suspendedUser)
  assertEqual "inactive version from suspended" (Version 3) (getUserVersion (fst inactiveFromSuspended))
  assertEqual "inactive event from suspended" (UserDeactivated (getUserId suspendedUser)) (snd inactiveFromSuspended)

case_deactivateRejectsPending :: Assertion
case_deactivateRejectsPending = do
  pendingUser <- samplePendingUser
  case deactivateUser pendingUser of
    Left err ->
      assertEqual
        "pending users cannot be deactivated"
        "Only Active or Suspended users can be deactivated."
        err
    Right _ -> assertFailure "expected pending deactivation to fail"

prop_registerUserEchoesInputs :: Property
prop_registerUserEchoesInputs = property $ do
  uid <- forAll genUserId
  name <- forAll genUserName
  email <- forAll genEmail
  let (user, event) = registerUser uid name email
  getUserId user === uid
  getUserProfile user === UserProfile name email
  getUserVersion user === initialVersion
  event === UserRegistered uid name email

prop_lifecyclePreservesInvariant :: Property
prop_lifecyclePreservesInvariant = property $ do
  uid <- forAll genUserId
  name <- forAll genUserName
  email <- forAll genEmail
  let (pendingUser, _) = registerUser uid name email
      (activeUser, activeEvent) = activateUser pendingUser
      (suspendedUser, suspendedEvent) = suspendUser activeUser
      (reactivatedUser, unsuspendedEvent) = unsuspendUser suspendedUser
      deactivated = deactivateUser reactivatedUser
  case deactivated of
    Left err -> fail ("expected deactivation to succeed in lifecycle property: " <> err)
    Right (inactiveUser, deactivatedEvent) -> do
      getUserId activeUser === uid
      getUserId suspendedUser === uid
      getUserId reactivatedUser === uid
      getUserId inactiveUser === uid
      getUserProfile activeUser === UserProfile name email
      getUserProfile suspendedUser === UserProfile name email
      getUserProfile reactivatedUser === UserProfile name email
      getUserProfile inactiveUser === UserProfile name email
      getUserVersion activeUser === Version 1
      getUserVersion suspendedUser === Version 2
      getUserVersion reactivatedUser === Version 3
      getUserVersion inactiveUser === Version 4
      activeEvent === UserActivated uid
      suspendedEvent === UserSuspended uid
      unsuspendedEvent === UserUnsuspended uid
      deactivatedEvent === UserDeactivated uid
