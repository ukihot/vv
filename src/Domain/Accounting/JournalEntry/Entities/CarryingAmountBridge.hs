module Domain.Accounting.JournalEntry.Entities.CarryingAmountBridge
    ( CarryingAmountBridge (..)
    , carryingAmount
    )
where

import Data.List (foldl')
import Domain.Accounting.ChartOfAccounts.ValueObjects.AccountCode (AccountCode)
import Domain.Shared (Money, addMoney, negateMoney)
import GHC.TypeLits (Symbol)

data CarryingAmountBridge (currency :: Symbol) = CarryingAmountBridge
    { bridgeAccountCode :: AccountCode,
      bridgeCostBasis :: Money currency,
      bridgeAccumDeprec :: Money currency,
      bridgeImpairmentLoss :: Money currency,
      bridgeFvAdjustment :: Money currency,
      bridgeEclAllowance :: Money currency
    }
    deriving (Show, Eq)

carryingAmount :: CarryingAmountBridge currency -> Money currency
carryingAmount b =
    foldl'
        addMoney
        (bridgeCostBasis b)
        [ negateMoney (bridgeAccumDeprec b),
          negateMoney (bridgeImpairmentLoss b),
          bridgeFvAdjustment b,
          negateMoney (bridgeEclAllowance b)
        ]
