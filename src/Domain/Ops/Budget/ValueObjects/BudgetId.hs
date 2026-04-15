module Domain.Ops.Budget.ValueObjects.BudgetId (
    BudgetId (..),
    mkBudgetId,
)
where

import Data.Text (Text)
import Data.Text qualified as T
import Domain.Ops.Budget.Errors (BudgetError (..))

newtype BudgetId = BudgetId {unBudgetId :: Text}
    deriving (Show, Eq, Ord)

mkBudgetId :: Text -> Either BudgetError BudgetId
mkBudgetId t
    | T.null t = Left InvalidBudgetId
    | otherwise = Right (BudgetId t)
