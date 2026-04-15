{- | 金融商品集約 (IFRS 9準拠 §4.7.5〜4.7.9)
ECL 3ステージモデルを型で表現し、
ステージ移動・ECL算定・判断ログを型安全に管理する。
-}
module Domain.IFRS.FinancialInstrument
    ( -- * 金融資産識別子
      FinancialAssetId (..)
    , mkFinancialAssetId

      -- * ECL ステージ §4.7.5
    , EclStage (..)

      -- * ECL パラメータ §4.7.8
    , EclParameters (..)
    , EconomicScenario (..)
    , ScenarioWeight (..)

      -- * ECL 算定 §4.7.7
    , computeEcl

      -- * ステージ判定 §4.7.6
    , classifyStage

      -- * 金融資産集約 (#3, #15: GADT)
    , FinancialAsset (..)
    , SomeFinancialAsset (..)
    , recordFinancialAsset
    , promoteToStage2
    , promoteToStage3
    , demoteToStage1
    , updateEclStage

      -- * ゲッター
    , faId
    , faGrossCarrying
    , faEclAllowance
    , faOriginalEir
    , faVersion
    , faStage

      -- * ECL 判断ログ §4.7.9, §5.2.2
    , EclJudgmentLog (..)

      -- * エラー
    , FinancialInstrumentError (..)
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Shared (Money (..), Version, initialVersion, nextVersion, scaleMoney, zeroMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 識別子
-- ─────────────────────────────────────────────────────────────────────────────

newtype FinancialAssetId = FinancialAssetId {unFinancialAssetId :: Text}
    deriving (Show, Eq, Ord)

mkFinancialAssetId :: Text -> Either FinancialInstrumentError FinancialAssetId
mkFinancialAssetId t
    | T.null t = Left InvalidAssetId
    | otherwise = Right (FinancialAssetId t)

-- ─────────────────────────────────────────────────────────────────────────────
-- ECL ステージ §4.7.5
-- ─────────────────────────────────────────────────────────────────────────────

{- | IFRS 9 の3ステージ分類。
ステージにより損失評価期間と割引率が変わる。
-}
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
-- 金融資産集約 (#3, #15: GADT でステージを型引数に昇格)
-- ─────────────────────────────────────────────────────────────────────────────

{- | ステージを型引数に持つ GADT。
Stage1 → Stage2 → Stage3 の遷移関数が型で制約される (#5)。
-}
data FinancialAsset (s :: EclStage) (currency :: Symbol) where
    FA1 ::
        FinancialAssetId ->
        Money currency ->
        Money currency ->
        Rational ->
        Version ->
        FinancialAsset 'Stage1 currency
    FA2 ::
        FinancialAssetId ->
        Money currency ->
        Money currency ->
        Rational ->
        Version ->
        FinancialAsset 'Stage2 currency
    FA3 ::
        FinancialAssetId ->
        Money currency ->
        Money currency ->
        Rational ->
        Version ->
        FinancialAsset 'Stage3 currency

deriving instance Show (FinancialAsset s currency)

deriving instance Eq (FinancialAsset s currency)

-- | 存在型: Application 層でのみ使用する (#20)
data SomeFinancialAsset currency where
    SomeFA :: FinancialAsset s currency -> SomeFinancialAsset currency

deriving instance Show (SomeFinancialAsset currency)

-- ゲッター（全ステージ共通）
faId :: FinancialAsset s currency -> FinancialAssetId
faId (FA1 i _ _ _ _) = i
faId (FA2 i _ _ _ _) = i
faId (FA3 i _ _ _ _) = i

faGrossCarrying :: FinancialAsset s currency -> Money currency
faGrossCarrying (FA1 _ g _ _ _) = g
faGrossCarrying (FA2 _ g _ _ _) = g
faGrossCarrying (FA3 _ g _ _ _) = g

faEclAllowance :: FinancialAsset s currency -> Money currency
faEclAllowance (FA1 _ _ e _ _) = e
faEclAllowance (FA2 _ _ e _ _) = e
faEclAllowance (FA3 _ _ e _ _) = e

faOriginalEir :: FinancialAsset s currency -> Rational
faOriginalEir (FA1 _ _ _ r _) = r
faOriginalEir (FA2 _ _ _ r _) = r
faOriginalEir (FA3 _ _ _ r _) = r

faVersion :: FinancialAsset s currency -> Version
faVersion (FA1 _ _ _ _ v) = v
faVersion (FA2 _ _ _ _ v) = v
faVersion (FA3 _ _ _ _ v) = v

faStage :: FinancialAsset s currency -> EclStage
faStage FA1 {} = Stage1
faStage FA2 {} = Stage2
faStage FA3 {} = Stage3

-- | 初度認識: Stage1 で開始 (#5: 型シグネチャが仕様書)
recordFinancialAsset ::
    FinancialAssetId ->
    Money currency ->
    -- | 当初実効金利
    Rational ->
    FinancialAsset 'Stage1 currency
recordFinancialAsset fid gross eir =
    FA1 fid gross zeroMoney eir initialVersion

-- | Stage1 → Stage2 への移動 (#5: 不正遷移はコンパイルエラー)
promoteToStage2 ::
    FinancialAsset 'Stage1 currency ->
    Money currency ->
    (FinancialAsset 'Stage2 currency, EclJudgmentLog currency)
promoteToStage2 fa newEcl =
    ( FA2 (faId fa) (faGrossCarrying fa) newEcl (faOriginalEir fa) (nextVersion (faVersion fa)),
      EclJudgmentLog (faId fa) Stage1 Stage2 newEcl ""
    )

-- | Stage2 → Stage3 への移動
promoteToStage3 ::
    FinancialAsset 'Stage2 currency ->
    Money currency ->
    (FinancialAsset 'Stage3 currency, EclJudgmentLog currency)
promoteToStage3 fa newEcl =
    ( FA3 (faId fa) (faGrossCarrying fa) newEcl (faOriginalEir fa) (nextVersion (faVersion fa)),
      EclJudgmentLog (faId fa) Stage2 Stage3 newEcl ""
    )

-- | Stage2 → Stage1 への改善
demoteToStage1 ::
    FinancialAsset 'Stage2 currency ->
    Money currency ->
    (FinancialAsset 'Stage1 currency, EclJudgmentLog currency)
demoteToStage1 fa newEcl =
    ( FA1 (faId fa) (faGrossCarrying fa) newEcl (faOriginalEir fa) (nextVersion (faVersion fa)),
      EclJudgmentLog (faId fa) Stage2 Stage1 newEcl ""
    )

-- | 後方互換: 実行時ステージ指定によるステージ更新（Application 層向け）
updateEclStage ::
    SomeFinancialAsset currency ->
    EclStage ->
    Money currency ->
    (SomeFinancialAsset currency, EclJudgmentLog currency)
updateEclStage (SomeFA fa@FA1 {}) Stage2 ecl =
    let (fa', log') = promoteToStage2 fa ecl in (SomeFA fa', log')
updateEclStage (SomeFA fa@FA2 {}) Stage3 ecl =
    let (fa', log') = promoteToStage3 fa ecl in (SomeFA fa', log')
updateEclStage (SomeFA fa@FA2 {}) Stage1 ecl =
    let (fa', log') = demoteToStage1 fa ecl in (SomeFA fa', log')
updateEclStage (SomeFA fa) newStage ecl =
    -- 同ステージ更新: ECL引当のみ変更
    let v' = nextVersion (faVersion fa)
        fa' = case fa of
            FA1 i g _ r _ -> SomeFA (FA1 i g ecl r v')
            FA2 i g _ r _ -> SomeFA (FA2 i g ecl r v')
            FA3 i g _ r _ -> SomeFA (FA3 i g ecl r v')
     in (fa', EclJudgmentLog (faId fa) (faStage fa) newStage ecl "")

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
