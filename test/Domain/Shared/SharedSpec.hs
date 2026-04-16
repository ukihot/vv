{- | Domain.Shared の Money 型に対する単体テスト
Semigroup / Monoid インスタンスと既存演算関数の整合性を検証する。
-}
module Domain.Shared.SharedSpec (tests) where

import Domain.Shared (
    Money (..),
    addMoney,
    mkMoney,
    negateMoney,
    scaleMoney,
    subMoney,
    unMoney,
    zeroMoney,
 )
import Hedgehog (Gen, Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertEqual, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
    testGroup
        "Domain.Shared – Money"
        [ testGroup
            "Semigroup (<>)"
            [ testCase "JPY 100 <> JPY 200 = JPY 300" case_semigroupAdd
            , testCase "異通貨は型が通らない（コンパイル時保証）" case_semigroupTypeSafety
            ]
        , testGroup
            "Monoid mempty"
            [ testCase "mempty = zeroMoney" case_memptyIsZero
            , testCase "mempty <> x = x（左単位元）" case_leftIdentity
            , testCase "x <> mempty = x（右単位元）" case_rightIdentity
            ]
        , testGroup
            "mconcat"
            [ testCase "空リストは zeroMoney" case_mconcatEmpty
            , testCase "仕訳行リストの合計" case_mconcatLines
            ]
        , testGroup
            "(<>) と addMoney の整合性"
            [ testCase "(<>) = addMoney" case_semigroupEqualsAddMoney
            ]
        , testGroup
            "既存演算関数"
            [ testCase "subMoney" case_subMoney
            , testCase "negateMoney" case_negateMoney
            , testCase "scaleMoney" case_scaleMoney
            ]
        , testGroup
            "Properties"
            [ testProperty "結合律: (a <> b) <> c = a <> (b <> c)" prop_associativity
            , testProperty "mconcat = foldr (<>) mempty" prop_mconcatFoldr
            , testProperty "(<>) と addMoney は常に等しい" prop_semigroupEqualsAddMoneyProp
            ]
        ]

-- ─────────────────────────────────────────────────────────────────────────────
-- HUnit ケース
-- ─────────────────────────────────────────────────────────────────────────────

case_semigroupAdd :: IO ()
case_semigroupAdd =
    assertEqual
        "100 + 200 = 300"
        (mkMoney 300 :: Money "JPY")
        (mkMoney 100 <> mkMoney 200)

-- 異通貨の加算はコンパイルエラーになるため、型安全性はコンパイル時に保証済み。
-- このテストはその事実をドキュメントとして残す。
case_semigroupTypeSafety :: IO ()
case_semigroupTypeSafety =
    -- Money "JPY" と Money "USD" は別の型。
    -- 以下はコンパイルエラーになるため、実行時テストは不要。
    --   (mkMoney 100 :: Money "JPY") <> (mkMoney 100 :: Money "USD")
    pure ()

case_memptyIsZero :: IO ()
case_memptyIsZero =
    assertEqual
        "mempty = zeroMoney"
        (zeroMoney :: Money "JPY")
        mempty

case_leftIdentity :: IO ()
case_leftIdentity =
    let x = mkMoney 12345 :: Money "JPY"
     in assertEqual "mempty <> x = x" x (mempty <> x)

case_rightIdentity :: IO ()
case_rightIdentity =
    let x = mkMoney 12345 :: Money "JPY"
     in assertEqual "x <> mempty = x" x (x <> mempty)

case_mconcatEmpty :: IO ()
case_mconcatEmpty =
    assertEqual
        "mconcat [] = zeroMoney"
        (zeroMoney :: Money "JPY")
        (mconcat [])

-- 仕訳行の借方合計を mconcat で計算する実用例
case_mconcatLines :: IO ()
case_mconcatLines =
    let lines_ = map mkMoney [100000, 200000, 300000] :: [Money "JPY"]
     in assertEqual "借方合計" (mkMoney 600000) (mconcat lines_)

case_semigroupEqualsAddMoney :: IO ()
case_semigroupEqualsAddMoney =
    let a = mkMoney 111 :: Money "JPY"
        b = mkMoney 222 :: Money "JPY"
     in assertEqual "(<>) = addMoney" (addMoney a b) (a <> b)

case_subMoney :: IO ()
case_subMoney =
    assertEqual
        "500 - 200 = 300"
        (mkMoney 300 :: Money "JPY")
        (subMoney (mkMoney 500) (mkMoney 200))

case_negateMoney :: IO ()
case_negateMoney =
    assertEqual
        "negate 100 = -100"
        (mkMoney (-100) :: Money "JPY")
        (negateMoney (mkMoney 100))

case_scaleMoney :: IO ()
case_scaleMoney =
    assertEqual
        "0.5 * 200 = 100"
        (mkMoney 100 :: Money "JPY")
        (scaleMoney (1 / 2) (mkMoney 200))

-- ─────────────────────────────────────────────────────────────────────────────
-- Hedgehog プロパティ
-- ─────────────────────────────────────────────────────────────────────────────

genMoney :: Gen (Money "JPY")
genMoney = mkMoney . fromIntegral <$> Gen.int (Range.linearFrom 0 (-1000000) 1000000)

-- | Semigroup 結合律
prop_associativity :: Property
prop_associativity = property $ do
    a <- forAll genMoney
    b <- forAll genMoney
    c <- forAll genMoney
    (a <> b) <> c === a <> (b <> c)

-- | mconcat は foldr (<>) mempty と等しい
prop_mconcatFoldr :: Property
prop_mconcatFoldr = property $ do
    xs <- forAll $ Gen.list (Range.linear 0 20) genMoney
    mconcat xs === foldr (<>) mempty xs

-- | (<>) と addMoney は常に等しい
prop_semigroupEqualsAddMoneyProp :: Property
prop_semigroupEqualsAddMoneyProp = property $ do
    a <- forAll genMoney
    b <- forAll genMoney
    (a <> b) === addMoney a b
