module Domain.IFRS.Revenue.Services.PriceAllocation (
    allocateTransactionPrice,
)
where

import Domain.IFRS.Revenue.Entities.PerformanceObligation (
    PerformanceObligation,
    poStandalonePrice,
    withAllocatedPrice,
 )
import Domain.IFRS.Revenue.Errors (RevenueError (..))
import Domain.Shared (Money, scaleMoney, toRationalMoney)

allocateTransactionPrice ::
    Money currency ->
    [PerformanceObligation currency] ->
    Either RevenueError [PerformanceObligation currency]
allocateTransactionPrice txPrice pos
    | any ((<= 0) . toRationalMoney . poStandalonePrice) pos = Left NonPositiveStandalonePrice
    | totalSSP == 0 = Left ZeroStandalonePrice
    | otherwise = traverse allocate pos
    where
        totalSSP = toRationalMoney (sum (map poStandalonePrice pos))
        allocate po =
            let ratio = toRationalMoney (poStandalonePrice po) / totalSSP
             in withAllocatedPrice (scaleMoney ratio txPrice) po
