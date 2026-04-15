module Domain.IFRS.RevenueSpec (tests) where

import Data.Time (fromGregorian)
import Domain.IFRS.Revenue
  ( AllocationMethod (..),
    PerformanceObligation (..),
    PerformanceObligationId (..),
    RevenueError (..),
    RevenueJudgmentLog (..),
    RevenueRecognitionResult (..),
    SatisfactionPattern (..),
    allocateTransactionPrice,
    mkContractId,
    recognizeRevenue,
  )
import Domain.Shared (Money (..), mkMoney, unMoney, zeroMoney)
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Support.Accounting.Fixtures
  ( sampleContractId,
    samplePoId,
    shouldRight,
  )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
  testGroup
    "Revenue (IFRS 15)"
    [ testGroup
        "ContractId"
        [ testCase "有効なIDは成功" case_validContractId
        ],
      testGroup
        "allocateTransactionPrice §4.3.2"
        [ testCase "2履行義務への独立販売価格比率配分" case_allocateTwoObligations,
          testCase "独立販売価格合計ゼロはエラー" case_zeroSspFails,
          testCase "配分後合計 = 取引価格" case_allocationSumsToTransactionPrice
        ],
      testGroup
        "recognizeRevenue §4.3.1 Step5"
        [ testCase "一時点認識の履行義務は収益計上できる" case_recognizeAtPoint,
          testCase "期間認識の履行義務は一時点認識できない" case_cannotRecognizeOverTimeAtPoint
        ],
      testGroup
        "Properties"
        [ testProperty "配分後の各履行義務の合計は取引価格に等しい" prop_allocationPreservesTotal
        ]
    ]

-- ─────────────────────────────────────────────────────────────────────────────
-- フィクスチャ
-- ─────────────────────────────────────────────────────────────────────────────

sampleLog :: IO (RevenueJudgmentLog "JPY")
sampleLog = do
  cid <- sampleContractId
  pure
    RevenueJudgmentLog
      { rjlContractId = cid,
        rjlStep1ContractExists = True,
        rjlStep2ObligationBasis = "ライセンスと保守は別個の財・サービス",
        rjlStep3AllocationMethod = RelativeStandalonePrice,
        rjlStep3VariableConsideration = Nothing,
        rjlStep5ProgressMethod = Nothing,
        rjlJudgmentDate = fromGregorian 2026 3 31
      }

makePO :: PerformanceObligationId -> SatisfactionPattern -> Money "JPY" -> PerformanceObligation "JPY"
makePO pid pat ssp =
  PerformanceObligation
    { poId = pid,
      poDescription = "テスト履行義務",
      poPattern = pat,
      poProgressMethod = Nothing,
      poStandalonePrice = ssp,
      poAllocatedPrice = zeroMoney
    }

-- ─────────────────────────────────────────────────────────────────────────────
-- HUnit ケース
-- ─────────────────────────────────────────────────────────────────────────────

case_validContractId :: Assertion
case_validContractId = do
  cid <- sampleContractId
  pure ()

case_allocateTwoObligations :: Assertion
case_allocateTwoObligations = do
  -- ライセンス SSP=600,000 / 保守 SSP=400,000 → 合計1,000,000
  -- 取引価格 900,000 → ライセンス 540,000 / 保守 360,000
  let po1 = makePO (PerformanceObligationId "PO-LIC") AtPointInTime (mkMoney 600000)
      po2 = makePO (PerformanceObligationId "PO-MNT") AtPointInTime (mkMoney 400000)
      txPrice = mkMoney 900000 :: Money "JPY"
  case allocateTransactionPrice txPrice [po1, po2] of
    Left e -> assertFailure ("予期しないエラー: " <> show e)
    Right pos -> do
      assertEqual "配分数" 2 (length pos)
      assertEqual "ライセンス配分額" (mkMoney 540000) (poAllocatedPrice (head pos))
      assertEqual "保守配分額" (mkMoney 360000) (poAllocatedPrice (pos !! 1))

case_zeroSspFails :: Assertion
case_zeroSspFails = do
  let po = makePO samplePoId AtPointInTime zeroMoney
  case allocateTransactionPrice (mkMoney 100000 :: Money "JPY") [po] of
    Left ZeroStandalonePrice -> pure ()
    other -> assertFailure ("期待: ZeroStandalonePrice, 実際: " <> show other)

case_allocationSumsToTransactionPrice :: Assertion
case_allocationSumsToTransactionPrice = do
  let po1 = makePO (PerformanceObligationId "PO-A") AtPointInTime (mkMoney 300000)
      po2 = makePO (PerformanceObligationId "PO-B") AtPointInTime (mkMoney 700000)
      txPrice = mkMoney 1000000 :: Money "JPY"
  case allocateTransactionPrice txPrice [po1, po2] of
    Left e -> assertFailure ("予期しないエラー: " <> show e)
    Right pos ->
      let total = Money (sum (map (unMoney . poAllocatedPrice) pos))
       in assertEqual "配分合計 = 取引価格" txPrice total

case_recognizeAtPoint :: Assertion
case_recognizeAtPoint = do
  log <- sampleLog
  let po =
        (makePO samplePoId AtPointInTime (mkMoney 500000))
          { poAllocatedPrice = mkMoney 500000
          }
      date = fromGregorian 2026 3 31
  case recognizeRevenue po date log of
    Left e -> assertFailure ("予期しないエラー: " <> show e)
    Right r -> assertEqual "認識額" (mkMoney 500000) (rrrRecognizedAmt r)

case_cannotRecognizeOverTimeAtPoint :: Assertion
case_cannotRecognizeOverTimeAtPoint = do
  log <- sampleLog
  let po =
        (makePO samplePoId OverTime (mkMoney 500000))
          { poAllocatedPrice = mkMoney 500000
          }
      date = fromGregorian 2026 3 31
  case recognizeRevenue po date log of
    Left CannotRecognizeOverTimeObligationAtPoint -> pure ()
    other -> assertFailure ("期待: CannotRecognizeOverTimeObligationAtPoint, 実際: " <> show other)

-- ─────────────────────────────────────────────────────────────────────────────
-- Hedgehog プロパティ
-- ─────────────────────────────────────────────────────────────────────────────

-- | 配分後の各履行義務の合計は取引価格に等しい（有理数精度で厳密）
prop_allocationPreservesTotal :: Property
prop_allocationPreservesTotal = property $ do
  ssp1 <- forAll $ Gen.integral (Range.linear 1 1000000)
  ssp2 <- forAll $ Gen.integral (Range.linear 1 1000000)
  tx <- forAll $ Gen.integral (Range.linear 1 2000000)
  let po1 = makePO (PerformanceObligationId "A") AtPointInTime (mkMoney (fromIntegral ssp1))
      po2 = makePO (PerformanceObligationId "B") AtPointInTime (mkMoney (fromIntegral ssp2))
      txPrice = mkMoney (fromIntegral tx) :: Money "JPY"
  case allocateTransactionPrice txPrice [po1, po2] of
    Left _ -> pure () -- ZeroSsp 等は skip
    Right pos ->
      let total = sum (map (unMoney . poAllocatedPrice) pos)
       in total === unMoney txPrice
