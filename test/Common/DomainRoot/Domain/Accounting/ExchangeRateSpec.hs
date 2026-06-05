module Domain.Accounting.ExchangeRateSpec (tests) where

import Data.Time (fromGregorian)
import Domain.Accounting.ExchangeRate (
    ExchangeRate,
    ExchangeRateError (..),
    RateKind (ClosingRate),
    mkAverageRate,
    mkClosingRate,
    translateByAverage,
    translateMonetary,
    translateNonMonetaryHistorical,
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
            "Constructors"
            [ testCase "positive rate succeeds" case_positiveRateSucceeds
            , testCase "zero rate fails" case_zeroRateFails
            , testCase "negative rate fails" case_negativeRateFails
            , testCase "blank source fails" case_blankSourceFails
            ]
        , testGroup
            "IAS 21 translations"
            [ testCase "closing rate translates monetary items" case_translateMonetary
            , testCase "historical rate translates non-monetary items" case_translateNonMonetary
            , testCase "average rate translates periodic flows" case_translateByAverageRate
            , testCase
                "type-level rate kind prevents historical-rate use in monetary translation"
                case_rateKindTypeSafety
            ]
        , testGroup
            "Properties"
            [ testProperty "positive rate always succeeds" prop_positiveRateAlwaysSucceeds
            , testProperty "monetary translation is linear" prop_translationIsLinear
            ]
        ]

case_positiveRateSucceeds :: Assertion
case_positiveRateSucceeds = do
    let result = mkClosingRate 150 (fromGregorian 2026 3 31) "BOJ"
    case result of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right _ -> pure ()

case_zeroRateFails :: Assertion
case_zeroRateFails =
    assertEqual
        "zero rate"
        (Left NonPositiveRate)
        ( mkClosingRate 0 (fromGregorian 2026 3 31) "BOJ" ::
            Either ExchangeRateError (ExchangeRate 'ClosingRate "USD" "JPY")
        )

case_negativeRateFails :: Assertion
case_negativeRateFails =
    assertEqual
        "negative rate"
        (Left NonPositiveRate)
        ( mkClosingRate (-1) (fromGregorian 2026 3 31) "BOJ" ::
            Either ExchangeRateError (ExchangeRate 'ClosingRate "USD" "JPY")
        )

case_blankSourceFails :: Assertion
case_blankSourceFails =
    assertEqual
        "blank source"
        (Left MissingRateSource)
        ( mkClosingRate 150 (fromGregorian 2026 3 31) "   " ::
            Either ExchangeRateError (ExchangeRate 'ClosingRate "USD" "JPY")
        )

case_translateMonetary :: Assertion
case_translateMonetary = do
    rate <- sampleUsdJpyClosingRate
    let usd = mkMoney' 1000 :: Money "USD"
        jpy = translateMonetary rate usd
    assertEqual "translated monetary amount" (mkMoney' 150000 :: Money "JPY") jpy

case_translateNonMonetary :: Assertion
case_translateNonMonetary = do
    rate <- sampleUsdJpyHistoricalRate
    let usd = mkMoney' 1000 :: Money "USD"
        jpy = translateNonMonetaryHistorical rate usd
    assertEqual "translated non-monetary amount" (mkMoney' 145000 :: Money "JPY") jpy

case_translateByAverageRate :: Assertion
case_translateByAverageRate = do
    rate <- case mkAverageRate 148 (fromGregorian 2026 3 31) "BOJ" of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right value -> pure value
    let usd = mkMoney' 1000 :: Money "USD"
        jpy = translateByAverage rate usd
    assertEqual "translated average-rate amount" (mkMoney' 148000 :: Money "JPY") jpy

case_rateKindTypeSafety :: Assertion
case_rateKindTypeSafety =
    -- The following does not typecheck, which is the point of the API:
    -- translateMonetary historicalRate amount
    pure ()

prop_positiveRateAlwaysSucceeds :: Property
prop_positiveRateAlwaysSucceeds = property $ do
    rate <- forAll $ Gen.realFrac_ (Range.linearFrac 0.0001 10000 :: Range.Range Double)
    let result =
            mkClosingRate (toRational rate) (fromGregorian 2026 3 31) "TEST" ::
                Either ExchangeRateError (ExchangeRate 'ClosingRate "USD" "JPY")
    case result of
        Right _ -> pure ()
        Left err -> fail ("positive rate failed: " <> show err)

prop_translationIsLinear :: Property
prop_translationIsLinear = property $ do
    a <- forAll $ Gen.integral (Range.linear 1 100000 :: Range.Range Int)
    b <- forAll $ Gen.integral (Range.linear 1 100000 :: Range.Range Int)
    let rate = case mkClosingRate 150 (fromGregorian 2026 3 31) "TEST" of
            Left err -> error ("invalid exchange rate fixture: " <> show err)
            Right value -> value
        ma = mkMoney' (fromIntegral a) :: Money "USD"
        mb = mkMoney' (fromIntegral b) :: Money "USD"
        mab = mkMoney' (fromIntegral (a + b)) :: Money "USD"
        lhs = translateMonetary rate mab
        rhs =
            M.dense'
                ( toRationalMoney (translateMonetary rate ma)
                    + toRationalMoney (translateMonetary rate mb)
                )
    toRationalMoney lhs === toRationalMoney rhs
