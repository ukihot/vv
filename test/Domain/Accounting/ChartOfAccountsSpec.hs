module Domain.Accounting.ChartOfAccountsSpec (tests) where

import Domain.Accounting.ChartOfAccounts
    ( ChartError (..)
    , mkAccountCode
    , mkAccountName
    )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)

tests :: TestTree
tests =
    testGroup
        "ChartOfAccounts"
        [ testGroup
            "AccountCode"
            [ testCase "空文字はエラー" case_emptyCodeIsError,
              testCase "非空文字は成功" case_nonEmptyCodeSucceeds
            ],
          testGroup
            "AccountName"
            [ testCase "空文字はエラー" case_emptyNameIsError,
              testCase "非空文字は成功" case_nonEmptyNameSucceeds
            ]
        ]

case_emptyCodeIsError :: Assertion
case_emptyCodeIsError =
    assertEqual "空コードはエラー" (Left EmptyAccountCode) (mkAccountCode "")

case_nonEmptyCodeSucceeds :: Assertion
case_nonEmptyCodeSucceeds =
    case mkAccountCode "1000" of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right _ -> pure ()

case_emptyNameIsError :: Assertion
case_emptyNameIsError =
    assertEqual "空名称はエラー" (Left EmptyAccountName) (mkAccountName "")

case_nonEmptyNameSucceeds :: Assertion
case_nonEmptyNameSucceeds =
    case mkAccountName "現金及び預金" of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right _ -> pure ()
