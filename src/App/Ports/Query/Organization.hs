module App.Ports.Query.Organization (
    FindOrganizationQuery (..),
    ListDepartmentsQuery (..),
    FindDepartmentQuery (..),
    ListJobRolesQuery (..),
    GetApprovalMatrixQuery (..),
    OrganizationDTO (..),
    DepartmentDTO (..),
    JobRoleDTO (..),
    ApprovalMatrixDTO (..),
)
where

import Data.Text (Text)

class Monad m => FindOrganizationQuery m where
    executeFindOrganization :: Text -> m (Maybe OrganizationDTO)

class Monad m => ListDepartmentsQuery m where
    executeListDepartments :: Text -> m [DepartmentDTO] -- orgId

class Monad m => FindDepartmentQuery m where
    executeFindDepartment :: Text -> m (Maybe DepartmentDTO)

class Monad m => ListJobRolesQuery m where
    executeListJobRoles :: m [JobRoleDTO]

class Monad m => GetApprovalMatrixQuery m where
    executeGetApprovalMatrix :: Text -> m (Maybe ApprovalMatrixDTO) -- documentType

data OrganizationDTO
data DepartmentDTO
data JobRoleDTO
data ApprovalMatrixDTO
