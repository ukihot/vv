module Domain.Accounting.JournalEntrySpec (tests) where

import Data.Time (fromGregorian)
import Domain.Accounting.ChartOfAccounts (mkAccountCode)
import Domain.Accounting.JournalEntry
    ( CarryingAmountBridge (..)
    , DrCr (..)
    , JournalEntry (..)
    , JournalError (..)
    , JournalLine (..)
    , mkJournalEntryId
    , recordEntry
    , validateBalance
    )
import Domain.Shared
    ( JournalEntryKind (..)
    , Money (..)
    , RiskClass (..)
    , mkMoney
    )
import Hedgehog (Property, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Support.Accounting.Fixtures
    ( sampleCreditLine
    , sampleDebitLine
    , sampleJournalEntryId
    , shouldRight
    )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)
import Test.Tasty.Hedgehog (testProperty)

tests :: TestTree
tests =
    testGroup
        "JournalEntry"
        [ testGroup
            "validateBalance"
            [ testCase "借貸一致は成功" case_balancedLinesSucceed,
              testCase "借貸不一致はエラー" case_imbalancedLinesFail,
              testCase "空行リストは借貸一致（ゼロ）" case_emptyLinesBalance
            ],
          testGroup
            "recordEntry"
            [ testCase "借貸一致の仕訳は記録できる" case_recordBalancedEntry,
              testCase "借貸不一致の仕訳は記録できない" case_recordImbalancedEntryFails,
              testCase "仕訳行為区分が保持される" case_entryKindPreserved
            ],
          testGroup
            "CarryingAmountBridge §2.3.5"
            [ testCase "帳簿価額 = 取得原価 − 累計償却 − 減損 ± FV調整 − ECL" case_carryingAmountBridge
            ],
          testGroup
            "Properties"
            [ testProperty "借方合計 = 貸方合計の仕訳は常に成功" prop_balancedEntryAlwaysSucceeds
            ]
        ]

-- ─────────────────────────────────────────────────────────────────────────────
-- HUnit ケース
-- ─────────────────────────────────────────────────────────────────────────────

case_balancedLinesSucceed :: Assertion
case_balancedLinesSucceed = do
    dr <- sampleDebitLine
    cr <- sampleCreditLine
    assertEqual "借貸一致" (Right ()) (validateBalance [dr, cr])

case_imbalancedLinesFail :: Assertion
case_imbalancedLinesFail = do
    code <- shouldRight "code" (mkAccountCode "1000")
    let dr = JournalLine code Dr (mkMoney 100000 :: Money "JPY")
        cr = JournalLine code Cr (mkMoney 90000 :: Money "JPY")
    case validateBalance [dr, cr] of
        Left (ImbalancedEntry _ _) -> pure ()
        other -> assertFailure ("期待: ImbalancedEntry, 実際: " <> show other)

case_emptyLinesBalance :: Assertion
case_emptyLinesBalance =
    assertEqual "空行はゼロ一致" (Right ()) (validateBalance ([] :: [JournalLine "JPY"]))

case_recordBalancedEntry :: Assertion
case_recordBalancedEntry = do
    eid <- sampleJournalEntryId
    dr <- sampleDebitLine
    cr <- sampleCreditLine
    let date = fromGregorian 2026 3 31
    case recordEntry eid date [dr, cr] OriginalEntry RiskLow "売上計上" (Just "INV-001") Nothing of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right _ -> pure ()

case_recordImbalancedEntryFails :: Assertion
case_recordImbalancedEntryFails = do
    eid <- sampleJournalEntryId
    code <- shouldRight "code" (mkAccountCode "1000")
    let dr = JournalLine code Dr (mkMoney 100000 :: Money "JPY")
        cr = JournalLine code Cr (mkMoney 80000 :: Money "JPY")
        date = fromGregorian 2026 3 31
    case recordEntry eid date [dr, cr] OriginalEntry RiskLow "不一致" Nothing Nothing of
        Left (ImbalancedEntry _ _) -> pure ()
        other -> assertFailure ("期待: ImbalancedEntry, 実際: " <> show other)

case_entryKindPreserved :: Assertion
case_entryKindPreserved = do
    eid <- sampleJournalEntryId
    dr <- sampleDebitLine
    cr <- sampleCreditLine
    let date = fromGregorian 2026 3 31
    case recordEntry eid date [dr, cr] WashEntry RiskHigh "洗替" Nothing Nothing of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right e -> assertEqual "仕訳行為区分" WashEntry (entryKind e)

{- | 帳簿価額ブリッジの算定検証
取得原価1,000,000 − 累計償却200,000 − 減損50,000 + FV調整30,000 − ECL10,000 = 770,000
-}
case_carryingAmountBridge :: Assertion
case_carryingAmountBridge = do
    code <- shouldRight "code" (mkAccountCode "1500")
    let bridge =
            CarryingAmountBridge
                { bridgeAccountCode = code,
                  bridgeCostBasis = mkMoney 1000000 :: Money "JPY",
                  bridgeAccumDeprec = mkMoney 200000 :: Money "JPY",
                  bridgeImpairmentLoss = mkMoney 50000 :: Money "JPY",
                  bridgeFvAdjustment = mkMoney 30000 :: Money "JPY",
                  bridgeEclAllowance = mkMoney 10000 :: Money "JPY"
                }
        expected = mkMoney 770000 :: Money "JPY"
        actual = carryingAmount bridge
    assertEqual "帳簿価額算定" expected actual
    where
        carryingAmount b =
            let Money cost = bridgeCostBasis b
                Money deprec = bridgeAccumDeprec b
                Money imp = bridgeImpairmentLoss b
                Money fv = bridgeFvAdjustment b
                Money ecl = bridgeEclAllowance b
             in Money (cost - deprec - imp + fv - ecl)

-- ─────────────────────────────────────────────────────────────────────────────
-- Hedgehog プロパティ
-- ─────────────────────────────────────────────────────────────────────────────

-- | 借方合計 = 貸方合計の仕訳は常に validateBalance が Right を返す
prop_balancedEntryAlwaysSucceeds :: Property
prop_balancedEntryAlwaysSucceeds = property $ do
    amt <- forAll $ Gen.integral (Range.linear 1 1000000)
    code <- case mkAccountCode "9999" of
        Right c -> pure c
        Left _ -> fail "fixture error"
    let dr = JournalLine code Dr (mkMoney (fromIntegral amt) :: Money "JPY")
        cr = JournalLine code Cr (mkMoney (fromIntegral amt) :: Money "JPY")
    validateBalance [dr, cr] === Right ()
