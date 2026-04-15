module App.Ports.Command.MasterData (
    RegisterChartOfAccountsUseCase (..),
    UpdateAccountUseCase (..),
    RegisterExchangeRateUseCase (..),
    ApproveExchangeRateUseCase (..),
    RegisterTaxRateUseCase (..),
    RegisterAccountingPolicyUseCase (..),
    UpdateAccountingPolicyUseCase (..),
)
where

import Data.Text (Text)
import Data.Time (Day)

-- ============================================================================
-- Master Data Management
-- ============================================================================

class Monad m => RegisterChartOfAccountsUseCase m where
    executeRegisterChartOfAccounts :: Text -> Text -> Text -> Text -> m (Either Text Text)

-- code, name, accountClass, accountNature -> accountId

class Monad m => UpdateAccountUseCase m where
    executeUpdateAccount :: Text -> Text -> m (Either Text ()) -- accountId, updates

class Monad m => RegisterExchangeRateUseCase m where
    executeRegisterExchangeRate :: Text -> Text -> Day -> Double -> Text -> m (Either Text Text)

-- fromCurrency, toCurrency, date, rate, source -> rateId

class Monad m => ApproveExchangeRateUseCase m where
    executeApproveExchangeRate :: Text -> Text -> m (Either Text ()) -- rateId, approverId

class Monad m => RegisterTaxRateUseCase m where
    executeRegisterTaxRate :: Text -> Day -> Double -> m (Either Text Text)

-- jurisdiction, effectiveDate, rate -> taxRateId

class Monad m => RegisterAccountingPolicyUseCase m where
    executeRegisterAccountingPolicy :: Text -> Text -> Text -> m (Either Text Text)

-- policyType, description, ifrsReference -> policyId

class Monad m => UpdateAccountingPolicyUseCase m where
    executeUpdateAccountingPolicy :: Text -> Text -> Text -> m (Either Text ())

-- policyId, newDescription, reason
