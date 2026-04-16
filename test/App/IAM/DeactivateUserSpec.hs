module App.IAM.DeactivateUserSpec (tests) where

import App.DTO.Request.IAM (DeactivateUserRequest (..))
import App.UseCase.IAM.DeactivateUser (executeDeactivateUser)
import Control.Monad.State (execState)
import Domain.IAM.User (activateUser)
import Domain.IAM.User.Services.Factory (registerUser)
import Support.IAM.Fixtures (shouldMakeEmail, shouldMakeUserId, shouldMakeUserName)
import Support.IAM.MockEnv (MockState (..), emptyMockState, initialStateWithUser, mockIamEnv)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, testCase)

tests :: TestTree
tests =
    testGroup
        "DeactivateUser UseCase"
        [ testCase "Active ユーザーを無効化すると成功レスポンスが記録される" case_deactivateSuccess
        , testCase "Pending ユーザーの無効化は失敗レスポンスになる" case_deactivatePendingFails
        ]

case_deactivateSuccess :: Assertion
case_deactivateSuccess = do
    uid <- shouldMakeUserId "user-001"
    name <- shouldMakeUserName "Alice"
    email <- shouldMakeEmail "alice@example.com"
    let (pendingUser, regEvent) = registerUser uid name email
        (_, actEvent) = activateUser pendingUser
        initState = initialStateWithUser uid [regEvent, actEvent]
        req = DeactivateUserRequest "user-001" "退職のため"
        finalState = execState (executeDeactivateUser mockIamEnv req) initState
    assertEqual "成功レスポンスが1件記録される" 1 (length (msPresentedSuccess finalState))
    assertEqual "失敗レスポンスは記録されない" 0 (length (msPresentedFailure finalState))

case_deactivatePendingFails :: Assertion
case_deactivatePendingFails = do
    uid <- shouldMakeUserId "user-001"
    name <- shouldMakeUserName "Alice"
    email <- shouldMakeEmail "alice@example.com"
    let (_, regEvent) = registerUser uid name email
        initState = initialStateWithUser uid [regEvent]
        req = DeactivateUserRequest "user-001" "テスト"
        finalState = execState (executeDeactivateUser mockIamEnv req) initState
    assertEqual "失敗レスポンスが1件記録される" 1 (length (msPresentedFailure finalState))
    assertEqual "成功レスポンスは記録されない" 0 (length (msPresentedSuccess finalState))
