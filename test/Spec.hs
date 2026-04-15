module Main (main) where

import Domain.Accounting.Spec qualified as Accounting
import Domain.IAM.Spec qualified as IAM
import Domain.IFRS.Spec qualified as IFRS
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main =
    defaultMain $
        testGroup
            "vv"
            [ IAM.tests,
              Accounting.tests,
              IFRS.tests
            ]
