{- | 為替換算サービス
実装は循環インポート回避のため Domain.Accounting.ExchangeRate ファサードに直接定義している。
呼び出し元は Domain.Accounting.ExchangeRate を直接インポートすること。
-}
module Domain.Accounting.ExchangeRate.Services.Translation
where
