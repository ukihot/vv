module App.Ports.Command.Management (
    GenerateManagementReportUseCase (..),
    CalculateKPIUseCase (..),
    GenerateDepartmentalPLUseCase (..),
    AnalyzeProfitabilityUseCase (..),
)
where

import Data.Text (Text)

-- ============================================================================
-- Management Accounting (管理会計)
-- ============================================================================

class Monad m => GenerateManagementReportUseCase m where
    executeGenerateManagementReport :: Int -> Int -> Text -> m (Either Text Text)

-- year, month, reportType -> reportId

class Monad m => CalculateKPIUseCase m where
    executeCalculateKPI :: Text -> Int -> Int -> m (Either Text Double)

-- kpiName, year, month -> kpiValue

class Monad m => GenerateDepartmentalPLUseCase m where
    executeGenerateDepartmentalPL :: Text -> Int -> Int -> m (Either Text Text)

-- departmentId, year, month -> plId

class Monad m => AnalyzeProfitabilityUseCase m where
    executeAnalyzeProfitability :: Text -> Int -> Int -> m (Either Text [(Text, Double)])

-- analysisType, year, month -> profitability metrics
