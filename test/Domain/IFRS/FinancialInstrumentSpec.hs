module Domain.IFRS.FinancialInstrumentSpec (tests) where

import Domain.IFRS.FinancialInstrument
  ( EclJudgmentLog (..),
    EclParameters (..),
    EclStage (..),
    FinancialAsset (..),
    FinancialInstrumentError (..),
    classifyStage,
    computeEcl,
    mkFinancialAssetId,
    recordFinancialAsset,
    updateEclStage,
  )
import Domain.Shared (Money (..), initialVersion, mkMoney, nextVersion, unMoney, zeroMoney)
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Support.Accounting.Fixtures
  ( sampleEclParams,
    sampleFinancialAssetId,
    shouldRight,
  )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
  testGroup
    "FinancialInstrument (IFRS 9)"
    [ testGroup
        "classifyStage §4.7.6"
        [ testCase "期日経過0日・格付正常 → Stage1" case_stage1Normal,
          testCase "期日経過31日 → Stage2" case_stage2Overdue31,
          testCase "格付著しく低下 → Stage2" case_stage2RatingDeteriorated,
          testCase "期日経過91日 → Stage3" case_stage3Overdue91,
          testCase "法的倒産 → Stage3" case_stage3LegalDefault
        ],
      testGroup
        "computeEcl §4.7.7"
        [ testCase "Stage1: ECL = EAD × PD(12M) × LGD" case_eclStage1,
          testCase "Stage2: ECL = EAD × PD(Lifetime) × LGD × DF" case_eclStage2,
          testCase "Stage3: Stage2と同じ算式（信用調整済み実効金利継続）" case_eclStage3,
          testCase "LGD > 1 はエラー" case_invalidLgd
        ],
      testGroup
        "recordFinancialAsset"
        [ testCase "初度認識: Stage1・ECLゼロ・初期バージョン" case_recordInitial
        ],
      testGroup
        "updateEclStage"
        [ testCase "Stage移動でバージョンが進む" case_updateStageVersionBumps,
          testCase "Stage1→Stage2への移動" case_stage1To2,
          testCase "Stage2→Stage3への移動" case_stage2To3
        ],
      testGroup
        "Properties"
        [ testProperty "Stage1 ECL ≤ Stage2 ECL (同一EAD・パラメータ)" prop_stage1EclLeStage2Ecl
        ]
    ]

-- ─────────────────────────────────────────────────────────────────────────────
-- HUnit ケース
-- ─────────────────────────────────────────────────────────────────────────────

case_stage1Normal :: Assertion
case_stage1Normal =
  assertEqual "Stage1" Stage1 (classifyStage 0 False False)

case_stage2Overdue31 :: Assertion
case_stage2Overdue31 =
  assertEqual "Stage2" Stage2 (classifyStage 31 False False)

case_stage2RatingDeteriorated :: Assertion
case_stage2RatingDeteriorated =
  assertEqual "Stage2" Stage2 (classifyStage 0 True False)

case_stage3Overdue91 :: Assertion
case_stage3Overdue91 =
  assertEqual "Stage3" Stage3 (classifyStage 91 False False)

case_stage3LegalDefault :: Assertion
case_stage3LegalDefault =
  assertEqual "Stage3" Stage3 (classifyStage 0 False True)

-- Stage1: ECL = 1,000,000 × 0.01 × 0.45 = 4,500
case_eclStage1 :: Assertion
case_eclStage1 = do
  let ead = mkMoney 1000000 :: Money "JPY"
      expected = mkMoney 4500 :: Money "JPY"
  case computeEcl Stage1 ead sampleEclParams of
    Left e -> assertFailure ("予期しないエラー: " <> show e)
    Right r -> assertEqual "Stage1 ECL" expected r

-- Stage2: ECL = 1,000,000 × 0.05 × 0.45 × 0.95 = 21,375
case_eclStage2 :: Assertion
case_eclStage2 = do
  let ead = mkMoney 1000000 :: Money "JPY"
      expected = mkMoney 21375 :: Money "JPY"
  case computeEcl Stage2 ead sampleEclParams of
    Left e -> assertFailure ("予期しないエラー: " <> show e)
    Right r -> assertEqual "Stage2 ECL" expected r

-- Stage3: 同じ算式
case_eclStage3 :: Assertion
case_eclStage3 = do
  let ead = mkMoney 1000000 :: Money "JPY"
  case (computeEcl Stage2 ead sampleEclParams, computeEcl Stage3 ead sampleEclParams) of
    (Right s2, Right s3) -> assertEqual "Stage3 = Stage2 算式" s2 s3
    other -> assertFailure ("予期しないエラー: " <> show other)

case_invalidLgd :: Assertion
case_invalidLgd = do
  let ead = mkMoney 1000000 :: Money "JPY"
      params = sampleEclParams {lgd = 1.5}
  case computeEcl Stage1 ead params of
    Left InvalidLgd -> pure ()
    other -> assertFailure ("期待: InvalidLgd, 実際: " <> show other)

case_recordInitial :: Assertion
case_recordInitial = do
  fid <- sampleFinancialAssetId
  let fa = recordFinancialAsset fid (mkMoney 500000 :: Money "JPY") 0.05
  assertEqual "初期ステージ" Stage1 (faStage fa)
  assertEqual "初期ECL" zeroMoney (faEclAllowance fa)
  assertEqual "初期バージョン" initialVersion (faVersion fa)

case_updateStageVersionBumps :: Assertion
case_updateStageVersionBumps = do
  fid <- sampleFinancialAssetId
  let fa = recordFinancialAsset fid (mkMoney 500000 :: Money "JPY") 0.05
      newEcl = mkMoney 21375 :: Money "JPY"
      (fa', _) = updateEclStage fa Stage2 newEcl
  assertEqual "バージョンが進む" (nextVersion initialVersion) (faVersion fa')

case_stage1To2 :: Assertion
case_stage1To2 = do
  fid <- sampleFinancialAssetId
  let fa = recordFinancialAsset fid (mkMoney 500000 :: Money "JPY") 0.05
      newEcl = mkMoney 21375 :: Money "JPY"
      (fa', log') = updateEclStage fa Stage2 newEcl
  assertEqual "新ステージ" Stage2 (faStage fa')
  assertEqual "ログ: 旧ステージ" Stage1 (ejlPreviousStage log')
  assertEqual "ログ: 新ステージ" Stage2 (ejlNewStage log')

case_stage2To3 :: Assertion
case_stage2To3 = do
  fid <- sampleFinancialAssetId
  let fa0 = recordFinancialAsset fid (mkMoney 500000 :: Money "JPY") 0.05
      (fa1, _) = updateEclStage fa0 Stage2 (mkMoney 21375)
      (fa2, _) = updateEclStage fa1 Stage3 (mkMoney 21375)
  assertEqual "Stage3へ移動" Stage3 (faStage fa2)

-- ─────────────────────────────────────────────────────────────────────────────
-- Hedgehog プロパティ
-- ─────────────────────────────────────────────────────────────────────────────

-- | Stage1 ECL ≤ Stage2 ECL (PD12M ≤ PDLifetime かつ DF ≤ 1 の場合)
prop_stage1EclLeStage2Ecl :: Property
prop_stage1EclLeStage2Ecl = property $ do
  ead <- forAll $ Gen.integral (Range.linear 1 10000000)
  let eadMoney = mkMoney (fromIntegral ead) :: Money "JPY"
  case (computeEcl Stage1 eadMoney sampleEclParams, computeEcl Stage2 eadMoney sampleEclParams) of
    (Right s1, Right s2) ->
      -- Stage1 = EAD × 0.01 × 0.45 = EAD × 0.0045
      -- Stage2 = EAD × 0.05 × 0.45 × 0.95 = EAD × 0.021375
      -- Stage1 < Stage2 は常に成立
      (unMoney s1 <= unMoney s2) === True
    _ -> pure ()
