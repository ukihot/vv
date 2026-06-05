{-# LANGUAGE ImportQualifiedPost #-}

module Fw.AppState (
    AppState (..),
    Name (..),
    DomainTab (..),
    Screen (..),
    ScreenStack,
    NavigationState (..),
    ScreenInfo (..),
    screenRegistry,
    getScreensByTab,
    initialAppState,
) where

import Common.UI.LogViewer (LogViewerState, initialLogViewerState)
import Control.Concurrent.STM (TVar)
import Data.Text (Text)
import Features.IAM.UserActivate.Core qualified as UserActivate
import Features.IAM.UserList.Core qualified as UserList
import Features.IAM.UserRegister.Core qualified as UserRegister
import Fw.Types (Env)

data Name
    = UserActivateIdField
    | UserRegisterNameField
    | UserRegisterEmailField
    | UserRegisterRoleField
    | NavigationList
    | TabSelector
    deriving stock (Eq, Ord, Show)

data DomainTab
    = TabIAM
    | TabAccounting
    | TabIFRS
    | TabOps
    | TabAudit
    | TabOrg
    deriving stock (Eq, Ord, Show, Enum, Bounded)

data Screen
    = ScreenUserList
    | ScreenUserActivate
    | ScreenUserCreate
    | ScreenUserRegister
    | ScreenRoleList
    | ScreenRoleCreate
    | ScreenPermissionList
    | ScreenJournalEntryList
    | ScreenJournalEntryCreate
    | ScreenChartOfAccounts
    | ScreenFiscalPeriodList
    | ScreenTrialBalance
    | ScreenGeneralLedger
    | ScreenLeaseList
    | ScreenRevenueRecognition
    | ScreenFinancialInstruments
    | ScreenBudgetList
    | ScreenBankAccountList
    | ScreenApprovalWorkflow
    | ScreenAuditTrail
    | ScreenClosingProcess
    | ScreenOrganizationSettings
    | ScreenHome
    deriving stock (Eq, Ord, Show)

data ScreenInfo = ScreenInfo
    { screenId :: Screen
    , screenTitle :: Text
    , screenTab :: DomainTab
    , screenDescription :: Text
    }
    deriving stock (Eq, Show)

screenRegistry :: [ScreenInfo]
screenRegistry =
    [ ScreenInfo ScreenUserList "User List" TabIAM "User list"
    , ScreenInfo ScreenUserActivate "User Activation" TabIAM "Activate pending users"
    , ScreenInfo ScreenUserRegister "Register User" TabIAM "Register a new user"
    , ScreenInfo ScreenRoleList "Role List" TabIAM "Role list"
    , ScreenInfo ScreenRoleCreate "Create Role" TabIAM "Create a role"
    , ScreenInfo ScreenPermissionList "Permission List" TabIAM "Permission list"
    , ScreenInfo ScreenJournalEntryList "Journal Entry List" TabAccounting "Journal entries"
    , ScreenInfo ScreenJournalEntryCreate "Create Journal Entry" TabAccounting "Create journal entry"
    , ScreenInfo ScreenChartOfAccounts "Chart of Accounts" TabAccounting "Chart of accounts"
    , ScreenInfo ScreenFiscalPeriodList "Fiscal Period" TabAccounting "Fiscal periods"
    , ScreenInfo ScreenTrialBalance "Trial Balance" TabAccounting "Trial balance"
    , ScreenInfo ScreenGeneralLedger "General Ledger" TabAccounting "General ledger"
    , ScreenInfo ScreenLeaseList "Lease Management" TabIFRS "Lease management"
    , ScreenInfo ScreenRevenueRecognition "Revenue Recognition" TabIFRS "Revenue recognition"
    , ScreenInfo ScreenFinancialInstruments "Financial Instruments" TabIFRS "Financial instruments"
    , ScreenInfo ScreenBudgetList "Budget Management" TabOps "Budget management"
    , ScreenInfo ScreenBankAccountList "Bank Accounts" TabOps "Bank accounts"
    , ScreenInfo ScreenApprovalWorkflow "Approval Workflow" TabOps "Approval workflow"
    , ScreenInfo ScreenAuditTrail "Audit Trail" TabAudit "Audit trail"
    , ScreenInfo ScreenClosingProcess "Closing Process" TabAudit "Closing process"
    , ScreenInfo ScreenOrganizationSettings "Organization Settings" TabOrg "Organization settings"
    , ScreenInfo ScreenHome "Home" TabIAM "Home"
    ]

getScreensByTab :: DomainTab -> [ScreenInfo]
getScreensByTab tab = filter (\s -> screenTab s == tab) screenRegistry

type ScreenStack = [Screen]

data NavigationState = NavigationState
    { navCurrentScreen :: Screen
    , navScreenStack :: ScreenStack
    , navCurrentTab :: DomainTab
    , navShowNavigation :: Bool
    }
    deriving stock (Eq, Show)

data AppState = AppState
    { appEnv :: Env
    , appLogs :: TVar [Text]
    , appLogViewer :: LogViewerState
    , appNavigation :: NavigationState
    , appShowHelp :: Bool
    , appNavSelectedIndex :: Int
    , appUserRegister :: UserRegister.UserRegisterState Name
    , appUserActivate :: UserActivate.UserActivateState Name
    , appUserList :: UserList.UserListState
    }

initialAppState :: Env -> TVar [Text] -> AppState
initialAppState env logsVar =
    AppState
        { appEnv = env
        , appLogs = logsVar
        , appLogViewer = initialLogViewerState
        , appNavigation =
            NavigationState
                { navCurrentScreen = ScreenHome
                , navScreenStack = []
                , navCurrentTab = TabIAM
                , navShowNavigation = False
                }
        , appShowHelp = False
        , appNavSelectedIndex = 0
        , appUserRegister =
            UserRegister.initialState
                UserRegisterNameField
                UserRegisterEmailField
                UserRegisterRoleField
        , appUserActivate = UserActivate.initialState UserActivateIdField
        , appUserList = UserList.initialState
        }
