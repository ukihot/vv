module Domain.Ops.Budget.Errors
    ( BudgetError (..)
    )
where

data BudgetError
    = InvalidBudgetId
    | InvalidBudgetAmount
    | BudgetExceeded
    deriving (Show, Eq)
