{-# LANGUAGE ImportQualifiedPost #-}

{- | 画面レンダリング（ファサード）
各画面の描画ロジックを個別モジュールに委譲する。
新しい画面を追加する際は、Screen/以下にモジュールを作成し、ここでimportして委譲する。

ファサードパターンにより、画面ごとの責務を分離し、保守性を向上させる。
-}
module Adapter.View.Brick.Screens (
    renderScreen,
)
where

import Adapter.View.Brick.Screen.Home (renderHomeScreen)
import Adapter.View.Brick.Screen.IAM.UserActivate (renderUserActivateScreen)
import Adapter.View.Brick.Screen.IAM.UserList (renderUserListScreen)
import Adapter.View.Brick.Screen.IAM.UserRegister (renderUserRegisterScreen)
import Adapter.View.Brick.Screen.Placeholder (renderPlaceholderScreen)
import Adapter.View.Brick.Types (
    Name (..),
    Screen (..),
    UiState (..),
 )
import Brick (Widget)

-- ─────────────────────────────────────────────────────────────────────────────
-- Screen Rendering Dispatcher (ファサード)
-- ─────────────────────────────────────────────────────────────────────────────

renderScreen :: Screen -> UiState -> Widget Name
renderScreen ScreenHome = renderHomeScreen
renderScreen ScreenUserActivate = renderUserActivateScreen
renderScreen ScreenUserList = renderUserListScreen
renderScreen ScreenUserRegister = renderUserRegisterScreen
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
