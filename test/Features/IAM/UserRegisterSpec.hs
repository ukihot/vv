{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module Features.IAM.UserRegisterSpec (
    tests,
) where

import Features.IAM.UserRegister.Core qualified as Core
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

data Field
    = Name
    | Email
    | Role
    deriving stock (Eq, Ord, Show)

tests :: TestTree
tests =
    testGroup
        "Features.IAM.UserRegister.Core"
        [ testCase "empty submit asks shell to report validation error" $ do
            let step = Core.handleCommand Core.Submit initial
            Core.stepEffects step @?= [Core.ReportValidationError "All fields are required."]
        , testCase "complete submit asks shell to register user" $ do
            let step = Core.handleCommand Core.Submit completed
            Core.stepEffects step @?= [Core.RegisterUser "alice" "alice@example.com" "admin"]
        ]

initial :: Core.UserRegisterState Field
initial = Core.initialState Name Email Role

completed :: Core.UserRegisterState Field
completed =
    applyCommands
        [ text "alice"
        , [Core.FocusNext]
        , text "alice@example.com"
        , [Core.FocusNext]
        , text "admin"
        ]
        initial

applyCommands ::
    [[Core.UserRegisterCommand]] -> Core.UserRegisterState Field -> Core.UserRegisterState Field
applyCommands commandGroups state =
    foldl applyCommand state (concat commandGroups)

applyCommand ::
    Core.UserRegisterState Field -> Core.UserRegisterCommand -> Core.UserRegisterState Field
applyCommand state command =
    Core.stepState (Core.handleCommand command state)

text :: String -> [Core.UserRegisterCommand]
text =
    map (Core.EditFocused . Core.InsertChar)
