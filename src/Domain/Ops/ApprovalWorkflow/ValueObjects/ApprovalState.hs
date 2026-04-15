module Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalState (
    ApprovalState (..),
)
where

data ApprovalState
    = -- | 下書き
      Draft
    | -- | 承認待ち
      PendingApproval
    | -- | 承認済み
      Approved
    | -- | 却下
      Rejected
    deriving (Show, Eq, Ord, Enum, Bounded)
