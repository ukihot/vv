module Support.Assert (assertRight) where

import Test.Tasty.HUnit (assertFailure)

{- | Either の Right 値を取り出す。Left の場合はテスト失敗。
Show 制約により DomainError 等の専用 ADT にも対応する (#7)。
-}
assertRight :: Show e => String -> Either e a -> IO a
assertRight _ (Right value) = pure value
assertRight label (Left err) = assertFailure (label <> " failed: " <> show err)
