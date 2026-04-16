{- | リース計算サービス
実装は循環インポート回避のため Domain.IFRS.Lease ファサードに直接定義している。
呼び出し元は Domain.IFRS.Lease を直接インポートすること。
-}
module Domain.IFRS.Lease.Services.LeaseCalculation
where
