{- | 繰延税金集約ルートエンティティ (IAS 12準拠)
一時差異、繰延税金資産・負債、回収可能性を管理する。
-}
module Domain.IFRS.DeferredTax (
    -- * 集約
    DeferredTaxItem (..),
    TemporaryDifferenceType (..),

    -- * 値オブジェクト
    module Domain.IFRS.DeferredTax.ValueObjects.DeferredTaxItemId,
)
where

import Data.Text (Text)
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)
import Domain.IFRS.DeferredTax.ValueObjects.DeferredTaxItemId
import Domain.IFRS.DeferredTax.ValueObjects.Version (Version)
import Domain.Shared (FiscalYearMonth, Money)
import GHC.TypeLits (Symbol)

data TemporaryDifferenceType
    = DeductibleTemporaryDifference
    | TaxableTemporaryDifference
    deriving stock (Show, Eq, Ord, Enum, Bounded)

data DeferredTaxItem (currency :: Symbol) = DeferredTaxItem
    { dtiId :: DeferredTaxItemId
    , dtiAccountCode :: AccountCode
    , dtiPeriod :: FiscalYearMonth
    , dtiCarryingAmount :: Money currency
    , dtiTaxBase :: Money currency
    , dtiTemporaryDifference :: Money currency
    , dtiDifferenceType :: TemporaryDifferenceType
    , dtiTaxRate :: Rational
    , dtiDeferredTaxAmount :: Money currency
    , dtiRecoverabilityAssessment :: Text
    , dtiVersion :: Version
    }
    deriving stock (Show, Eq)
