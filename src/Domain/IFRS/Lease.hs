{- | リース集約ルートエンティティ (IFRS 16準拠)
使用権資産とリース負債を型安全に管理し、
利息費用・償却の計算を保証する。
-}
module Domain.IFRS.Lease (
    -- * 集約
    Lease (..),

    -- * 値オブジェクト
    LeaseId (..),
    mkLeaseId,

    -- * エラー
    LeaseError (..),

    -- * 状態遷移
    recordLease,
    applyLeasePayment,

    -- * サービス
    computePeriodInterest,
    computePeriodDepreciation,
)
where

import Data.Time (Day)
import Domain.IFRS.Lease.Errors (LeaseError (..))
import Domain.IFRS.Lease.ValueObjects.LeaseId (LeaseId (..), mkLeaseId)
import Domain.IFRS.Lease.ValueObjects.Version (Version, initialVersion, nextVersion)
import Domain.Shared (Money, scaleMoney, subMoney, zeroMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- リース集約
-- ─────────────────────────────────────────────────────────────────────────────

data Lease (currency :: Symbol) = Lease
    { leaseId :: LeaseId
    , leaseCommencementDate :: Day
    , leaseTerm :: Int
    , leaseDiscountRate :: Rational
    , leaseRouAsset :: Money currency
    , leaseLiability :: Money currency
    , leaseAccumDeprec :: Money currency
    , leaseVersion :: Version
    }
    deriving stock (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

recordLease ::
    LeaseId ->
    Day ->
    Int ->
    Rational ->
    Money currency ->
    Lease currency
recordLease lid date term rate pv =
    Lease
        { leaseId = lid
        , leaseCommencementDate = date
        , leaseTerm = term
        , leaseDiscountRate = rate
        , leaseRouAsset = pv
        , leaseLiability = pv
        , leaseAccumDeprec = zeroMoney
        , leaseVersion = initialVersion
        }

applyLeasePayment ::
    Lease currency ->
    Money currency ->
    Lease currency
applyLeasePayment l payment =
    let interest = scaleMoney (leaseDiscountRate l / 12) (leaseLiability l)
        principalRepayment = subMoney payment interest
        newLiability = subMoney (leaseLiability l) principalRepayment
     in l
            { leaseLiability = newLiability
            , leaseVersion = nextVersion (leaseVersion l)
            }

-- ─────────────────────────────────────────────────────────────────────────────
-- サービス（循環インポート回避のためファサードに直接定義）
-- ─────────────────────────────────────────────────────────────────────────────

computePeriodInterest :: Lease currency -> Money currency
computePeriodInterest l =
    scaleMoney (leaseDiscountRate l / 12) (leaseLiability l)

computePeriodDepreciation :: Lease currency -> Money currency
computePeriodDepreciation l =
    scaleMoney (1 / fromIntegral (leaseTerm l)) (leaseRouAsset l)
