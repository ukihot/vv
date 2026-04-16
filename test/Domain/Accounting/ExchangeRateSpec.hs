module Domain.Accounting.ExchangeRateSpec (tests) where

import Data.Time (fromGregorian)
import Domain.Accounting.ExchangeRate (
    ExchangeRate (..),
    ExchangeRateError (..),
    RateKind (..),
    mkExchangeRate,
    translateMoney,
 )
import Domain.Shared (Money, mkMoney', toRationalMoney)
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Money qualified as M
import Support.Accounting.Fixtures (
    sampleUsdJpyClosingRate,
    sampleUsdJpyHistoricalRate,
 )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
    testGroup
        "ExchangeRate"
        [ testGroup
            "mkExchangeRate"
            [ testCase "正のレートは成功" case_positiveRateSucceeds
            , testCase "ゼロレートはエラー" case_zeroRateFails
            , testCase "負のレートはエラー" case_negativeRateFails
            ]
        , testGroup
            "translateMoney §4.7.10.3"
            [ testCase "期末日レートで貨幣性項目を換算" case_translateMonetary
            , testCase "取引日レートで非貨幣性項目を換算" case_translateNonMonetary
            ]
        , testGroup
            "Properties"
            [ testProperty "正のレートは常に成功" prop_positiveRateAlwaysSucceeds
            , testProperty "換算後金額 = 原通貨金額 × レート" prop_translationIsLinear
            ]
        ]

case_positiveRateSucceeds :: Assertion
case_positiveRateSucceeds = do
    let result = mkExchangeRate 150 ClosingRate (fromGregorian 2026 3 31) "BOJ"
    case result of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right _ -> pure ()

case_zeroRateFails :: Assertion
case_zeroRateFails =
    assertEqual
        "ゼロレートはエラー"
        (Left NonPositiveRate)
        ( mkExchangeRate 0 ClosingRate (fromGregorian 2026 3 31) "BOJ" ::
            Either ExchangeRateError (ExchangeRate "USD" "JPY")
        )

case_negativeRateFails :: Assertion
case_negativeRateFails =
    assertEqual
        "負レートはエラー"
        (Left NonPositiveRate)
        ( mkExchangeRate (-1) ClosingRate (fromGregorian 2026 3 31) "BOJ" ::
            Either ExchangeRateError (ExchangeRate "USD" "JPY")
        )

-- | 貨幣性項目: USD 1,000 × 期末日レート 150 = JPY 150,000
case_translateMonetary :: Assertion
case_translateMonetary = do
    rate <- sampleUsdJpyClosingRate
    let usd = mkMoney' 1000 :: Money "USD"
        jpy = translateMoney rate usd
    assertEqual "換算結果" (mkMoney' 150000 :: Money "JPY") jpy

-- | 非貨幣性項目: USD 1,000 × 取引日レート 145 = JPY 145,000
case_translateNonMonetary :: Assertion
case_translateNonMonetary = do
    rate <- sampleUsdJpyHistoricalRate
    let usd = mkMoney' 1000 :: Money "USD"
        jpy = translateMoney rate usd
    assertEqual "換算結果" (mkMoney' 145000 :: Money "JPY") jpy

prop_positiveRateAlwaysSucceeds :: Property
prop_positiveRateAlwaysSucceeds = property $ do
    r <- forAll $ Gen.realFrac_ (Range.linearFrac 0.0001 10000 :: Range.Range Double)
    let result =
            mkExchangeRate (toRational r) ClosingRate (fromGregorian 2026 3 31) "TEST" ::
                Either ExchangeRateError (ExchangeRate "USD" "JPY")
    case result of
        Right _ -> pure ()
        Left e -> fail ("正のレートが失敗: " <> show e)

-- | 換算の線形性: translate(r, a + b) = translate(r, a) + translate(r, b)
prop_translationIsLinear :: Property
prop_translationIsLinear = property $ do
    a <- forAll $ Gen.integral (Range.linear 1 100000 :: Range.Range Int)
    b <- forAll $ Gen.integral (Range.linear 1 100000 :: Range.Range Int)
    let rate =
            ExchangeRate
                { rateValue = 150
                , rateKind = ClosingRate
                , rateDate = fromGregorian 2026 3 31
                , rateSource = "TEST"
                }
        ma = mkMoney' (fromIntegral a) :: Money "USD"
        mb = mkMoney' (fromIntegral b) :: Money "USD"
        mab = mkMoney' (fromIntegral (a + b)) :: Money "USD"
        lhs = translateMoney rate mab
        rhs = M.dense' (toRationalMoney (translateMoney rate ma) + toRationalMoney (translateMoney rate mb))
    toRationalMoney lhs === toRationalMoney rhs
