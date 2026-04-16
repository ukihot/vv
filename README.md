# vv

IFRS準拠の複式簿記会計エンジン。Event Sourcing / CQRS + DDD で構築。

## 特徴

- **IFRSポリシー強硬** — 日本会計基準との選択なし。IFRS 9 / 15 / 16 / IAS 21 / 36 を直接実装
- **型安全な財務金額** — 通貨タグ付き `Money (currency :: Symbol)` により異通貨混算をコンパイル時に排除
- **GADT 状態機械** — 集約の状態遷移（`FiscalPeriod 'Open → 'Locked`、`FinancialAsset 'Stage1 → 'Stage2` 等）を型で制約し、不正遷移をコンパイルエラーにする
- **Event Sourcing** — イベントが唯一の事実。`rehydrate` で任意時点の状態を再現可能
- **ローカル完結** — Write: SQLite / Read: RocksDB。サーバ・コンテナ不要

## ドメイン構成

```
Domain/
├── Accounting/   仕訳帳・勘定科目・会計期間・為替レート
├── IFRS/         収益認識(15) / 金融商品(9) / リース(16) / セグメント(8)
├── IAM/          ユーザー・ロール・パーミッション
├── Ops/          予算・銀行口座・承認ワークフロー
├── Org/          組織
└── Audit/        監査証跡・決算クローズ
```

## 要件

- GHC 9.8.2
- Cabal 3.4+

## ビルド・テスト

```sh
cabal build
cabal test
```

## フォーマット

[fourmolu](https://github.com/fourmolu/fourmolu) を使用。設定は `fourmolu.yaml`。

```sh
fourmolu   --ghc-opt=-XImportQualifiedPost   --ghc-opt=-XLambdaCase   --ghc-opt=-XMultiWayIf   --ghc-opt=-XOverloadedStrings   --ghc-opt=-XOverloadedRecordDot   --ghc-opt=-XRecordWildCards   --ghc-opt=-XDerivingStrategies   --ghc-opt=-XDeriveAnyClass   --ghc-opt=-XDataKinds   --ghc-opt=-XTypeFamilies   --ghc-opt=-XGADTs   --ghc-opt=-XViewPatterns   --ghc-opt=-XPatternSynonyms   --ghc-opt=-XStrictData   --mode inplace .
```

## ライセンス

GPL-3.0-or-later
