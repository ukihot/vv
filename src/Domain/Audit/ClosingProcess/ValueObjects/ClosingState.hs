module Domain.Audit.ClosingProcess.ValueObjects.ClosingState (
    ClosingState (..),
)
where

data ClosingState
    = -- | 決算作業中
      InProgress
    | -- | 承認待ち
      PendingApproval
    | -- | 承認済み
      Approved
    | -- | 確定済み
      Finalized
    deriving (Show, Eq, Ord, Enum, Bounded)
