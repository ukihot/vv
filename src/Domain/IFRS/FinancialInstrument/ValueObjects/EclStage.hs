module Domain.IFRS.FinancialInstrument.ValueObjects.EclStage (
    EclStage (..),
)
where

data EclStage
    = Stage1
    | Stage2
    | Stage3
    deriving (Show, Eq, Ord, Enum, Bounded)
