module Domain.Accounting.ExchangeRate.Services.Translation (
    translateMoney,
    translateMoneyApprox,
)
where

import Domain.Accounting.ExchangeRate (ExchangeRate (..))
import Domain.Shared (Money (..), mkMoney)

translateMoney ::
    ExchangeRate from to ->
    Money from ->
    Money to
translateMoney er m = mkMoney (unMoney m * rateValue er)

translateMoneyApprox ::
    ExchangeRate from to ->
    Money from ->
    Money to
translateMoneyApprox = translateMoney
