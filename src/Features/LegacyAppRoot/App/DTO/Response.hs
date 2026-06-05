{- | Response DTOs

This module re-exports all response DTOs organized by functional domain.
Response DTOs represent output data from query use cases and command results.

Design principles:
- Response DTOs are optimized for presentation layer consumption
- They may include computed fields and formatted data
- Field names are prefixed to avoid conflicts (e.g., userResponseId)
- All DTOs derive Show and Eq for testing and debugging
- Response DTOs are independent from domain entities (CQRS pattern)
-}
module App.DTO.Response (
    -- * IAM
    module App.DTO.Response.IAM,

    -- * Transaction
    module App.DTO.Response.Transaction,

    -- * Ledger
    module App.DTO.Response.Ledger,

    -- * Closing
    module App.DTO.Response.Closing,

    -- * Financial Statement
    module App.DTO.Response.FinancialStatement,
)
where

import App.DTO.Response.Closing
import App.DTO.Response.FinancialStatement
import App.DTO.Response.IAM
import App.DTO.Response.Ledger
import App.DTO.Response.Transaction
