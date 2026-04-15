module Domain.IFRS.FixedAsset.Errors (
    FixedAssetError (..),
)
where

data FixedAssetError
    = InvalidFixedAssetId
    | InvalidComponentId
    | NegativeUsefulLife
    | InvalidDepreciationMethod
    deriving (Show, Eq)
