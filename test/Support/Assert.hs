module Support.Assert (assertRight) where

import Test.Tasty.HUnit (assertFailure)

assertRight :: String -> Either String a -> IO a
assertRight _ (Right value) = pure value
assertRight label (Left err) = assertFailure (label <> " failed: " <> err)
