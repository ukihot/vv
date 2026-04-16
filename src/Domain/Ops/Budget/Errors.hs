module Domain.Ops.Budget.Errors (
    BudgetError (..),
)
where

data BudgetError
    = InvalidBudgetId
    | InvalidBudgetAmount
    | BudgetExceeded
    deriving stock (Show, Eq)
