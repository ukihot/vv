module Domain.Ops.ApprovalWorkflow.ValueObjects.ApprovalWorkflowId
    ( ApprovalWorkflowId (..)
    , mkApprovalWorkflowId
    )
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.ApprovalWorkflow.Errors (ApprovalWorkflowError (..))

newtype ApprovalWorkflowId = ApprovalWorkflowId {unApprovalWorkflowId :: Text}
    deriving (Show, Eq, Ord)

mkApprovalWorkflowId :: Text -> Either ApprovalWorkflowError ApprovalWorkflowId
mkApprovalWorkflowId t
    | T.null t = Left InvalidWorkflowId
    | otherwise = Right (ApprovalWorkflowId t)
