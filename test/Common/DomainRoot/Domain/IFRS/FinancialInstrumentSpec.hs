module Domain.IFRS.FinancialInstrumentSpec (tests) where

import Domain.IFRS.FinancialInstrument (
    EclJudgmentLog (..),
    EclParameters,
    EclStage (..),
    EconomicScenario (..),
    FinancialInstrumentError (..),
    SomeFinancialAsset (..),
    classifyStage,
    computeEcl,
    faEclAllowance,
    faStage,
    faVersion,
    mkEclParameters,
    mkFinancialAssetId,
    mkScenarioWeight,
    promoteToStage2,
    recordFinancialAsset,
    unFinancialAssetId,
    updateEclStage,
 )
import Domain.Shared (
    Money,
    Version,
    initialVersion,
    mkMoney',
    nextVersion,
    toRationalMoney,
    zeroMoney,
 )
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Support.Accounting.Fixtures (
    sampleEclParams,
    sampleFinancialAssetId,
 )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
    testGroup
        "FinancialInstrument (IFRS 9)"
        [ testGroup
            "classifyStage"
            [ testCase "0 days overdue with sound credit remains Stage1" case_stage1Normal
            , testCase "31 days overdue moves to Stage2" case_stage2Overdue31
            , testCase "rating deterioration moves to Stage2" case_stage2RatingDeteriorated
            , testCase "91 days overdue moves to Stage3" case_stage3Overdue91
            , testCase "legal default moves to Stage3" case_stage3LegalDefault
            ]
        , testGroup
            "mkEclParameters"
            [ testCase "LGD > 1 is rejected" case_invalidLgd
            , testCase "PD > 1 is rejected" case_invalidPd
            , testCase "discount factor outside (0, 1] is rejected" case_invalidDiscountFactor
            , testCase "scenario weights must sum to 1" case_invalidScenarioWeights
            ]
        , testGroup
            "FinancialAssetId"
            [ testCase "blank asset id is rejected" case_blankAssetIdFails
            , testCase "asset id is normalized" case_assetIdIsTrimmed
            ]
        , testGroup
            "computeEcl"
            [ testCase "Stage1 ECL = EAD x PD12M x LGD" case_eclStage1
            , testCase "Stage2 ECL = EAD x lifetime PD x LGD x DF" case_eclStage2
            , testCase "Stage3 uses the Stage2 formula" case_eclStage3
            , testCase "negative EAD is rejected" case_negativeEad
            ]
        , testGroup
            "recordFinancialAsset"
            [ testCase "initial recognition starts at Stage1 with zero ECL and initial version" case_recordInitial
            ]
        , testGroup
            "updateEclStage"
            [ testCase "stage movement bumps the version" case_updateStageVersionBumps
            , testCase "promoteToStage2 moves Stage1 to Stage2" case_stage1To2
            , testCase "updateEclStage moves Stage2 to Stage3" case_stage2To3
            ]
        , testGroup
            "Properties"
            [ testProperty
                "Stage1 ECL is not greater than Stage2 ECL for identical inputs"
                prop_stage1EclLeStage2Ecl
            ]
        ]

someFaStage :: SomeFinancialAsset currency -> EclStage
someFaStage (SomeFA fa) = faStage fa

someFaVersion :: SomeFinancialAsset currency -> Version
someFaVersion (SomeFA fa) = faVersion fa

case_stage1Normal :: Assertion
case_stage1Normal = assertEqual "Stage1" Stage1 (classifyStage 0 False False)

case_stage2Overdue31 :: Assertion
case_stage2Overdue31 = assertEqual "Stage2" Stage2 (classifyStage 31 False False)

case_stage2RatingDeteriorated :: Assertion
case_stage2RatingDeteriorated = assertEqual "Stage2" Stage2 (classifyStage 0 True False)

case_stage3Overdue91 :: Assertion
case_stage3Overdue91 = assertEqual "Stage3" Stage3 (classifyStage 91 False False)

case_stage3LegalDefault :: Assertion
case_stage3LegalDefault = assertEqual "Stage3" Stage3 (classifyStage 0 False True)

case_invalidLgd :: Assertion
case_invalidLgd =
    assertEqual
        "invalid lgd"
        (Left InvalidLgd)
        ( mkValidatedParams
            0.01
            0.05
            1.5
            0.95
            [(0.6, BaseScenario), (0.2, OptimisticScenario), (0.2, PessimisticScenario)]
        )

case_invalidPd :: Assertion
case_invalidPd =
    assertEqual
        "invalid pd"
        (Left InvalidPd)
        ( mkValidatedParams
            1.2
            0.05
            0.45
            0.95
            [(0.6, BaseScenario), (0.2, OptimisticScenario), (0.2, PessimisticScenario)]
        )

case_invalidDiscountFactor :: Assertion
case_invalidDiscountFactor =
    assertEqual
        "invalid discount factor"
        (Left InvalidDiscountFactor)
        ( mkValidatedParams
            0.01
            0.05
            0.45
            1.2
            [(0.6, BaseScenario), (0.2, OptimisticScenario), (0.2, PessimisticScenario)]
        )

case_invalidScenarioWeights :: Assertion
case_invalidScenarioWeights =
    assertEqual
        "invalid scenario weights"
        (Left InvalidScenarioWeights)
        (mkValidatedParams 0.01 0.05 0.45 0.95 [(0.7, BaseScenario), (0.2, OptimisticScenario)])

case_blankAssetIdFails :: Assertion
case_blankAssetIdFails =
    assertEqual "blank asset id" (Left InvalidAssetId) (mkFinancialAssetId "   ")

case_assetIdIsTrimmed :: Assertion
case_assetIdIsTrimmed =
    case mkFinancialAssetId " FA-2026-001 " of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right fid -> assertEqual "trimmed asset id" "FA-2026-001" (unFinancialAssetId fid)

case_eclStage1 :: Assertion
case_eclStage1 = do
    let ead = mkMoney' 1000000 :: Money "JPY"
        expected = mkMoney' 4500 :: Money "JPY"
    case computeEcl Stage1 ead sampleEclParams of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right value -> assertEqual "Stage1 ECL" expected value

case_eclStage2 :: Assertion
case_eclStage2 = do
    let ead = mkMoney' 1000000 :: Money "JPY"
        expected = mkMoney' 21375 :: Money "JPY"
    case computeEcl Stage2 ead sampleEclParams of
        Left err -> assertFailure ("unexpected error: " <> show err)
        Right value -> assertEqual "Stage2 ECL" expected value

case_eclStage3 :: Assertion
case_eclStage3 = do
    let ead = mkMoney' 1000000 :: Money "JPY"
    case (computeEcl Stage2 ead sampleEclParams, computeEcl Stage3 ead sampleEclParams) of
        (Right stage2Ecl, Right stage3Ecl) -> assertEqual "Stage3 formula" stage2Ecl stage3Ecl
        other -> assertFailure ("unexpected error: " <> show other)

case_negativeEad :: Assertion
case_negativeEad = do
    let ead = mkMoney' (-1000000) :: Money "JPY"
    case computeEcl Stage1 ead sampleEclParams of
        Left NegativeEad -> pure ()
        other -> assertFailure ("expected NegativeEad, got: " <> show other)

case_recordInitial :: Assertion
case_recordInitial = do
    fid <- sampleFinancialAssetId
    let asset = recordFinancialAsset fid (mkMoney' 500000 :: Money "JPY") 0.05
    assertEqual "initial stage" Stage1 (faStage asset)
    assertEqual "initial ecl" zeroMoney (faEclAllowance asset)
    assertEqual "initial version" initialVersion (faVersion asset)

case_updateStageVersionBumps :: Assertion
case_updateStageVersionBumps = do
    fid <- sampleFinancialAssetId
    let asset = recordFinancialAsset fid (mkMoney' 500000 :: Money "JPY") 0.05
        newEcl = mkMoney' 21375 :: Money "JPY"
        (asset', _) = updateEclStage (SomeFA asset) Stage2 newEcl
    assertEqual "version bump" (nextVersion initialVersion) (someFaVersion asset')

case_stage1To2 :: Assertion
case_stage1To2 = do
    fid <- sampleFinancialAssetId
    let asset = recordFinancialAsset fid (mkMoney' 500000 :: Money "JPY") 0.05
        newEcl = mkMoney' 21375 :: Money "JPY"
        (asset', log') = promoteToStage2 asset newEcl
    assertEqual "new stage" Stage2 (faStage asset')
    assertEqual "previous stage in log" Stage1 (ejlPreviousStage log')
    assertEqual "new stage in log" Stage2 (ejlNewStage log')

case_stage2To3 :: Assertion
case_stage2To3 = do
    fid <- sampleFinancialAssetId
    let asset0 = recordFinancialAsset fid (mkMoney' 500000 :: Money "JPY") 0.05
        (asset1, _) = promoteToStage2 asset0 (mkMoney' 21375)
        (asset2, _) = updateEclStage (SomeFA asset1) Stage3 (mkMoney' 21375)
    assertEqual "Stage3" Stage3 (someFaStage asset2)

prop_stage1EclLeStage2Ecl :: Property
prop_stage1EclLeStage2Ecl = property $ do
    ead <- forAll $ Gen.integral (Range.linear 1 10000000 :: Range.Range Int)
    let eadMoney = mkMoney' (fromIntegral ead) :: Money "JPY"
    case (computeEcl Stage1 eadMoney sampleEclParams, computeEcl Stage2 eadMoney sampleEclParams) of
        (Right stage1Ecl, Right stage2Ecl) ->
            (toRationalMoney stage1Ecl <= toRationalMoney stage2Ecl) === True
        _ -> pure ()

mkValidatedParams ::
    Rational ->
    Rational ->
    Rational ->
    Rational ->
    [(Rational, EconomicScenario)] ->
    Either FinancialInstrumentError EclParameters
mkValidatedParams pd12 pdLife lossGivenDefault df weights = do
    validatedWeights <- traverse mkWeight weights
    mkEclParameters pd12 pdLife lossGivenDefault df validatedWeights
    where
        mkWeight (weight, scenario) = do
            validatedWeight <- mkScenarioWeight weight
            pure (scenario, validatedWeight)
