module Domain.Ops.ApprovalWorkflow.Errors
    ( ApprovalWorkflowError (..)
    )
where

data ApprovalWorkflowError
    = InvalidWorkflowId
    | InvalidStateTransition
    | UnauthorizedApprover
    deriving (Show, Eq)
