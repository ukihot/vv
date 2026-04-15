module Domain.Ops.TaxConfiguration.ValueObjects.TaxType
    ( TaxType (..)
    )
where

data TaxType
    = -- | 消費税（標準税率）
      ConsumptionTaxStandard
    | -- | 消費税（軽減税率）
      ConsumptionTaxReduced
    | -- | 法人税
      CorporateTax
    | -- | 源泉所得税
      WithholdingTax
    deriving (Show, Eq, Ord, Enum, Bounded)
