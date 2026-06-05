module App.Ports.Query.MasterData where

import Data.Text (Text)
import Data.Time (Day)

class Monad m => FindAccountQuery m where
    executeFindAccount :: Text -> m (Maybe AccountDTO)

class Monad m => ListAccountsQuery m where
    executeListAccounts :: Maybe Text -> m [AccountDTO]

class Monad m => SearchAccountsQuery m where
    executeSearchAccounts :: Text -> m [AccountDTO]

class Monad m => FindExchangeRateQuery m where
    executeFindExchangeRate :: Text -> Text -> Day -> m (Maybe ExchangeRateDTO)

class Monad m => ListExchangeRatesQuery m where
    executeListExchangeRates :: Day -> m [ExchangeRateDTO]

class Monad m => FindTaxRateQuery m where
    executeFindTaxRate :: Text -> Day -> m (Maybe TaxRateDTO)

class Monad m => ListAccountingPoliciesQuery m where
    executeListAccountingPolicies :: Maybe Text -> m [AccountingPolicyDTO]

data AccountDTO
data ExchangeRateDTO
data TaxRateDTO
data AccountingPolicyDTO
