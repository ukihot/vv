module Domain.Ops.ApprovalWorkflow.Events
    ( ApprovalWorkflowEventPayload (..)
    )
where

import Data.Text (Text)
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalWorkflowId (ApprovalWorkflowId)

data ApprovalWorkflowEventPayload
    = WorkflowCreated ApprovalWorkflowId UserId
    | WorkflowSubmitted ApprovalWorkflowId UserId
    | WorkflowApproved ApprovalWorkflowId UserId
    | WorkflowRejected ApprovalWorkflowId UserId Text
    deriving (Show, Eq)
