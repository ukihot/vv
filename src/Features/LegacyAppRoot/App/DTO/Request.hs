{- | Request DTOs

This module re-exports all request DTOs organized by functional domain.
Request DTOs represent input data for command use cases.

Design principles:
- Each DTO is a simple data structure with named fields
- DTOs are validated at the adapter layer before reaching use cases
- Field names are prefixed to avoid conflicts (e.g., regOrgName, updateOrgId)
- All DTOs derive Show and Eq for testing and debugging
-}
module App.DTO.Request (
    -- * IAM
    module App.DTO.Request.IAM,

    -- * Organization
    module App.DTO.Request.Organization,

    -- * Transaction
    module App.DTO.Request.Transaction,

    -- * Closing
    module App.DTO.Request.Closing,
)
where

import App.DTO.Request.Closing
import App.DTO.Request.IAM
import App.DTO.Request.Organization
import App.DTO.Request.Transaction
