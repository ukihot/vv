module Domain.IFRS.Lease.Services.LeaseCalculation
    ( computePeriodInterest
    , computePeriodDepreciation
    )
where

import Domain.IFRS.Lease (Lease (..))
import Domain.Shared (Money, scaleMoney)

computePeriodInterest :: Lease currency -> Money currency
computePeriodInterest l =
    scaleMoney (leaseDiscountRate l / 12) (leaseLiability l)

computePeriodDepreciation :: Lease currency -> Money currency
computePeriodDepreciation l =
    scaleMoney (1 / fromIntegral (leaseTerm l)) (leaseRouAsset l)
