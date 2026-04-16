module App.IAM.RegisterUserSpec (tests) where

import App.DTO.Request.IAM (RegisterUserRequest (..))
import App.UseCase.IAM.RegisterUser (executeRegisterUser)
import Control.Monad.State (execState)
import Support.IAM.MockEnv (MockState (..), emptyMockState, mockIamEnv)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, testCase)

tests :: TestTree
tests =
    testGroup
        "RegisterUser UseCase"
        [ testCase "正常な入力でユーザー登録が成功する" case_registerSuccess
        , testCase "無効なメールアドレスは失敗レスポンスになる" case_registerInvalidEmail
        , testCase "空のユーザー名は失敗レスポンスになる" case_registerEmptyName
        ]

case_registerSuccess :: Assertion
case_registerSuccess = do
    let req = RegisterUserRequest "alice" "alice@example.com" "admin"
        finalState = execState (executeRegisterUser mockIamEnv req) emptyMockState
    assertEqual "成功レスポンスが1件記録される" 1 (length (msPresentedSuccess finalState))
    assertEqual "失敗レスポンスは記録されない" 0 (length (msPresentedFailure finalState))

case_registerInvalidEmail :: Assertion
case_registerInvalidEmail = do
    let req = RegisterUserRequest "alice" "not-an-email" "admin"
        finalState = execState (executeRegisterUser mockIamEnv req) emptyMockState
    assertEqual "失敗レスポンスが1件記録される" 1 (length (msPresentedFailure finalState))
    assertEqual "成功レスポンスは記録されない" 0 (length (msPresentedSuccess finalState))

case_registerEmptyName :: Assertion
case_registerEmptyName = do
    let req = RegisterUserRequest "" "alice@example.com" "admin"
        finalState = execState (executeRegisterUser mockIamEnv req) emptyMockState
    assertEqual "失敗レスポンスが1件記録される" 1 (length (msPresentedFailure finalState))
