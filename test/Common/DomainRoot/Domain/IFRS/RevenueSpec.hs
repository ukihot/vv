module Domain.IFRS.RevenueSpec (tests) where

import Data.Text (Text)
import Data.Time (fromGregorian)
import Domain.IFRS.Revenue (
    AllocationMethod (..),
    PerformanceObligation,
    PerformanceObligationId,
    RevenueError (..),
    RevenueJudgmentLog (..),
    RevenueRecognitionResult (..),
    SatisfactionPattern (..),
    allocateTransactionPrice,
    mkPerformanceObligation,
    mkPerformanceObligationId,
    poAllocatedPrice,
    recognizeRevenue,
    unPerformanceObligationId,
 )
import Domain.Shared (Money, mkMoney', toRationalMoney, zeroMoney)
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Money qualified
import Support.Accounting.Fixtures (
    sampleContractId,
    samplePoId,
 )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
    testGroup
        "Revenue (IFRS 15)"
        [ testGroup
            "PerformanceObligationId"
            [ testCase "blank obligation id is rejected" case_blankPoIdFails
            , testCase "obligation id is normalized" case_poIdIsTrimmed
            ]
        , testGroup
            "PerformanceObligation"
            [ testCase "positive SSP succeeds" case_positiveSspSucceeds
            , testCase "zero SSP is rejected" case_zeroSspFails
            , testCase "negative SSP is rejected" case_negativeSspFails
            ]
        , testGroup
            "allocateTransactionPrice"
            [ testCase "allocates transaction price by relative SSP" case_allocateTwoObligations
            , testCase "allocated total equals transaction price" case_allocationSumsToTransactionPrice
            , testCase "empty obligations are rejected" case_emptyObligationsFail
            ]
        , testGroup
            "recognizeRevenue"
            [ testCase "at-point obligation can be recognized" case_recognizeAtPoint
            , testCase
                "over-time obligation cannot be recognized at a point in time"
                case_cannotRecognizeOverTimeAtPoint
            ]
        , testGroup
            "Properties"
            [ testProperty "allocated amounts preserve the transaction price total" prop_allocationPreservesTotal
            ]
        ]

sampleLog :: IO (RevenueJudgmentLog "JPY")
sampleLog = do
    contractId <- sampleContractId
    pure
        RevenueJudgmentLog
            { rjlContractId = contractId
            , rjlStep1ContractExists = True
            , rjlStep2ObligationBasis = "ライセンスと保守は別個の財・サービス"
            , rjlStep3AllocationMethod = RelativeStandalonePrice
            , rjlStep3VariableConsideration = Nothing
            , rjlStep5ProgressMethod = Nothing
            , rjlJudgmentDate = fromGregorian 2026 3 31
            }

makePO ::
    PerformanceObligationId ->
    SatisfactionPattern ->
    Money "JPY" ->
    PerformanceObligation "JPY"
makePO obligationId pattern_ standalonePrice =
    case mkPerformanceObligation obligationId "テスト履行義務" pattern_ Nothing standalonePrice of
        Left err -> error ("invalid performance obligation fixture: " <> show err)
        Right value -> value

case_blankPoIdFails :: Assertion
case_blankPoIdFails =
    assertEqual "blank po id" (Left InvalidPerformanceObligationId) (mkPerformanceObligationId "   ")

case_poIdIsTrimmed :: Assertion
case_poIdIsTrimmed =
    case mkPerformanceObligationId " PO-001 " of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right obligationId -> assertEqual "trimmed po id" "PO-001" (unPerformanceObligationId obligationId)

case_positiveSspSucceeds :: Assertion
case_positiveSspSucceeds =
    case mkPerformanceObligation samplePoId "正のSSP" AtPointInTime Nothing (mkMoney' 100000 :: Money "JPY") of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right _ -> pure ()

case_zeroSspFails :: Assertion
case_zeroSspFails =
    assertEqual
        "zero SSP"
        (Left NonPositiveStandalonePrice)
        (mkPerformanceObligation samplePoId "ゼロSSP" AtPointInTime Nothing (zeroMoney :: Money "JPY"))

case_negativeSspFails :: Assertion
case_negativeSspFails =
    assertEqual
        "negative SSP"
        (Left NonPositiveStandalonePrice)
        (mkPerformanceObligation samplePoId "負のSSP" AtPointInTime Nothing (mkMoney' (-1) :: Money "JPY"))

case_allocateTwoObligations :: Assertion
case_allocateTwoObligations = do
    let po1 = makePO (mkPoId "PO-LIC") AtPointInTime (mkMoney' 600000)
        po2 = makePO (mkPoId "PO-MNT") AtPointInTime (mkMoney' 400000)
        txPrice = mkMoney' 900000 :: Money "JPY"
    case allocateTransactionPrice txPrice [po1, po2] of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right [licensePo, maintenancePo] -> do
            assertEqual "allocation count" 2 (length [licensePo, maintenancePo])
            assertEqual "license allocation" (mkMoney' 540000) (poAllocatedPrice licensePo)
            assertEqual "maintenance allocation" (mkMoney' 360000) (poAllocatedPrice maintenancePo)
        Right other -> assertFailure ("expected 2 obligations, got: " <> show (length other))

case_allocationSumsToTransactionPrice :: Assertion
case_allocationSumsToTransactionPrice = do
    let po1 = makePO (mkPoId "PO-A") AtPointInTime (mkMoney' 300000)
        po2 = makePO (mkPoId "PO-B") AtPointInTime (mkMoney' 700000)
        txPrice = mkMoney' 1000000 :: Money "JPY"
    case allocateTransactionPrice txPrice [po1, po2] of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right obligations ->
            let total = Money.dense' (sum (map (toRationalMoney . poAllocatedPrice) obligations))
             in assertEqual "allocation total" txPrice total

case_emptyObligationsFail :: Assertion
case_emptyObligationsFail =
    assertEqual
        "empty obligations"
        (Left ZeroStandalonePrice)
        (allocateTransactionPrice (mkMoney' 100000 :: Money "JPY") [])

case_recognizeAtPoint :: Assertion
case_recognizeAtPoint = do
    judgmentLog <- sampleLog
    let po = makePO samplePoId AtPointInTime (mkMoney' 500000)
        recognitionDate = fromGregorian 2026 3 31
    case allocateTransactionPrice (mkMoney' 500000 :: Money "JPY") [po] of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right [allocatedPo] -> case recognizeRevenue allocatedPo recognitionDate judgmentLog of
            Left err -> assertFailure ("unexpected error: " <> show err)
            Right result -> assertEqual "recognized amount" (mkMoney' 500000) (rrrRecognizedAmt result)
        Right other -> assertFailure ("expected 1 obligation, got: " <> show (length other))

case_cannotRecognizeOverTimeAtPoint :: Assertion
case_cannotRecognizeOverTimeAtPoint = do
    judgmentLog <- sampleLog
    let po = makePO samplePoId OverTime (mkMoney' 500000)
        recognitionDate = fromGregorian 2026 3 31
    case allocateTransactionPrice (mkMoney' 500000 :: Money "JPY") [po] of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right [allocatedPo] -> case recognizeRevenue allocatedPo recognitionDate judgmentLog of
            Left CannotRecognizeOverTimeObligationAtPoint -> pure ()
            other -> assertFailure ("expected CannotRecognizeOverTimeObligationAtPoint, got: " <> show other)
        Right other -> assertFailure ("expected 1 obligation, got: " <> show (length other))

prop_allocationPreservesTotal :: Property
prop_allocationPreservesTotal = property $ do
    ssp1 <- forAll $ Gen.integral (Range.linear 1 1000000 :: Range.Range Int)
    ssp2 <- forAll $ Gen.integral (Range.linear 1 1000000 :: Range.Range Int)
    tx <- forAll $ Gen.integral (Range.linear 1 2000000 :: Range.Range Int)
    let po1 = makePO (mkPoId "A") AtPointInTime (mkMoney' (fromIntegral ssp1))
        po2 = makePO (mkPoId "B") AtPointInTime (mkMoney' (fromIntegral ssp2))
        txPrice = mkMoney' (fromIntegral tx) :: Money "JPY"
    case allocateTransactionPrice txPrice [po1, po2] of
        Left _ -> pure ()
        Right obligations ->
            let total = sum (map (toRationalMoney . poAllocatedPrice) obligations)
             in total === toRationalMoney txPrice

mkPoId :: Text -> PerformanceObligationId
mkPoId raw =
    case mkPerformanceObligationId raw of
        Left err -> error ("invalid po id fixture: " <> show err)
        Right value -> value
