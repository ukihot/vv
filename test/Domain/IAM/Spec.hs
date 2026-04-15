module Domain.IAM.Spec (tests) where

import Domain.IAM.PermissionSpec qualified as PermissionSpec
import Domain.IAM.RoleSpec qualified as RoleSpec
import Domain.IAM.UserSpec qualified as UserSpec
import Test.Tasty (TestTree, testGroup)

tests :: TestTree
tests =
    testGroup
        "Domain.IAM"
        [ UserSpec.tests
        , RoleSpec.tests
        , PermissionSpec.tests
        ]
