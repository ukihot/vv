module Domain.Accounting.FiscalPeriodSpec (tests) where

import Domain.Accounting.FiscalPeriod
    ( FiscalPeriod (..)
    , FiscalPeriodEvent (..)
    , lockPeriod
    , openPeriod
    , reopenPeriod
    )
import Domain.Shared (Version (..), initialVersion, nextVersion)
import Support.Accounting.Fixtures (sampleFiscalPeriodId, sampleFiscalYearMonth)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, testCase)

tests :: TestTree
tests =
    testGroup
        "FiscalPeriod"
        [ testGroup
            "Factory"
            [ testCase "openPeriod は Open 状態で初期バージョンを持つ" case_openPeriodSeeds
            ],
          testGroup
            "Transitions"
            [ testCase "lockPeriod は Open → Locked へ遷移しバージョンを進める" case_lockPeriod,
              testCase "reopenPeriod は Locked → Open へ遷移しバージョンを進める" case_reopenPeriod,
              testCase "open → lock → reopen でバージョンが2になる" case_fullCycleVersion
            ]
        ]

case_openPeriodSeeds :: Assertion
case_openPeriodSeeds = do
    pid <- sampleFiscalPeriodId
    let (fp, ev) = openPeriod pid sampleFiscalYearMonth
    case fp of
        FPOpen _ ym v -> do
            assertEqual "会計期間が一致" sampleFiscalYearMonth ym
            assertEqual "初期バージョン" initialVersion v
    assertEqual "イベント種別" (PeriodOpened pid sampleFiscalYearMonth) ev

case_lockPeriod :: Assertion
case_lockPeriod = do
    pid <- sampleFiscalPeriodId
    let (fp, _) = openPeriod pid sampleFiscalYearMonth
        (locked, ev) = lockPeriod fp
    case locked of
        FPLocked _ ym v -> do
            assertEqual "会計期間が保持" sampleFiscalYearMonth ym
            assertEqual "バージョンが進む" (nextVersion initialVersion) v
    assertEqual "ロックイベント" (PeriodLocked pid sampleFiscalYearMonth) ev

case_reopenPeriod :: Assertion
case_reopenPeriod = do
    pid <- sampleFiscalPeriodId
    let (fp, _) = openPeriod pid sampleFiscalYearMonth
        (locked, _) = lockPeriod fp
        (reopened, ev) = reopenPeriod locked
    case reopened of
        FPOpen _ _ v ->
            assertEqual "バージョンが進む" (Version 2) v
    assertEqual "再オープンイベント" (PeriodReopened pid sampleFiscalYearMonth) ev

case_fullCycleVersion :: Assertion
case_fullCycleVersion = do
    pid <- sampleFiscalPeriodId
    let (fp, _) = openPeriod pid sampleFiscalYearMonth
        (locked, _) = lockPeriod fp
        (reopened, _) = reopenPeriod locked
    case reopened of
        FPOpen _ _ v -> assertEqual "2サイクル後バージョン=2" (Version 2) v
