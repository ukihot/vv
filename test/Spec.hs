module Main (main) where

import Domain.IAM.Spec qualified as IAM
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main =
  defaultMain $
    testGroup
      "vv"
      [ IAM.tests
      ]
