{-# LANGUAGE ImportQualifiedPost #-}

{- | 画面レンダリング
各画面の描画ロジックを定義する。
新しい画面を追加する際は、ここに描画関数を追加する。

Components層の再利用可能なコンポーネントを組み合わせて画面を構築する。
-}
module Adapter.View.Brick.Screens (
    renderScreen,
)
where

import Adapter.View.Brick.Types (
    Name (..),
    Screen (..),
    UiState (..),
 )
import Adapter.View.Components.Button (
    renderPrimaryButton,
 )
import Adapter.View.Components.Form (
    renderTextInput,
 )
import Adapter.View.Components.Layout (
    renderCard,
    renderSection,
    renderSpacer,
 )
import Brick (
    Padding (Pad),
    Widget,
    attrName,
    padTop,
    txt,
    vBox,
    withAttr,
 )
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Screen Rendering Dispatcher
-- ─────────────────────────────────────────────────────────────────────────────

renderScreen :: Screen -> UiState -> Widget Name
renderScreen ScreenHome = renderHomeScreen
renderScreen ScreenUserActivate = renderUserActivateScreen
renderScreen ScreenUserList = renderPlaceholderScreen "User List" "ユーザー一覧画面（未実装）"
renderScreen ScreenUserCreate = renderPlaceholderScreen "Create User" "ユーザー登録画面（未実装）"
renderScreen ScreenRoleList = renderPlaceholderScreen "Role List" "ロール一覧画面（未実装）"
renderScreen ScreenRoleCreate = renderPlaceholderScreen "Create Role" "ロール作成画面（未実装）"
renderScreen ScreenPermissionList = renderPlaceholderScreen "Permission List" "権限一覧画面（未実装）"
renderScreen ScreenJournalEntryList = renderPlaceholderScreen "Journal Entry List" "仕訳帳画面（未実装）"
renderScreen ScreenJournalEntryCreate = renderPlaceholderScreen "Create Journal Entry" "仕訳登録画面（未実装）"
renderScreen ScreenChartOfAccounts = renderPlaceholderScreen "Chart of Accounts" "勘定科目体系画面（未実装）"
renderScreen ScreenFiscalPeriodList = renderPlaceholderScreen "Fiscal Period" "会計期間管理画面（未実装）"
renderScreen ScreenTrialBalance = renderPlaceholderScreen "Trial Balance" "試算表画面（未実装）"
renderScreen ScreenGeneralLedger = renderPlaceholderScreen "General Ledger" "総勘定元帳画面（未実装）"
renderScreen ScreenLeaseList = renderPlaceholderScreen "Lease Management" "リース管理画面（未実装）"
renderScreen ScreenRevenueRecognition = renderPlaceholderScreen "Revenue Recognition" "収益認識画面（未実装）"
renderScreen ScreenFinancialInstruments = renderPlaceholderScreen "Financial Instruments" "金融商品画面（未実装）"
renderScreen ScreenBudgetList = renderPlaceholderScreen "Budget Management" "予算管理画面（未実装）"
renderScreen ScreenBankAccountList = renderPlaceholderScreen "Bank Accounts" "銀行口座画面（未実装）"
renderScreen ScreenApprovalWorkflow = renderPlaceholderScreen "Approval Workflow" "承認ワークフロー画面（未実装）"
renderScreen ScreenAuditTrail = renderPlaceholderScreen "Audit Trail" "監査証跡画面（未実装）"
renderScreen ScreenClosingProcess = renderPlaceholderScreen "Closing Process" "決算処理画面（未実装）"
renderScreen ScreenOrganizationSettings = renderPlaceholderScreen "Organization Settings" "組織設定画面（未実装）"

-- ─────────────────────────────────────────────────────────────────────────────
-- Home Screen (Components使用例)
-- ─────────────────────────────────────────────────────────────────────────────

renderHomeScreen :: UiState -> Widget Name
renderHomeScreen _st =
    renderCard (Just "Home") $
        vBox
            [ renderSection "Welcome to VV!" $
                vBox
                    [ txt "IFRS-based Accounting System"
                    , renderSpacer 1
                    , txt "Built with Haskell + Event Sourcing + CQRS"
                    ]
            , renderSpacer 1
            , renderSection "Quick Start" $
                vBox
                    [ txt "• Press 'n' to open navigation menu"
                    , txt "• Press 'Tab' to switch domain tabs"
                    , txt "• Press 'Esc' to go back"
                    , txt "• Press 'q' to quit"
                    ]
            ]

-- ─────────────────────────────────────────────────────────────────────────────
-- User Activate Screen (Components使用例)
-- ─────────────────────────────────────────────────────────────────────────────

renderUserActivateScreen :: UiState -> Widget Name
renderUserActivateScreen st =
    renderCard (Just "User Activation") $
        vBox
            [ renderTextInput "User ID" (uiUserIdEditor st) True
            , padTop (Pad 1) $
                renderPrimaryButton "Activate" "Enter"
            ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Placeholder Screen (未実装画面用)
-- ─────────────────────────────────────────────────────────────────────────────

renderPlaceholderScreen :: String -> String -> UiState -> Widget Name
renderPlaceholderScreen title description _st =
    renderCard (Just (T.pack title)) $
        vBox
            [ txt (T.pack description)
            , renderSpacer 1
            , withAttr (attrName "hint") $ txt "This screen is not yet implemented."
            ]
