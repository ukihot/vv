module App.Ports.Command.Workflow (
    SubmitForApprovalUseCase (..),
    ApproveUseCase (..),
    RejectUseCase (..),
    RequestRevisionUseCase (..),
)
where

import Data.Text (Text)

-- ============================================================================
-- Approval Workflow (承認ワークフロー)
-- ============================================================================

class Monad m => SubmitForApprovalUseCase m where
    executeSubmitForApproval :: Text -> Text -> Text -> m (Either Text Text)

-- documentType, documentId, submitterId -> workflowId

class Monad m => ApproveUseCase m where
    executeApprove :: Text -> Text -> Text -> m (Either Text ())

-- workflowId, approverId, comment

class Monad m => RejectUseCase m where
    executeReject :: Text -> Text -> Text -> m (Either Text ())

-- workflowId, approverId, reason

class Monad m => RequestRevisionUseCase m where
    executeRequestRevision :: Text -> Text -> Text -> m (Either Text ())

-- workflowId, approverId, comment
