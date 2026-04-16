module Domain.IFRS.Revenue.Services.PriceAllocation (
    allocateTransactionPrice,
)
where

import Domain.IFRS.Revenue.Entities.PerformanceObligation (PerformanceObligation (..))
import Domain.IFRS.Revenue.Errors (RevenueError (..))
import Domain.Shared (Money, scaleMoney, unMoney)

allocateTransactionPrice ::
    Money currency ->
    [PerformanceObligation currency] ->
    Either RevenueError [PerformanceObligation currency]
allocateTransactionPrice txPrice pos
    | totalSSP == 0 = Left ZeroStandalonePrice
    | otherwise = Right (map allocate pos)
    where
        -- mconcat が使えるのは Money が Monoid インスタンスを持つため（Domain.Shared §Semigroup）
        totalSSP = unMoney (mconcat (map poStandalonePrice pos))
        allocate po =
            let ratio = unMoney (poStandalonePrice po) / totalSSP
             in po {poAllocatedPrice = scaleMoney ratio txPrice}
