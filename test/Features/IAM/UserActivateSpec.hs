{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module Features.IAM.UserActivateSpec (
    tests,
) where

import Features.IAM.UserActivate.Core qualified as Core
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

data Field
    = UserId
    deriving stock (Eq, Ord, Show)

tests :: TestTree
tests =
    testGroup
        "Features.IAM.UserActivate.Core"
        [ testCase "empty submit asks shell to report validation error" $ do
            let step = Core.handleCommand Core.Submit initial
            Core.stepEffects step @?= [Core.ReportValidationError "User ID is required."]
        , testCase "filled submit asks shell to activate user" $ do
            let step = Core.handleCommand Core.Submit completed
            Core.stepEffects step @?= [Core.ActivateUser "user-1"]
        ]

initial :: Core.UserActivateState Field
initial = Core.initialState UserId

completed :: Core.UserActivateState Field
completed =
    foldl
        (\state command -> Core.stepState (Core.handleCommand command state))
        initial
        (map (Core.EditUserId . Core.InsertChar) "user-1")
