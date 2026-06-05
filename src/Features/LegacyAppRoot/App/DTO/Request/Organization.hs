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
    deriving stock (Show, Eq)

data UpdateOrganizationRequest = UpdateOrganizationRequest
    { updateOrgId :: Text
    , updateOrgData :: Text -- JSON or structured data
    }
    deriving stock (Show, Eq)

data RegisterDepartmentRequest = RegisterDepartmentRequest
    { regDeptOrgId :: Text
    , regDeptName :: Text
    , regDeptCode :: Text
    }
    deriving stock (Show, Eq)

data AssignDepartmentHeadRequest = AssignDepartmentHeadRequest
    { assignDeptHeadDeptId :: Text
    , assignDeptHeadUserId :: Text
    }
    deriving stock (Show, Eq)

data DefineJobRoleRequest = DefineJobRoleRequest
    { defineJobRoleName :: Text
    , defineJobRoleDescription :: Text
    , defineJobRoleResponsibilities :: [Text]
    }
    deriving stock (Show, Eq)

data AssignJobRoleRequest = AssignJobRoleRequest
    { assignJobRoleUserId :: Text
    , assignJobRoleJobRoleId :: Text
    }
    deriving stock (Show, Eq)

data DefineApprovalMatrixRequest = DefineApprovalMatrixRequest
    { defineApprovalMatrixDocType :: Text
    , defineApprovalMatrixLevels :: [(Text, Int)] -- (roleId, level)
    }
    deriving stock (Show, Eq)
