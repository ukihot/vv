module Domain.Accounting.Spec (tests) where

import Domain.Accounting.ChartOfAccountsSpec qualified as CoASpec
import Domain.Accounting.ExchangeRateSpec qualified as ERSpec
import Domain.Accounting.FiscalPeriodSpec qualified as FPSpec
import Domain.Accounting.JournalEntrySpec qualified as JESpec
import Test.Tasty (TestTree, testGroup)

tests :: TestTree
tests =
    testGroup
        "Domain.Accounting"
        [ CoASpec.tests,
          FPSpec.tests,
          JESpec.tests,
          ERSpec.tests
        ]
