{- | 収益認識集約ルートエンティティ (IFRS 15準拠)
5ステップモデルを型で表現し、履行義務の識別・取引価格配分・
収益認識タイミングをコンパイル時に強制する。
-}
module Domain.IFRS.Revenue (
    -- * エンティティ
    module Domain.IFRS.Revenue.Entities.PerformanceObligation,
    module Domain.IFRS.Revenue.Entities.VariableConsideration,
    module Domain.IFRS.Revenue.Entities.RevenueJudgmentLog,
    module Domain.IFRS.Revenue.Entities.RevenueRecognitionResult,

    -- * 値オブジェクト
    module Domain.IFRS.Revenue.ValueObjects.ContractId,
    module Domain.IFRS.Revenue.ValueObjects.AllocationMethod,
)
where

import Domain.IFRS.Revenue.Entities.PerformanceObligation
import Domain.IFRS.Revenue.Entities.RevenueJudgmentLog
import Domain.IFRS.Revenue.Entities.RevenueRecognitionResult
import Domain.IFRS.Revenue.Entities.VariableConsideration
import Domain.IFRS.Revenue.ValueObjects.AllocationMethod
import Domain.IFRS.Revenue.ValueObjects.ContractId
