module Domain.IFRS.LeaseSpec (tests) where

import Data.Time (fromGregorian)
import Domain.IFRS.Lease (
    Lease (..),
    LeaseError (..),
    applyLeasePayment,
    computePeriodDepreciation,
    computePeriodInterest,
    mkLeaseId,
    recordLease,
    unLeaseId,
 )
import Domain.Shared (Money, initialVersion, mkMoney', nextVersion, toRationalMoney)
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Support.Accounting.Fixtures (sampleLeaseId)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
    testGroup
        "Lease (IFRS 16)"
        [ testGroup
            "mkLeaseId"
            [ testCase "blank lease id is rejected" case_blankLeaseIdFails
            , testCase "lease id is normalized" case_leaseIdIsTrimmed
            ]
        , testGroup
            "recordLease"
            [ testCase "初度認識: 使用権資産 = リース負債" case_initialRecognitionRouEqLiability
            , testCase "初度認識: 初期バージョン" case_initialVersion
            ]
        , testGroup
            "computePeriodInterest §2.4.6"
            [ testCase "月次利息 = 負債残高 × 年率/12" case_periodInterest
            ]
        , testGroup
            "computePeriodDepreciation §2.4.6"
            [ testCase "月次償却 = 使用権資産 / リース期間" case_periodDepreciation
            ]
        , testGroup
            "applyLeasePayment"
            [ testCase "支払後の負債残高が減少する" case_liabilityDecreases
            , testCase "支払後バージョンが進む" case_versionBumps
            ]
        , testGroup
            "Properties"
            [ testProperty "月次利息は常に非負" prop_interestNonNegative
            , testProperty "月次償却は常に正" prop_depreciationPositive
            ]
        ]

-- ─────────────────────────────────────────────────────────────────────────────
-- フィクスチャ
-- ─────────────────────────────────────────────────────────────────────────────

sampleLease :: IO (Lease "JPY")
sampleLease = do
    lid <- sampleLeaseId
    pure $ recordLease lid (fromGregorian 2026 4 1) 36 0.03 (mkMoney' 3000000)

-- ─────────────────────────────────────────────────────────────────────────────
-- HUnit ケース
-- ─────────────────────────────────────────────────────────────────────────────

case_blankLeaseIdFails :: Assertion
case_blankLeaseIdFails =
    assertEqual "blank lease id" (Left InvalidLeaseId) (mkLeaseId "   ")

case_leaseIdIsTrimmed :: Assertion
case_leaseIdIsTrimmed =
    case mkLeaseId " LS-2026-001 " of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right leaseId -> assertEqual "trimmed lease id" "LS-2026-001" (unLeaseId leaseId)

case_initialRecognitionRouEqLiability :: Assertion
case_initialRecognitionRouEqLiability = do
    l <- sampleLease
    assertEqual
        "使用権資産 = リース負債"
        (leaseRouAsset l)
        (leaseLiability l)

case_initialVersion :: Assertion
case_initialVersion = do
    l <- sampleLease
    assertEqual "初期バージョン" initialVersion (leaseVersion l)

-- 月次利息 = 3,000,000 × 0.03 / 12 = 7,500
case_periodInterest :: Assertion
case_periodInterest = do
    l <- sampleLease
    let interest = computePeriodInterest l
    assertEqual "月次利息" (mkMoney' 7500 :: Money "JPY") interest

-- 月次償却 = 3,000,000 / 36 = 83,333.333...
case_periodDepreciation :: Assertion
case_periodDepreciation = do
    l <- sampleLease
    let deprec = computePeriodDepreciation l
        expected = mkMoney' (3000000 / 36) :: Money "JPY"
    assertEqual "月次償却" expected deprec

-- 支払 90,000 → 利息 7,500 → 元本返済 82,500 → 残高 2,917,500
case_liabilityDecreases :: Assertion
case_liabilityDecreases = do
    l <- sampleLease
    let payment = mkMoney' 90000 :: Money "JPY"
        l' = applyLeasePayment l payment
        expected = mkMoney' 2917500 :: Money "JPY"
    assertEqual "支払後負債残高" expected (leaseLiability l')

case_versionBumps :: Assertion
case_versionBumps = do
    l <- sampleLease
    let l' = applyLeasePayment l (mkMoney' 90000 :: Money "JPY")
    assertEqual "バージョンが進む" (nextVersion initialVersion) (leaseVersion l')

-- ─────────────────────────────────────────────────────────────────────────────
-- Hedgehog プロパティ
-- ─────────────────────────────────────────────────────────────────────────────

prop_interestNonNegative :: Property
prop_interestNonNegative = property $ do
    pv <- forAll $ Gen.integral (Range.linear 1 100000000 :: Range.Range Int)
    term <- forAll $ Gen.integral (Range.linear 1 360 :: Range.Range Int)
    rate <- forAll $ Gen.realFrac_ (Range.linearFrac 0.001 0.2 :: Range.Range Double)
    lid <- case mkLeaseId "LS-TEST" of
        Right l -> pure l
        Left _ -> fail "fixture"
    let l = recordLease lid (fromGregorian 2026 1 1) term (toRational rate) (mkMoney' (fromIntegral pv))
        interest = computePeriodInterest l
    (toRationalMoney interest >= 0) === True

prop_depreciationPositive :: Property
prop_depreciationPositive = property $ do
    pv <- forAll $ Gen.integral (Range.linear 1 100000000 :: Range.Range Int)
    term <- forAll $ Gen.integral (Range.linear 1 360 :: Range.Range Int)
    lid <- case mkLeaseId "LS-TEST" of
        Right l -> pure l
        Left _ -> fail "fixture"
    let l = recordLease lid (fromGregorian 2026 1 1) term 0.03 (mkMoney' (fromIntegral pv))
        deprec = computePeriodDepreciation l
    (toRationalMoney deprec > 0) === True
