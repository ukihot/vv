module App.IAM.ActivateUserSpec (tests) where

import App.DTO.Request.IAM (ActivateUserRequest (..))
import App.UseCase.IAM.ActivateUser (executeActivateUser)
import Control.Monad.State (execState)
import Data.Map.Strict qualified as Map
import Domain.IAM.User.Services.Factory (registerUser)
import Support.IAM.Fixtures (shouldMakeEmail, shouldMakeUserId, shouldMakeUserName)
import Support.IAM.MockEnv (MockState (..), emptyMockState, initialStateWithUser, mockIamEnv)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertBool, assertEqual, testCase)

tests :: TestTree
tests =
    testGroup
        "ActivateUser UseCase"
        [ testCase "pending ユーザーを有効化すると成功レスポンスが記録される" case_activateSuccess
        , testCase "存在しないユーザーは失敗レスポンスが記録される" case_activateNotFound
        , testCase "有効化後に UserActivated イベントが追記される" case_activateAppendsEvent
        , testCase "無効な UserId は失敗レスポンスが記録される" case_activateInvalidId
        ]

case_activateSuccess :: Assertion
case_activateSuccess = do
    uid <- shouldMakeUserId "user-001"
    name <- shouldMakeUserName "Alice"
    email <- shouldMakeEmail "alice@example.com"
    let (_, regEvent) = registerUser uid name email
        initState = initialStateWithUser uid [regEvent]
        finalState = execState (executeActivateUser mockIamEnv (ActivateUserRequest "user-001")) initState
    assertEqual "成功レスポンスが1件記録される" 1 (length (msPresentedSuccess finalState))
    assertEqual "失敗レスポンスは記録されない" 0 (length (msPresentedFailure finalState))

case_activateNotFound :: Assertion
case_activateNotFound = do
    let finalState = execState (executeActivateUser mockIamEnv (ActivateUserRequest "nonexistent")) emptyMockState
    assertEqual "失敗レスポンスが1件記録される" 1 (length (msPresentedFailure finalState))
    assertEqual "成功レスポンスは記録されない" 0 (length (msPresentedSuccess finalState))

case_activateAppendsEvent :: Assertion
case_activateAppendsEvent = do
    uid <- shouldMakeUserId "user-001"
    name <- shouldMakeUserName "Alice"
    email <- shouldMakeEmail "alice@example.com"
    let (_, regEvent) = registerUser uid name email
        initState = initialStateWithUser uid [regEvent]
        finalState = execState (executeActivateUser mockIamEnv (ActivateUserRequest "user-001")) initState
        events = Map.findWithDefault [] "user-001" (msUserEvents finalState)
    -- 登録イベント(初期) + 有効化イベント(追記) = 2件
    assertBool "UserActivated イベントが追記されている" (length events >= 2)

case_activateInvalidId :: Assertion
case_activateInvalidId = do
    let finalState = execState (executeActivateUser mockIamEnv (ActivateUserRequest "")) emptyMockState
    assertEqual "失敗レスポンスが1件記録される" 1 (length (msPresentedFailure finalState))
