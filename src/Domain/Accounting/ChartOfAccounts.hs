{- | 勘定科目体系集約ルートエンティティ
IFRS の財務諸表表示区分と勘定科目を型安全に管理する。
-}
module Domain.Accounting.ChartOfAccounts
    ( -- * 集約
      Account (..)

      -- * 値オブジェクト
    , module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode
    , module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountName
    , module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountClass
    , module Domain.Accounting.ChartOfAccounts.ValueObjects.AccountNature
    , module Domain.Accounting.ChartOfAccounts.ValueObjects.StatementSection
    )
where

import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountClass
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountName
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountNature
import Domain.Accounting.ChartOfAccounts.ValueObjects.StatementSection

data Account = Account
    { accountCode :: AccountCode,
      accountName :: AccountName,
      accountClass :: AccountClass,
      accountNature :: AccountNature,
      accountSection :: StatementSection,
      accountCNC :: CurrentNonCurrent
    }
    deriving (Show, Eq)
