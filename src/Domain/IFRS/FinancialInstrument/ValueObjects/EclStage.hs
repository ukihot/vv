module Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (
    EclStage (..),
)
where

data EclStage
    = Stage1
    | Stage2
    | Stage3
    deriving stock (Show, Eq, Ord, Enum, Bounded)
