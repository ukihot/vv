{- | Query Port - Read-side Use Cases

This module re-exports all query use cases organized by functional domain.
Queries represent read operations that do not change system state (CQRS pattern).

Organization follows the business requirements and IFRS accounting processes:
- IAM: User and permission queries
- Organization: Organizational structure queries
- MasterData: Chart of accounts, exchange rates, policies
- Transaction: Journal entries and cash logs
- Ledger: General and subsidiary ledger balances
- Closing: Period closing status and checklists
- FinancialStatement: Financial statements and notes

Additional query modules can be added as needed for:
- Valuation, Revenue, FixedAsset, Lease
- Workflow, Audit, Consolidation, Tax
- Reproducibility, Management
-}
module App.Ports.Query (
    -- * IAM
    module App.Ports.Query.IAM,

    -- * Organization
    module App.Ports.Query.Organization,

    -- * Master Data
    module App.Ports.Query.MasterData,

    -- * Transaction
    module App.Ports.Query.Transaction,

    -- * Ledger
    module App.Ports.Query.Ledger,

    -- * Closing
    module App.Ports.Query.Closing,

    -- * Financial Statement
    module App.Ports.Query.FinancialStatement,
)
where

import App.Ports.Query.Closing
import App.Ports.Query.FinancialStatement
import App.Ports.Query.IAM
import App.Ports.Query.Ledger
import App.Ports.Query.MasterData
import App.Ports.Query.Organization
import App.Ports.Query.Transaction
