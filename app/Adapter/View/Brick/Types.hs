{-# LANGUAGE ImportQualifiedPost #-}

{- | Brick UI型定義
画面遷移、ナビゲーション、状態管理の型を定義する。
-}
module Adapter.View.Brick.Types (
    -- * UI State
    UiState (..),
    Name (..),

    -- * Navigation
    DomainTab (..),
    Screen (..),
    ScreenStack,
    NavigationState (..),

    -- * Screen Registry
    ScreenInfo (..),
    screenRegistry,
    getScreensByTab,
)
where

import Adapter.Env (Env)
import Adapter.View.Components.LogViewer (LogViewerState, initialLogViewerState)
import App.DTO.Response.IAM (UserListResponse)
import Brick.Widgets.Edit (Editor)
import Control.Concurrent.STM (TVar)
import Data.Text (Text)

data Name
    = UserIdField
    | UserNameField
    | UserEmailField
    | UserRoleField
    | NavigationList
    | TabSelector
    deriving stock (Eq, Ord, Show)

-- ─────────────────────────────────────────────────────────────────────────────
-- Domain Tab (ドメイン集約単位)
-- ─────────────────────────────────────────────────────────────────────────────

data DomainTab
    = TabIAM -- Identity & Access Management
    | TabAccounting -- 会計
    | TabIFRS -- IFRS関連
    | TabOps -- 運用（予算、銀行、承認等）
    | TabAudit -- 監査
    | TabOrg -- 組織
    deriving stock (Eq, Ord, Show, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- Screen (画面定義)
-- ─────────────────────────────────────────────────────────────────────────────

data Screen
    = -- IAM
      ScreenUserList
    | ScreenUserActivate
    | ScreenUserCreate
    | ScreenUserRegister
    | ScreenRoleList
    | ScreenRoleCreate
    | ScreenPermissionList
    | -- Accounting
      ScreenJournalEntryList
    | ScreenJournalEntryCreate
    | ScreenChartOfAccounts
    | ScreenFiscalPeriodList
    | ScreenTrialBalance
    | ScreenGeneralLedger
    | -- IFRS
      ScreenLeaseList
    | ScreenRevenueRecognition
    | ScreenFinancialInstruments
    | -- Ops
      ScreenBudgetList
    | ScreenBankAccountList
    | ScreenApprovalWorkflow
    | -- Audit
      ScreenAuditTrail
    | ScreenClosingProcess
    | -- Org
      ScreenOrganizationSettings
    | -- Home
      ScreenHome
    deriving stock (Eq, Ord, Show)

-- ─────────────────────────────────────────────────────────────────────────────
-- Screen Info (画面メタデータ)
-- ─────────────────────────────────────────────────────────────────────────────

data ScreenInfo = ScreenInfo
    { screenId :: Screen
    , screenTitle :: Text
    , screenTab :: DomainTab
    , screenDescription :: Text
    }
    deriving stock (Eq, Show)

-- ─────────────────────────────────────────────────────────────────────────────
-- Screen Registry (画面レジストリ)
-- 新しい画面を追加する際はここに登録するだけ
-- ─────────────────────────────────────────────────────────────────────────────

screenRegistry :: [ScreenInfo]
screenRegistry =
    [ -- IAM
      ScreenInfo ScreenUserList "User List" TabIAM "ユーザー一覧"
    , ScreenInfo ScreenUserActivate "User Activation" TabIAM "ユーザー有効化"
    , ScreenInfo ScreenUserRegister "Register User" TabIAM "ユーザー登録"
    , ScreenInfo ScreenRoleList "Role List" TabIAM "ロール一覧"
    , ScreenInfo ScreenRoleCreate "Create Role" TabIAM "ロール作成"
    , ScreenInfo ScreenPermissionList "Permission List" TabIAM "権限一覧"
    , -- Accounting
      ScreenInfo ScreenJournalEntryList "Journal Entry List" TabAccounting "仕訳帳"
    , ScreenInfo ScreenJournalEntryCreate "Create Journal Entry" TabAccounting "仕訳登録"
    , ScreenInfo ScreenChartOfAccounts "Chart of Accounts" TabAccounting "勘定科目体系"
    , ScreenInfo ScreenFiscalPeriodList "Fiscal Period" TabAccounting "会計期間管理"
    , ScreenInfo ScreenTrialBalance "Trial Balance" TabAccounting "試算表"
    , ScreenInfo ScreenGeneralLedger "General Ledger" TabAccounting "総勘定元帳"
    , -- IFRS
      ScreenInfo ScreenLeaseList "Lease Management" TabIFRS "リース管理"
    , ScreenInfo ScreenRevenueRecognition "Revenue Recognition" TabIFRS "収益認識"
    , ScreenInfo ScreenFinancialInstruments "Financial Instruments" TabIFRS "金融商品"
    , -- Ops
      ScreenInfo ScreenBudgetList "Budget Management" TabOps "予算管理"
    , ScreenInfo ScreenBankAccountList "Bank Accounts" TabOps "銀行口座"
    , ScreenInfo ScreenApprovalWorkflow "Approval Workflow" TabOps "承認ワークフロー"
    , -- Audit
      ScreenInfo ScreenAuditTrail "Audit Trail" TabAudit "監査証跡"
    , ScreenInfo ScreenClosingProcess "Closing Process" TabAudit "決算処理"
    , -- Org
      ScreenInfo ScreenOrganizationSettings "Organization Settings" TabOrg "組織設定"
    , -- Home
      ScreenInfo ScreenHome "Home" TabIAM "ホーム"
    ]

-- タブごとの画面一覧を取得
getScreensByTab :: DomainTab -> [ScreenInfo]
getScreensByTab tab = filter (\s -> screenTab s == tab) screenRegistry

-- ─────────────────────────────────────────────────────────────────────────────
-- Navigation State (ナビゲーション状態)
-- ─────────────────────────────────────────────────────────────────────────────

type ScreenStack = [Screen]

data NavigationState = NavigationState
    { navCurrentScreen :: Screen
    , navScreenStack :: ScreenStack -- 戻る用のスタック
    , navCurrentTab :: DomainTab
    , navShowNavigation :: Bool -- ナビゲーションメニューの表示/非表示
    }
    deriving stock (Eq, Show)

-- ─────────────────────────────────────────────────────────────────────────────
-- UI State
-- ─────────────────────────────────────────────────────────────────────────────

data UiState = UiState
    { -- 依存環境
      uiEnv :: Env
    , -- ログ（Presenterが更新）
      uiLogs :: TVar [Text]
    , -- ログビューワー状態
      uiLogViewer :: LogViewerState
    , -- ナビゲーション
      uiNavigation :: NavigationState
    , -- 画面固有の状態
      uiUserIdEditor :: Editor Text Name
    , uiUserNameEditor :: Editor Text Name
    , uiUserEmailEditor :: Editor Text Name
    , uiUserRoleEditor :: Editor Text Name
    , -- ユーザー一覧データ
      uiUserList :: Maybe UserListResponse
    , -- フォーカス管理
      uiCurrentFocus :: Name
    , -- ヘルプ表示フラグ
      uiShowHelp :: Bool
    , -- ナビゲーションメニューの選択インデックス
      uiNavSelectedIndex :: Int
    }
