{- | vv-bench: ドメイン層のパフォーマンス計測

tasty-bench を使用。各ベンチマークは deepseq で WHNF 以上まで評価し、
GHC の遅延評価による計測誤差を排除する。

実行:
  cabal bench vv-bench
  cabal bench vv-bench --benchmark-options='+RTS -T'   -- メモリ統計付き
  cabal bench vv-bench --benchmark-options='--csv bench.csv'
-}
module Main (main) where

import Control.DeepSeq (NFData (..), deepseq, force, rwhnf)
import Data.List (foldl')
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (fromGregorian)
import Domain.Accounting.ChartOfAccounts (mkAccountCode)
import Domain.Accounting.ExchangeRate (ExchangeRate (..), RateKind (..), translateMoney)
import Domain.Accounting.JournalEntry
    ( DrCr (..)
    , JournalError (..)
    , JournalLine (..)
    , validateBalance
    )
import Domain.IAM.User
    ( SomeUser (..)
    , applyEvent
    , rehydrate
    )
import Domain.IAM.User.Entities.Profile (UserProfile (..))
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Events
    ( UserEventPayload (..)
    , UserEventPayloadV1 (..)
    , UserEventPayloadV2 (..)
    )
import Domain.IAM.User.ValueObjects.Email (Email, mkEmail)
import Domain.IAM.User.ValueObjects.UserId (UserId, mkUserId)
import Domain.IAM.User.ValueObjects.UserName (UserName, mkUserName)
import Domain.IFRS.FinancialInstrument
    ( EclJudgmentLog (..)
    , EclParameters (..)
    , EclStage (..)
    , EconomicScenario (..)
    , FinancialAsset (..)
    , FinancialAssetId (..)
    , FinancialInstrumentError (..)
    , ScenarioWeight (..)
    , SomeFinancialAsset (..)
    , classifyStage
    , computeEcl
    , promoteToStage2
    , recordFinancialAsset
    , updateEclStage
    )
import Domain.IFRS.Revenue
    ( AllocationMethod (..)
    , PerformanceObligation (..)
    , PerformanceObligationId (..)
    , ProgressMethod (..)
    , RevenueError (..)
    , SatisfactionPattern (..)
    , allocateTransactionPrice
    )
import Domain.Shared (Money (..), Version (..), mkMoney, zeroMoney)
import Test.Tasty.Bench

-- ─────────────────────────────────────────────────────────────────────────────
-- NFData インスタンス（deepseq で完全評価するために必要）
-- ─────────────────────────────────────────────────────────────────────────────

instance NFData (Money c) where
    rnf (Money r) = rnf r

instance NFData EclStage where
    rnf s = s `seq` ()

instance NFData (FinancialAsset s c) where
    rnf (FA1 (FinancialAssetId i) g e r (Version v)) =
        rnf i `seq` rnf g `seq` rnf e `seq` rnf r `seq` rnf v
    rnf (FA2 (FinancialAssetId i) g e r (Version v)) =
        rnf i `seq` rnf g `seq` rnf e `seq` rnf r `seq` rnf v
    rnf (FA3 (FinancialAssetId i) g e r (Version v)) =
        rnf i `seq` rnf g `seq` rnf e `seq` rnf r `seq` rnf v

instance NFData (SomeFinancialAsset c) where
    rnf (SomeFA fa) = rnf fa

instance NFData SomeUser where
    rnf (SomeUser u) = u `seq` ()

-- Either の両辺
instance NFData FinancialInstrumentError where
    rnf e = e `seq` ()

instance NFData (EclJudgmentLog c) where
    rnf (EclJudgmentLog (FinancialAssetId i) ps ns ecl reason) =
        rnf i `seq` rnf ps `seq` rnf ns `seq` rnf ecl `seq` rnf reason

instance NFData JournalError where
    rnf e = e `seq` ()

instance NFData RevenueError where
    rnf e = e `seq` ()

instance NFData DomainError where
    rnf e = e `seq` ()

instance NFData SatisfactionPattern where
    rnf s = s `seq` ()

instance NFData ProgressMethod where
    rnf p = p `seq` ()

instance NFData PerformanceObligationId where
    rnf (PerformanceObligationId t) = rnf t

instance NFData (PerformanceObligation c) where
    rnf (PerformanceObligation i d p pm ssp ap) =
        rnf i `seq` rnf d `seq` rnf p `seq` rnf pm `seq` rnf ssp `seq` rnf ap

-- ─────────────────────────────────────────────────────────────────────────────
-- フィクスチャ
-- ─────────────────────────────────────────────────────────────────────────────

eclParams :: EclParameters
eclParams =
    EclParameters
        { pd12Month = 0.01,
          pdLifetime = 0.05,
          lgd = 0.45,
          discountFactor = 0.95,
          scenarioWeights =
            [ (BaseScenario, ScenarioWeight 0.6),
              (OptimisticScenario, ScenarioWeight 0.2),
              (PessimisticScenario, ScenarioWeight 0.2)
            ]
        }

ead :: Money "JPY"
ead = mkMoney 1000000

usdJpyRate :: ExchangeRate "USD" "JPY"
usdJpyRate =
    ExchangeRate
        { rateValue = 150,
          rateKind = ClosingRate,
          rateDate = fromGregorian 2026 3 31,
          rateSource = "BOJ"
        }

sampleFaId :: FinancialAssetId
sampleFaId = FinancialAssetId "FA-001"

-- N行の借貸均衡仕訳行リストを生成
makeLines :: Int -> [JournalLine "JPY"]
makeLines n =
    let code = case mkAccountCode "1000" of Right c -> c; Left _ -> error "fixture"
        half = n `div` 2
        drs = replicate half (JournalLine code Dr (mkMoney (fromIntegral half)))
        crs = replicate half (JournalLine code Cr (mkMoney (fromIntegral half)))
     in drs <> crs

-- N個の履行義務リストを生成（均等 SSP）
makeObligations :: Int -> [PerformanceObligation "JPY"]
makeObligations n =
    [ PerformanceObligation
        { poId = PerformanceObligationId (T.pack ("PO-" <> show i)),
          poDescription = "obligation",
          poPattern = AtPointInTime,
          poProgressMethod = Nothing,
          poStandalonePrice = mkMoney 100000,
          poAllocatedPrice = zeroMoney
        }
    | i <- [1 .. n]
    ]

-- N個のイベント列（登録 → 有効化 → 凍結 → 解除 を繰り返す）
makeEvents :: Int -> [UserEventPayload]
makeEvents n =
    let uid = case mkUserId "bench-user" of Right v -> v; Left _ -> error "fixture"
        name = case mkUserName "Bench" of Right v -> v; Left _ -> error "fixture"
        email = case mkEmail "bench@example.com" of Right v -> v; Left _ -> error "fixture"
        base =
            [ V1 (UserRegistered uid name email),
              V1 (UserActivated uid)
            ]
        cycle' =
            [ V2 (UserSuspended uid),
              V2 (UserUnsuspended uid)
            ]
     in base <> concat (replicate ((n - 2) `div` 2) cycle')

-- ─────────────────────────────────────────────────────────────────────────────
-- ベンチマーク
-- ─────────────────────────────────────────────────────────────────────────────

main :: IO ()
main =
    defaultMain
        [ bgroup
            "IFRS 9 / ECL"
            [ bench "computeEcl Stage1" $
                nf (\e -> computeEcl Stage1 e eclParams) ead,
              bench "computeEcl Stage2" $
                nf (\e -> computeEcl Stage2 e eclParams) ead,
              bench "computeEcl Stage3" $
                nf (\e -> computeEcl Stage3 e eclParams) ead,
              bgroup
                "classifyStage (1,000 calls)"
                [ bench "all Stage1" $
                    nf (map (\_ -> classifyStage 0 False False)) [1 .. 1000 :: Int],
                  bench "all Stage3" $
                    nf (map (\_ -> classifyStage 91 False True)) [1 .. 1000 :: Int]
                ],
              bgroup
                "promoteToStage2"
                [ bench "single" $
                    let fa = recordFinancialAsset sampleFaId ead 0.05
                     in nf (promoteToStage2 fa) (mkMoney 4500 :: Money "JPY"),
                  bench "chain Stage1→2→3" $
                    let fa0 = recordFinancialAsset sampleFaId ead 0.05
                        ecl = mkMoney 21375 :: Money "JPY"
                     in nf
                            ( \e ->
                                let (fa1, _) = promoteToStage2 fa0 e
                                 in updateEclStage (SomeFA fa1) Stage3 e
                            )
                            ecl
                ]
            ],
          bgroup
            "IAS 21 / ExchangeRate"
            [ bench "translateMoney single" $
                nf (translateMoney usdJpyRate) (mkMoney 1000 :: Money "USD"),
              bench "translateMoney 10,000 calls" $
                nf (map (translateMoney usdJpyRate . mkMoney . fromIntegral)) [1 .. 10000 :: Int]
            ],
          bgroup
            "Accounting / JournalEntry"
            [ bench "validateBalance 2 lines" $
                nf validateBalance (makeLines 2),
              bench "validateBalance 20 lines" $
                nf validateBalance (makeLines 20),
              bench "validateBalance 200 lines" $
                nf validateBalance (makeLines 200)
            ],
          bgroup
            "IFRS 15 / Revenue allocation"
            [ bench "allocate 2 obligations" $
                nf (allocateTransactionPrice (mkMoney 1000000 :: Money "JPY")) (makeObligations 2),
              bench "allocate 10 obligations" $
                nf (allocateTransactionPrice (mkMoney 1000000 :: Money "JPY")) (makeObligations 10),
              bench "allocate 50 obligations" $
                nf (allocateTransactionPrice (mkMoney 1000000 :: Money "JPY")) (makeObligations 50)
            ],
          bgroup
            "IAM / User rehydrate"
            [ bench "rehydrate 2 events (register+activate)" $
                nf rehydrate (makeEvents 2),
              bench "rehydrate 10 events" $
                nf rehydrate (makeEvents 10),
              bench "rehydrate 100 events" $
                nf rehydrate (makeEvents 100),
              bench "rehydrate 1,000 events" $
                nf rehydrate (makeEvents 1000)
            ]
        ]
