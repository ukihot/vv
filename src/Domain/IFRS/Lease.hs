-- | リース集約 (IFRS 16準拠 §2.4.6)
-- 使用権資産とリース負債を型安全に管理し、
-- 利息費用・償却の計算を保証する。
module Domain.IFRS.Lease
  ( -- * リース識別子
    LeaseId (..),
    mkLeaseId,

    -- * リース集約
    Lease (..),
    recordLease,
    computePeriodInterest,
    computePeriodDepreciation,

    -- * リース負債残高更新
    applyLeasePayment,

    -- * エラー
    LeaseError (..),
  )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Shared (Money, Version, initialVersion, mkMoney, nextVersion, scaleMoney, subMoney, unMoney, zeroMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 識別子
-- ─────────────────────────────────────────────────────────────────────────────

newtype LeaseId = LeaseId {unLeaseId :: Text}
  deriving (Show, Eq, Ord)

mkLeaseId :: Text -> Either LeaseError LeaseId
mkLeaseId t
  | null (show t) = Left InvalidLeaseId
  | otherwise = Right (LeaseId t)

-- ─────────────────────────────────────────────────────────────────────────────
-- リース集約
-- ─────────────────────────────────────────────────────────────────────────────

data Lease (currency :: Symbol) = Lease
  { leaseId :: LeaseId,
    leaseCommencementDate :: Day,
    -- | リース期間（月数）
    leaseTerm :: Int,
    -- | 割引率（年率）
    leaseDiscountRate :: Rational,
    -- | 使用権資産帳簿価額
    leaseRouAsset :: Money currency,
    -- | リース負債残高
    leaseLiability :: Money currency,
    -- | 使用権資産累計償却
    leaseAccumDeprec :: Money currency,
    leaseVersion :: Version
  }
  deriving (Show, Eq)

-- | リース開始時の初度認識。
-- 使用権資産 = リース負債（簡便化: 直接費用・解体費用は別途加算）
recordLease ::
  LeaseId ->
  Day ->
  -- | リース期間（月数）
  Int ->
  -- | 割引率（年率）
  Rational ->
  -- | リース負債現在価値（= 使用権資産初度測定額）
  Money currency ->
  Lease currency
recordLease lid date term rate pv =
  Lease
    { leaseId = lid,
      leaseCommencementDate = date,
      leaseTerm = term,
      leaseDiscountRate = rate,
      leaseRouAsset = pv,
      leaseLiability = pv,
      leaseAccumDeprec = zeroMoney,
      leaseVersion = initialVersion
    }

-- | 月次利息費用 = リース負債残高 × 月次割引率
computePeriodInterest :: Lease currency -> Money currency
computePeriodInterest l =
  scaleMoney (leaseDiscountRate l / 12) (leaseLiability l)

-- | 月次使用権資産償却 = 使用権資産 / リース期間（月数）
computePeriodDepreciation :: Lease currency -> Money currency
computePeriodDepreciation l =
  scaleMoney (1 / fromIntegral (leaseTerm l)) (leaseRouAsset l)

-- | リース支払の適用: 負債残高を減少させる。
-- 支払額 = 利息費用 + 元本返済
applyLeasePayment ::
  Lease currency ->
  -- | 支払額
  Money currency ->
  Lease currency
applyLeasePayment l payment =
  let interest = computePeriodInterest l
      principalRepayment = subMoney payment interest
      newLiability = subMoney (leaseLiability l) principalRepayment
   in l
        { leaseLiability = newLiability,
          leaseVersion = nextVersion (leaseVersion l)
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data LeaseError
  = InvalidLeaseId
  | NegativeLeaseTerm
  | NonPositiveDiscountRate
  deriving (Show, Eq)
