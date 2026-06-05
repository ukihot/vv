module Domain.Ops.ApprovalWorkflow.Repository (
    ApprovalWorkflowRepository (..),
)
where

import Domain.Ops.ApprovalWorkflow (SomeApprovalWorkflow)
import Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalWorkflowId (ApprovalWorkflowId)

class Monad m => ApprovalWorkflowRepository m where
    saveApprovalWorkflow :: SomeApprovalWorkflow -> m ()
    findApprovalWorkflowById :: ApprovalWorkflowId -> m (Maybe SomeApprovalWorkflow)
