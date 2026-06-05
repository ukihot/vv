module Domain.Accounting.ChartOfAccountsSpec (tests) where

import Domain.Accounting.ChartOfAccounts (
    ChartError (..),
    mkAccountCode,
    mkAccountName,
    unAccountCode,
    unAccountName,
 )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion, assertEqual, assertFailure, testCase)

tests :: TestTree
tests =
    testGroup
        "ChartOfAccounts"
        [ testGroup
            "AccountCode"
            [ testCase "空文字はエラー" case_emptyCodeIsError
            , testCase "空白文字だけはエラー" case_blankCodeIsError
            , testCase "非空文字は成功" case_nonEmptyCodeSucceeds
            , testCase "前後の空白は正規化される" case_codeIsTrimmed
            ]
        , testGroup
            "AccountName"
            [ testCase "空文字はエラー" case_emptyNameIsError
            , testCase "空白文字だけはエラー" case_blankNameIsError
            , testCase "非空文字は成功" case_nonEmptyNameSucceeds
            , testCase "前後の空白は正規化される" case_nameIsTrimmed
            ]
        ]

case_emptyCodeIsError :: Assertion
case_emptyCodeIsError =
    assertEqual "空コードはエラー" (Left EmptyAccountCode) (mkAccountCode "")

case_blankCodeIsError :: Assertion
case_blankCodeIsError =
    assertEqual "空白コードはエラー" (Left EmptyAccountCode) (mkAccountCode "   ")

case_nonEmptyCodeSucceeds :: Assertion
case_nonEmptyCodeSucceeds =
    case mkAccountCode "1000" of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right _ -> pure ()

case_codeIsTrimmed :: Assertion
case_codeIsTrimmed =
    case mkAccountCode " 1000 " of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right code -> assertEqual "trimmed code" "1000" (unAccountCode code)

case_emptyNameIsError :: Assertion
case_emptyNameIsError =
    assertEqual "空名称はエラー" (Left EmptyAccountName) (mkAccountName "")

case_blankNameIsError :: Assertion
case_blankNameIsError =
    assertEqual "空白名称はエラー" (Left EmptyAccountName) (mkAccountName "   ")

case_nonEmptyNameSucceeds :: Assertion
case_nonEmptyNameSucceeds =
    case mkAccountName "現金及び預金" of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right _ -> pure ()

case_nameIsTrimmed :: Assertion
case_nameIsTrimmed =
    case mkAccountName " 現金及び預金 " of
        Left e -> assertFailure ("予期しないエラー: " <> show e)
        Right name -> assertEqual "trimmed name" "現金及び預金" (unAccountName name)
