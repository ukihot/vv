{- | 金融商品集約ルートエンティティ (IFRS 9準拠)
ECL 3ステージモデルを型で表現し、
ステージ移動・ECL算定・判断ログを型安全に管理する。
-}
module Domain.IFRS.FinancialInstrument
    ( -- * 集約
      FinancialAsset (..)
    , EclStage (..)
    , SomeFinancialAsset (..)

      -- * ゲッター
    , faId
    , faGrossCarrying
    , faEclAllowance
    , faOriginalEir
    , faVersion
    , faStage

      -- * 状態遷移
    , recordFinancialAsset
    , promoteToStage2
    , promoteToStage3
    , demoteToStage1
    , updateEclStage
    )
where

import Domain.IFRS.FinancialInstrument.Entities.EclJudgmentLog (EclJudgmentLog (..))
import Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (EclStage (..))
import Domain.IFRS.FinancialInstrument.ValueObjects.FinancialAssetId (FinancialAssetId)
import Domain.IFRS.FinancialInstrument.ValueObjects.Version (Version, initialVersion, nextVersion)
import Domain.Shared (Money, zeroMoney)
import GHC.TypeLits (Symbol)

-- ─────────────────────────────────────────────────────────────────────────────
-- 金融資産集約 GADT
-- ─────────────────────────────────────────────────────────────────────────────

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

data SomeFinancialAsset currency where
    SomeFA :: FinancialAsset s currency -> SomeFinancialAsset currency

deriving instance Show (SomeFinancialAsset currency)

-- ─────────────────────────────────────────────────────────────────────────────
-- ゲッター
-- ─────────────────────────────────────────────────────────────────────────────

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

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

recordFinancialAsset ::
    FinancialAssetId ->
    Money currency ->
    Rational ->
    FinancialAsset 'Stage1 currency
recordFinancialAsset fid gross eir =
    FA1 fid gross zeroMoney eir initialVersion

promoteToStage2 ::
    FinancialAsset 'Stage1 currency ->
    Money currency ->
    (FinancialAsset 'Stage2 currency, EclJudgmentLog currency)
promoteToStage2 fa newEcl =
    ( FA2 (faId fa) (faGrossCarrying fa) newEcl (faOriginalEir fa) (nextVersion (faVersion fa)),
      EclJudgmentLog (faId fa) Stage1 Stage2 newEcl ""
    )

promoteToStage3 ::
    FinancialAsset 'Stage2 currency ->
    Money currency ->
    (FinancialAsset 'Stage3 currency, EclJudgmentLog currency)
promoteToStage3 fa newEcl =
    ( FA3 (faId fa) (faGrossCarrying fa) newEcl (faOriginalEir fa) (nextVersion (faVersion fa)),
      EclJudgmentLog (faId fa) Stage2 Stage3 newEcl ""
    )

demoteToStage1 ::
    FinancialAsset 'Stage2 currency ->
    Money currency ->
    (FinancialAsset 'Stage1 currency, EclJudgmentLog currency)
demoteToStage1 fa newEcl =
    ( FA1 (faId fa) (faGrossCarrying fa) newEcl (faOriginalEir fa) (nextVersion (faVersion fa)),
      EclJudgmentLog (faId fa) Stage2 Stage1 newEcl ""
    )

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
    let v' = nextVersion (faVersion fa)
        fa' = case fa of
            FA1 i g _ r _ -> SomeFA (FA1 i g ecl r v')
            FA2 i g _ r _ -> SomeFA (FA2 i g ecl r v')
            FA3 i g _ r _ -> SomeFA (FA3 i g ecl r v')
     in (fa', EclJudgmentLog (faId fa) (faStage fa) newStage ecl "")
