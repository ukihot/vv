module Domain.IFRS.Spec (tests) where

import Domain.IFRS.FinancialInstrumentSpec qualified as FISpec
import Domain.IFRS.LeaseSpec qualified as LeaseSpec
import Domain.IFRS.RevenueSpec qualified as RevenueSpec
import Test.Tasty (TestTree, testGroup)

tests :: TestTree
tests =
    testGroup
        "Domain.IFRS"
        [ RevenueSpec.tests
        , FISpec.tests
        , LeaseSpec.tests
        ]
