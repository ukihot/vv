-- | 収益認識集約 (IFRS 15準拠 §4.3.1〜4.3.4)
-- 5ステップモデルを型で表現し、履行義務の識別・取引価格配分・
-- 収益認識タイミングをコンパイル時に強制する。
module Domain.IFRS.Revenue
  ( -- * 契約識別子
    ContractId (..),
    mkContractId,

    -- * 履行義務
    PerformanceObligationId (..),
    SatisfactionPattern (..),
    ProgressMethod (..),
    PerformanceObligation (..),

    -- * 取引価格配分
    AllocationMethod (..),
    PriceAllocation (..),
    allocateTransactionPrice,

    -- * 変動対価 §4.3.3
    VariableConsideration (..),
    VariableConsiderationMethod (..),

    -- * 収益認識判断ログ §4.3.4
    RevenueJudgmentLog (..),

    -- * 収益認識結果
    RevenueRecognitionResult (..),
    recognizeRevenue,

    -- * エラー
    RevenueError (..),
  )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Shared (Money (..), addMoney, scaleMoney, zeroMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 契約識別子
-- ─────────────────────────────────────────────────────────────────────────────

newtype ContractId = ContractId {unContractId :: Text}
  deriving (Show, Eq, Ord)

mkContractId :: Text -> Either RevenueError ContractId
mkContractId t
  | null (show t) = Left InvalidContractId
  | otherwise = Right (ContractId t)

-- ─────────────────────────────────────────────────────────────────────────────
-- 履行義務 (Step 2)
-- ─────────────────────────────────────────────────────────────────────────────

newtype PerformanceObligationId = PerformanceObligationId {unPOId :: Text}
  deriving (Show, Eq, Ord)

-- | 収益認識パターン: 一時点 vs 期間
data SatisfactionPattern
  = -- | 一時点認識
    AtPointInTime
  | -- | 期間認識
    OverTime
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | 期間認識時の進捗度測定方法 §4.3.1 Step5
data ProgressMethod
  = -- | インプット法（コスト進捗等）
    InputMethod
  | -- | アウトプット法（成果物単位等）
    OutputMethod
  deriving (Show, Eq, Ord, Enum, Bounded)

data PerformanceObligation (currency :: Symbol) = PerformanceObligation
  { poId :: PerformanceObligationId,
    poDescription :: Text,
    poPattern :: SatisfactionPattern,
    -- | OverTime の場合のみ
    poProgressMethod :: Maybe ProgressMethod,
    -- | 独立販売価格
    poStandalonePrice :: Money currency,
    -- | 配分後取引価格
    poAllocatedPrice :: Money currency
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- 取引価格配分 (Step 4) §4.3.2
-- ─────────────────────────────────────────────────────────────────────────────

data AllocationMethod
  = -- | 独立販売価格比率法（原則）
    RelativeStandalonePrice
  | -- | 調整市場評価アプローチ
    AdjustedMarketAssessment
  | -- | 予想コスト＋利益アプローチ
    ExpectedCostPlusMargin
  | -- | 残余アプローチ（適用要件充足時のみ）
    ResidualApproach
  deriving (Show, Eq, Ord, Enum, Bounded)

data PriceAllocation (currency :: Symbol) = PriceAllocation
  { paMethod :: AllocationMethod,
    paTransactionPrice :: Money currency,
    paObligations :: [PerformanceObligation currency]
  }
  deriving (Show, Eq)

-- | 独立販売価格比率法による取引価格配分。
-- 各履行義務の独立販売価格の比率で取引価格を按分する。
allocateTransactionPrice ::
  -- | 取引価格合計
  Money currency ->
  -- | 履行義務リスト（独立販売価格設定済み）
  [PerformanceObligation currency] ->
  Either RevenueError [PerformanceObligation currency]
allocateTransactionPrice txPrice pos
  | totalSSP == 0 = Left ZeroStandalonePrice
  | otherwise = Right (map allocate pos)
  where
    totalSSP = unMoney (foldr (\po acc -> addMoney acc (poStandalonePrice po)) zeroMoney pos)
    allocate po =
      let ratio = unMoney (poStandalonePrice po) / totalSSP
       in po {poAllocatedPrice = scaleMoney ratio txPrice}

-- ─────────────────────────────────────────────────────────────────────────────
-- 変動対価 §4.3.3
-- ─────────────────────────────────────────────────────────────────────────────

data VariableConsiderationMethod
  = -- | 期待値法
    ExpectedValueMethod
  | -- | 最頻値法
    MostLikelyAmount
  deriving (Show, Eq, Ord, Enum, Bounded)

data VariableConsideration (currency :: Symbol) = VariableConsideration
  { vcDescription :: Text,
    vcMethod :: VariableConsiderationMethod,
    vcEstimatedAmount :: Money currency,
    -- | 重要な戻入れが生じない可能性が非常に高い範囲の根拠
    vcConstraintNote :: Text
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- 収益認識判断ログ §4.3.4, §5.2.1
-- ─────────────────────────────────────────────────────────────────────────────

data RevenueJudgmentLog (currency :: Symbol) = RevenueJudgmentLog
  { rjlContractId :: ContractId,
    -- | 契約の識別
    rjlStep1ContractExists :: Bool,
    -- | 履行義務識別根拠
    rjlStep2ObligationBasis :: Text,
    -- | 独立販売価格算定方法
    rjlStep3AllocationMethod :: AllocationMethod,
    rjlStep3VariableConsideration :: Maybe (VariableConsideration currency),
    -- | 期間認識の場合
    rjlStep5ProgressMethod :: Maybe ProgressMethod,
    rjlJudgmentDate :: Day
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- 収益認識結果
-- ─────────────────────────────────────────────────────────────────────────────

data RevenueRecognitionResult (currency :: Symbol) = RevenueRecognitionResult
  { rrrContractId :: ContractId,
    rrrObligationId :: PerformanceObligationId,
    rrrRecognizedAmt :: Money currency,
    rrrRecognizedAt :: Day,
    rrrJudgmentLog :: RevenueJudgmentLog currency
  }
  deriving (Show, Eq)

-- | 一時点認識の収益計上。
-- 履行義務充足時点で配分済み取引価格を全額認識する。
recognizeRevenue ::
  PerformanceObligation currency ->
  Day ->
  RevenueJudgmentLog currency ->
  Either RevenueError (RevenueRecognitionResult currency)
recognizeRevenue po date log
  | poPattern po /= AtPointInTime = Left CannotRecognizeOverTimeObligationAtPoint
  | otherwise =
      Right
        RevenueRecognitionResult
          { rrrContractId = rjlContractId log,
            rrrObligationId = poId po,
            rrrRecognizedAmt = poAllocatedPrice po,
            rrrRecognizedAt = date,
            rrrJudgmentLog = log
          }

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data RevenueError
  = InvalidContractId
  | ZeroStandalonePrice
  | CannotRecognizeOverTimeObligationAtPoint
  | ResidualApproachRequirementsNotMet
  deriving (Show, Eq)
