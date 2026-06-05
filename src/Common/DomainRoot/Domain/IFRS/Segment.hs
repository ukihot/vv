{- | セグメント情報集約ルートエンティティ (IFRS 8準拠)
管理会計変換原則に基づき、
制度表示区分に拘束されないセグメント別損益を管理する。
-}
module Domain.IFRS.Segment (
    -- * 集約
    Segment (..),

    -- * エンティティ
    module Domain.IFRS.Segment.Entities.SegmentResult,

    -- * 値オブジェクト
    module Domain.IFRS.Segment.ValueObjects.SegmentId,
)
where

import Data.Text (Text)
import Domain.IFRS.Segment.Entities.SegmentResult
import Domain.IFRS.Segment.ValueObjects.SegmentId

data Segment = Segment
    { segmentId :: SegmentId
    , segmentName :: Text
    }
    deriving stock (Show, Eq)
