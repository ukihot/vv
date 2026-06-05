module App.Ports.Command.Organization (
    RegisterOrganizationUseCase (..),
    UpdateOrganizationUseCase (..),
    RegisterDepartmentUseCase (..),
    AssignDepartmentHeadUseCase (..),
    DefineJobRoleUseCase (..),
    AssignJobRoleUseCase (..),
    DefineApprovalMatrixUseCase (..),
)
where

import Data.Text (Text)

-- ============================================================================
-- Organization Management
-- ============================================================================

class Monad m => RegisterOrganizationUseCase m where
    executeRegisterOrganization :: Text -> Text -> Text -> m (Either Text Text)

-- name, code, functionalCurrency -> orgId

class Monad m => UpdateOrganizationUseCase m where
    executeUpdateOrganization :: Text -> Text -> m (Either Text ()) -- orgId, updates

class Monad m => RegisterDepartmentUseCase m where
    executeRegisterDepartment :: Text -> Text -> Text -> m (Either Text Text)

-- orgId, name, code -> deptId

class Monad m => AssignDepartmentHeadUseCase m where
    executeAssignDepartmentHead :: Text -> Text -> m (Either Text ()) -- deptId, userId

class Monad m => DefineJobRoleUseCase m where
    executeDefineJobRole :: Text -> Text -> [Text] -> m (Either Text Text)

-- name, description, responsibilities -> jobRoleId

class Monad m => AssignJobRoleUseCase m where
    executeAssignJobRole :: Text -> Text -> m (Either Text ()) -- userId, jobRoleId

class Monad m => DefineApprovalMatrixUseCase m where
    executeDefineApprovalMatrix :: Text -> [(Text, Int)] -> m (Either Text Text)

-- documentType, [(roleId, level)] -> matrixId
