{-# LANGUAGE ImportQualifiedPost #-}

module Fw.Screens (
    renderScreen,
) where

import Brick (Widget)
import Features.Home.UI qualified as Home
import Features.IAM.UserActivate.UI qualified as UserActivate
import Features.IAM.UserList.UI qualified as UserList
import Features.IAM.UserRegister.UI qualified as UserRegister
import Features.Placeholder.UI qualified as Placeholder
import Fw.AppState (
    AppState (..),
    Name,
    Screen (..),
 )

renderScreen :: Screen -> AppState -> Widget Name
renderScreen ScreenHome _ = Home.draw
renderScreen ScreenUserActivate state = UserActivate.draw (appUserActivate state)
renderScreen ScreenUserList state = UserList.draw (appUserList state)
renderScreen ScreenUserRegister state = UserRegister.draw (appUserRegister state)
renderScreen ScreenUserCreate _ = Placeholder.draw "Create User" "User creation screen is not implemented."
renderScreen ScreenRoleList _ = Placeholder.draw "Role List" "Role list screen is not implemented."
renderScreen ScreenRoleCreate _ = Placeholder.draw "Create Role" "Role creation screen is not implemented."
renderScreen ScreenPermissionList _ = Placeholder.draw "Permission List" "Permission list screen is not implemented."
renderScreen ScreenJournalEntryList _ = Placeholder.draw "Journal Entry List" "Journal entry list screen is not implemented."
renderScreen ScreenJournalEntryCreate _ = Placeholder.draw "Create Journal Entry" "Journal entry creation screen is not implemented."
renderScreen ScreenChartOfAccounts _ = Placeholder.draw "Chart of Accounts" "Chart of accounts screen is not implemented."
renderScreen ScreenFiscalPeriodList _ = Placeholder.draw "Fiscal Period" "Fiscal period screen is not implemented."
renderScreen ScreenTrialBalance _ = Placeholder.draw "Trial Balance" "Trial balance screen is not implemented."
renderScreen ScreenGeneralLedger _ = Placeholder.draw "General Ledger" "General ledger screen is not implemented."
renderScreen ScreenLeaseList _ = Placeholder.draw "Lease Management" "Lease management screen is not implemented."
renderScreen ScreenRevenueRecognition _ = Placeholder.draw "Revenue Recognition" "Revenue recognition screen is not implemented."
renderScreen ScreenFinancialInstruments _ = Placeholder.draw "Financial Instruments" "Financial instruments screen is not implemented."
renderScreen ScreenBudgetList _ = Placeholder.draw "Budget Management" "Budget management screen is not implemented."
renderScreen ScreenBankAccountList _ = Placeholder.draw "Bank Accounts" "Bank account screen is not implemented."
renderScreen ScreenApprovalWorkflow _ = Placeholder.draw "Approval Workflow" "Approval workflow screen is not implemented."
renderScreen ScreenAuditTrail _ = Placeholder.draw "Audit Trail" "Audit trail screen is not implemented."
renderScreen ScreenClosingProcess _ = Placeholder.draw "Closing Process" "Closing process screen is not implemented."
renderScreen ScreenOrganizationSettings _ = Placeholder.draw "Organization Settings" "Organization settings screen is not implemented."
