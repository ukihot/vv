{- | Output Ports - Presenter Interfaces

This module re-exports all output ports organized by functional domain.
Each output port represents a specific screen/view in the presentation layer.

Design principles:
- One output port per screen/use case
- Each port has presentSuccess and presentFailure methods
- Success methods receive Response DTOs
- Failure methods receive error messages (Text)
- Output ports enable the Dependency Inversion Principle

Example:
  class Monad m => LoginOutputPort m where
    presentLoginSuccess :: LoginResponse -> m ()
    presentLoginFailure :: Text -> m ()

The use case calls the output port, and the adapter layer implements it
to render the appropriate view (Web UI, CLI, API response, etc.)
-}
module App.Ports.Output (
    -- * IAM
    module App.Ports.Output.IAM,

    -- * Transaction
    module App.Ports.Output.Transaction,

    -- * Ledger
    module App.Ports.Output.Ledger,

    -- * Closing
    module App.Ports.Output.Closing,

    -- * Financial Statement
    module App.Ports.Output.FinancialStatement,
)
where

import App.Ports.Output.Closing
import App.Ports.Output.FinancialStatement
import App.Ports.Output.IAM
import App.Ports.Output.Ledger
import App.Ports.Output.Transaction
