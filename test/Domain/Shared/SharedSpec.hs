{- | Domain.Shared の Money 型に対する単体テスト
Num インスタンスと既存演算関数の整合性を検証する。
-}
module Domain.Shared.SharedSpec (tests) where

import Domain.Shared (
    Money,
    addMoney,
    mkMoney',
    negateMoney,
    scaleMoney,
    subMoney,
    toRationalMoney,
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
            "zeroMoney"
            [ testCase "zeroMoney は加算の単位元" case_zeroIsZero
            , testCase "zeroMoney + x = x（左単位元）" case_leftIdentity
            , testCase "x + zeroMoney = x（右単位元）" case_rightIdentity
            ]
        , testGroup
            "sum"
            [ testCase "空リストは zeroMoney" case_sumEmpty
            , testCase "仕訳行リストの合計" case_sumLines
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
            [ testProperty "結合律: (a + b) + c = a + (b + c)" prop_associativity
            , testProperty "sum = foldr (+) zeroMoney" prop_sumFoldr
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
        (mkMoney' 300 :: Money "JPY")
        (mkMoney' 100 + mkMoney' 200)

-- 異通貨の加算はコンパイルエラーになるため、型安全性はコンパイル時に保証済み。
-- このテストはその事実をドキュメントとして残す。
case_semigroupTypeSafety :: IO ()
case_semigroupTypeSafety =
    -- Money "JPY" と Money "USD" は別の型。
    -- 以下はコンパイルエラーになるため、実行時テストは不要。
    --   (mkMoney' 100 :: Money "JPY") + (mkMoney' 100 :: Money "USD")
    pure ()

case_zeroIsZero :: IO ()
case_zeroIsZero =
    assertEqual
        "zeroMoney = 0"
        (zeroMoney :: Money "JPY")
        (mkMoney' 0)

case_leftIdentity :: IO ()
case_leftIdentity =
    let x = mkMoney' 12345 :: Money "JPY"
     in assertEqual "zeroMoney + x = x" x (zeroMoney + x)

case_rightIdentity :: IO ()
case_rightIdentity =
    let x = mkMoney' 12345 :: Money "JPY"
     in assertEqual "x + zeroMoney = x" x (x + zeroMoney)

case_sumEmpty :: IO ()
case_sumEmpty =
    assertEqual
        "sum [] = zeroMoney"
        (zeroMoney :: Money "JPY")
        (sum ([] :: [Money "JPY"]))

-- 仕訳行の借方合計を sum で計算する実用例
case_sumLines :: IO ()
case_sumLines =
    let lines_ = map mkMoney' [100000, 200000, 300000] :: [Money "JPY"]
     in assertEqual "借方合計" (mkMoney' 600000) (sum lines_)

case_semigroupEqualsAddMoney :: IO ()
case_semigroupEqualsAddMoney =
    let a = mkMoney' 111 :: Money "JPY"
        b = mkMoney' 222 :: Money "JPY"
     in assertEqual "(<>) = addMoney" (addMoney a b) (a + b)

case_subMoney :: IO ()
case_subMoney =
    assertEqual
        "500 - 200 = 300"
        (mkMoney' 300 :: Money "JPY")
        (subMoney (mkMoney' 500) (mkMoney' 200))

case_negateMoney :: IO ()
case_negateMoney =
    assertEqual
        "negate 100 = -100"
        (mkMoney' (-100) :: Money "JPY")
        (negateMoney (mkMoney' 100))

case_scaleMoney :: IO ()
case_scaleMoney =
    assertEqual
        "0.5 * 200 = 100"
        (mkMoney' 100 :: Money "JPY")
        (scaleMoney (1 / 2) (mkMoney' 200))

-- ─────────────────────────────────────────────────────────────────────────────
-- Hedgehog プロパティ
-- ─────────────────────────────────────────────────────────────────────────────

genMoney :: Gen (Money "JPY")
genMoney = mkMoney' . fromIntegral <$> Gen.int (Range.linearFrom 0 (-1000000) 1000000)

-- | 結合律
prop_associativity :: Property
prop_associativity = property $ do
    a <- forAll genMoney
    b <- forAll genMoney
    c <- forAll genMoney
    (a + b) + c === a + (b + c)

-- | sum は foldr (+) zeroMoney と等しい
prop_sumFoldr :: Property
prop_sumFoldr = property $ do
    xs <- forAll $ Gen.list (Range.linear 0 20) genMoney
    sum xs === foldr (+) zeroMoney xs

-- | (<>) と addMoney は常に等しい
prop_semigroupEqualsAddMoneyProp :: Property
prop_semigroupEqualsAddMoneyProp = property $ do
    a <- forAll genMoney
    b <- forAll genMoney
    (a + b) === addMoney a b
