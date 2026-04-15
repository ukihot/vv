-- | 金融商品集約 (IFRS 9準拠 §4.7.5〜4.7.9)
-- ECL 3ステージモデルを型で表現し、
-- ステージ移動・ECL算定・判断ログを型安全に管理する。
module Domain.IFRS.FinancialInstrument
  ( -- * 金融資産識別子
    FinancialAssetId (..),
    mkFinancialAssetId,

    -- * ECL ステージ §4.7.5
    EclStage (..),

    -- * ECL パラメータ §4.7.8
    EclParameters (..),
    EconomicScenario (..),
    ScenarioWeight (..),

    -- * ECL 算定 §4.7.7
    computeEcl,

    -- * ステージ判定 §4.7.6
    classifyStage,

    -- * 金融資産集約
    FinancialAsset (..),
    recordFinancialAsset,
    updateEclStage,

    -- * ECL 判断ログ §4.7.9, §5.2.2
    EclJudgmentLog (..),

    -- * エラー
    FinancialInstrumentError (..),
  )
where

import Data.Text (Text)
import Data.Time (Day)
import Domain.Shared (Money (..), Version, addMoney, initialVersion, nextVersion, scaleMoney, zeroMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 識別子
-- ─────────────────────────────────────────────────────────────────────────────

newtype FinancialAssetId = FinancialAssetId {unFinancialAssetId :: Text}
  deriving (Show, Eq, Ord)

mkFinancialAssetId :: Text -> Either FinancialInstrumentError FinancialAssetId
mkFinancialAssetId t
  | null (show t) = Left InvalidAssetId
  | otherwise = Right (FinancialAssetId t)

-- ─────────────────────────────────────────────────────────────────────────────
-- ECL ステージ §4.7.5
-- ─────────────────────────────────────────────────────────────────────────────

-- | IFRS 9 の3ステージ分類。
-- ステージにより損失評価期間と割引率が変わる。
data EclStage
  = -- | 信用リスク正常: 12ヶ月ECL
    Stage1
  | -- | 信用リスク著しく増大: 全期間ECL
    Stage2
  | -- | 信用減損: 全期間ECL（信用調整済み実効金利）
    Stage3
  deriving (Show, Eq, Ord, Enum, Bounded)

-- ─────────────────────────────────────────────────────────────────────────────
-- ステージ判定 §4.7.6
-- ─────────────────────────────────────────────────────────────────────────────

-- | 期日経過日数・格付変化・財務状況悪化等からステージを判定する。
classifyStage ::
  -- | 期日経過日数
  Int ->
  -- | 信用格付の著しい低下
  Bool ->
  -- | 法的倒産手続開始
  Bool ->
  EclStage
classifyStage daysOverdue ratingDeteriorated legalDefault
  | legalDefault || daysOverdue > 90 = Stage3
  | daysOverdue > 30 || ratingDeteriorated = Stage2
  | otherwise = Stage1

-- ─────────────────────────────────────────────────────────────────────────────
-- ECL パラメータ §4.7.8
-- ─────────────────────────────────────────────────────────────────────────────

data EconomicScenario
  = -- | ベースシナリオ
    BaseScenario
  | -- | 楽観シナリオ
    OptimisticScenario
  | -- | 悲観シナリオ
    PessimisticScenario
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | シナリオウェイト（合計が1.0になること）
newtype ScenarioWeight = ScenarioWeight {unWeight :: Rational}
  deriving (Show, Eq, Ord)

-- | ECL算定パラメータ。債権属性別に設定・四半期更新。
data EclParameters = EclParameters
  { -- | 12ヶ月デフォルト確率 (Stage1)
    pd12Month :: Rational,
    -- | 全期間デフォルト確率 (Stage2/3)
    pdLifetime :: Rational,
    -- | デフォルト時損失率 (0〜1)
    lgd :: Rational,
    -- | 割引係数
    discountFactor :: Rational,
    scenarioWeights :: [(EconomicScenario, ScenarioWeight)]
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- ECL 算定 §4.7.7
-- ─────────────────────────────────────────────────────────────────────────────

-- | ECL = EAD × PD × LGD (× DF for Stage2/3)
computeEcl ::
  EclStage ->
  -- | EAD (Exposure at Default)
  Money currency ->
  EclParameters ->
  Either FinancialInstrumentError (Money currency)
computeEcl stage ead params
  | lgd params < 0 || lgd params > 1 = Left InvalidLgd
  | otherwise = Right $ case stage of
      Stage1 ->
        -- ECL = EAD × PD(12M) × LGD
        scaleMoney (pd12Month params * lgd params) ead
      Stage2 ->
        -- ECL = EAD × PD(Lifetime) × LGD × DF
        scaleMoney (pdLifetime params * lgd params * discountFactor params) ead
      Stage3 ->
        -- Stage3: 信用調整済み実効金利を継続使用（§4.7.7）
        scaleMoney (pdLifetime params * lgd params * discountFactor params) ead

-- ─────────────────────────────────────────────────────────────────────────────
-- 金融資産集約
-- ─────────────────────────────────────────────────────────────────────────────

data FinancialAsset (currency :: Symbol) = FinancialAsset
  { faId :: FinancialAssetId,
    -- | グロス帳簿価額
    faGrossCarrying :: Money currency,
    -- | ECL評価引当（控除）
    faEclAllowance :: Money currency,
    faStage :: EclStage,
    -- | 当初実効金利（Stage3移行後も継続）
    faOriginalEir :: Rational,
    faVersion :: Version
  }
  deriving (Show, Eq)

recordFinancialAsset ::
  FinancialAssetId ->
  Money currency ->
  -- | 当初実効金利
  Rational ->
  FinancialAsset currency
recordFinancialAsset fid gross eir =
  FinancialAsset
    { faId = fid,
      faGrossCarrying = gross,
      faEclAllowance = zeroMoney,
      faStage = Stage1,
      faOriginalEir = eir,
      faVersion = initialVersion
    }

-- | ステージ更新とECL引当の再計算。
updateEclStage ::
  FinancialAsset currency ->
  EclStage ->
  -- | 新ECL引当額
  Money currency ->
  (FinancialAsset currency, EclJudgmentLog currency)
updateEclStage fa newStage newEcl =
  ( fa
      { faStage = newStage,
        faEclAllowance = newEcl,
        faVersion = nextVersion (faVersion fa)
      },
    EclJudgmentLog
      { ejlAssetId = faId fa,
        ejlPreviousStage = faStage fa,
        ejlNewStage = newStage,
        ejlEclAmount = newEcl,
        ejlMovementReason = "" -- 呼び出し元で設定
      }
  )

-- ─────────────────────────────────────────────────────────────────────────────
-- ECL 判断ログ §4.7.9, §5.2.2
-- ─────────────────────────────────────────────────────────────────────────────

data EclJudgmentLog (currency :: Symbol) = EclJudgmentLog
  { ejlAssetId :: FinancialAssetId,
    ejlPreviousStage :: EclStage,
    ejlNewStage :: EclStage,
    ejlEclAmount :: Money currency,
    ejlMovementReason :: Text
  }
  deriving (Show, Eq)

-- ─────────────────────────────────────────────────────────────────────────────
-- エラー
-- ─────────────────────────────────────────────────────────────────────────────

data FinancialInstrumentError
  = InvalidAssetId
  | -- | LGD が 0〜1 の範囲外
    InvalidLgd
  | -- | PD が負値
    InvalidPd
  | -- | EAD が負値
    NegativeEad
  deriving (Show, Eq)
