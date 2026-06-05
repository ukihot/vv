{- | 承認ワークフロー集約ルートエンティティ
承認プロセスを型安全に管理し、承認状態の遷移を保証する。
-}
module Domain.Ops.ApprovalWorkflow (
    -- * 集約
    ApprovalWorkflow (..),
    ApprovalState (..),
    SomeApprovalWorkflow (..),

    -- * 値オブジェクト
    module Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalWorkflowId,

    -- * 状態遷移
    createDraft,
    submitForApproval,
    approve,
    reject,
)
where

import Data.Text (Text)
import Data.Time (UTCTime)
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.Ops.ApprovalWorkflow.Events (ApprovalWorkflowEventPayload (..))
import Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalState (ApprovalState (..))
import Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalWorkflowId
import Domain.Ops.ApprovalWorkflow.ValueObjects.Version (Version, initialVersion, nextVersion)

-- ─────────────────────────────────────────────────────────────────────────────
-- 承認ワークフロー集約 GADT
-- ─────────────────────────────────────────────────────────────────────────────

data ApprovalWorkflow (s :: ApprovalState) where
    AWDraft ::
        ApprovalWorkflowId ->
        Text ->
        UserId ->
        UTCTime ->
        Version ->
        ApprovalWorkflow 'Draft
    AWPendingApproval ::
        ApprovalWorkflowId ->
        Text ->
        UserId ->
        UTCTime ->
        Version ->
        ApprovalWorkflow 'PendingApproval
    AWApproved ::
        ApprovalWorkflowId ->
        Text ->
        UserId ->
        UserId ->
        UTCTime ->
        Version ->
        ApprovalWorkflow 'Approved
    AWRejected ::
        ApprovalWorkflowId ->
        Text ->
        UserId ->
        UserId ->
        Text ->
        UTCTime ->
        Version ->
        ApprovalWorkflow 'Rejected

deriving stock instance Show (ApprovalWorkflow s)
deriving stock instance Eq (ApprovalWorkflow s)

data SomeApprovalWorkflow where
    SomeAW :: ApprovalWorkflow s -> SomeApprovalWorkflow

deriving stock instance Show SomeApprovalWorkflow

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

createDraft ::
    ApprovalWorkflowId ->
    Text ->
    UserId ->
    UTCTime ->
    (ApprovalWorkflow 'Draft, ApprovalWorkflowEventPayload)
createDraft wfId description creatorId timestamp =
    ( AWDraft wfId description creatorId timestamp initialVersion
    , WorkflowCreated wfId creatorId
    )

submitForApproval ::
    ApprovalWorkflow 'Draft ->
    (ApprovalWorkflow 'PendingApproval, ApprovalWorkflowEventPayload)
submitForApproval (AWDraft wfId description creatorId timestamp v) =
    ( AWPendingApproval wfId description creatorId timestamp (nextVersion v)
    , WorkflowSubmitted wfId creatorId
    )

approve ::
    UserId ->
    ApprovalWorkflow 'PendingApproval ->
    (ApprovalWorkflow 'Approved, ApprovalWorkflowEventPayload)
approve approverId (AWPendingApproval wfId description creatorId timestamp v) =
    ( AWApproved wfId description creatorId approverId timestamp (nextVersion v)
    , WorkflowApproved wfId approverId
    )

reject ::
    UserId ->
    Text ->
    ApprovalWorkflow 'PendingApproval ->
    (ApprovalWorkflow 'Rejected, ApprovalWorkflowEventPayload)
reject rejecterId reason (AWPendingApproval wfId description creatorId timestamp v) =
    ( AWRejected wfId description creatorId rejecterId reason timestamp (nextVersion v)
    , WorkflowRejected wfId rejecterId reason
    )
