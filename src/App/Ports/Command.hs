{- | Command Port - Write-side Use Cases

This module re-exports all command use cases organized by functional domain.
Commands represent write operations that change system state.

Organization follows the business requirements and IFRS accounting processes:
- IAM: Identity and Access Management
- Organization: Organizational structure and roles
- MasterData: Chart of accounts, exchange rates, policies
- Transaction: Daily journal entries and cash logs
- Ledger: General and subsidiary ledger aggregation
- Closing: Period closing and calendar management
- Adjustment: Account adjustments and reclassifications
- Valuation: IFRS valuation processes (ECL, impairment, fair value)
- Revenue: IFRS 15 revenue recognition (5-step model)
- FixedAsset: IAS 16/38 fixed asset management
- Lease: IFRS 16 lease accounting
- FinancialStatement: Financial statement generation
- Workflow: Approval workflow management
- Audit: Audit trail and prior period error correction
- Consolidation: Consolidation eliminations and goodwill
- Tax: Corporate tax and deferred tax
- Reproducibility: Calculation reproducibility (Chapter 7 compliance)
- Management: Management accounting and KPIs
-}
module App.Ports.Command (
    -- * IAM
    module App.Ports.Command.IAM,

    -- * Organization
    module App.Ports.Command.Organization,

    -- * Master Data
    module App.Ports.Command.MasterData,

    -- * Transaction
    module App.Ports.Command.Transaction,

    -- * Ledger
    module App.Ports.Command.Ledger,

    -- * Closing
    module App.Ports.Command.Closing,

    -- * Adjustment
    module App.Ports.Command.Adjustment,

    -- * Valuation
    module App.Ports.Command.Valuation,

    -- * Revenue
    module App.Ports.Command.Revenue,

    -- * Fixed Asset
    module App.Ports.Command.FixedAsset,

    -- * Lease
    module App.Ports.Command.Lease,

    -- * Financial Statement
    module App.Ports.Command.FinancialStatement,

    -- * Workflow
    module App.Ports.Command.Workflow,

    -- * Audit
    module App.Ports.Command.Audit,

    -- * Consolidation
    module App.Ports.Command.Consolidation,

    -- * Tax
    module App.Ports.Command.Tax,

    -- * Reproducibility
    module App.Ports.Command.Reproducibility,

    -- * Management
    module App.Ports.Command.Management,
)
where

import App.Ports.Command.Adjustment
import App.Ports.Command.Audit
import App.Ports.Command.Closing
import App.Ports.Command.Consolidation
import App.Ports.Command.FinancialStatement
import App.Ports.Command.FixedAsset
import App.Ports.Command.IAM
import App.Ports.Command.Lease
import App.Ports.Command.Ledger
import App.Ports.Command.Management
import App.Ports.Command.MasterData
import App.Ports.Command.Organization
import App.Ports.Command.Reproducibility
import App.Ports.Command.Revenue
import App.Ports.Command.Tax
import App.Ports.Command.Transaction
import App.Ports.Command.Valuation
import App.Ports.Command.Workflow
