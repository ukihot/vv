module App.IAM.Spec (tests) where

import App.IAM.ActivateUserSpec qualified as ActivateUser
import App.IAM.DeactivateUserSpec qualified as DeactivateUser
import App.IAM.RegisterUserSpec qualified as RegisterUser
import Test.Tasty (TestTree, testGroup)

tests :: TestTree
tests =
    testGroup
        "App.IAM UseCases"
        [ RegisterUser.tests
        , ActivateUser.tests
        , DeactivateUser.tests
        ]
