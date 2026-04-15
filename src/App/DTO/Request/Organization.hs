module App.DTO.Request.Organization (
    RegisterOrganizationRequest (..),
    UpdateOrganizationRequest (..),
    RegisterDepartmentRequest (..),
    AssignDepartmentHeadRequest (..),
    DefineJobRoleRequest (..),
    AssignJobRoleRequest (..),
    DefineApprovalMatrixRequest (..),
)
where

import Data.Text (Text)

data RegisterOrganizationRequest = RegisterOrganizationRequest
    { regOrgName :: Text
    , regOrgCode :: Text
    , regOrgFunctionalCurrency :: Text
    }
    deriving (Show, Eq)

data UpdateOrganizationRequest = UpdateOrganizationRequest
    { updateOrgId :: Text
    , updateOrgData :: Text -- JSON or structured data
    }
    deriving (Show, Eq)

data RegisterDepartmentRequest = RegisterDepartmentRequest
    { regDeptOrgId :: Text
    , regDeptName :: Text
    , regDeptCode :: Text
    }
    deriving (Show, Eq)

data AssignDepartmentHeadRequest = AssignDepartmentHeadRequest
    { assignDeptHeadDeptId :: Text
    , assignDeptHeadUserId :: Text
    }
    deriving (Show, Eq)

data DefineJobRoleRequest = DefineJobRoleRequest
    { defineJobRoleName :: Text
    , defineJobRoleDescription :: Text
    , defineJobRoleResponsibilities :: [Text]
    }
    deriving (Show, Eq)

data AssignJobRoleRequest = AssignJobRoleRequest
    { assignJobRoleUserId :: Text
    , assignJobRoleJobRoleId :: Text
    }
    deriving (Show, Eq)

data DefineApprovalMatrixRequest = DefineApprovalMatrixRequest
    { defineApprovalMatrixDocType :: Text
    , defineApprovalMatrixLevels :: [(Text, Int)] -- (roleId, level)
    }
    deriving (Show, Eq)
