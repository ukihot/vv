{- | 決算プロセス集約ルートエンティティ
月次・四半期・年次決算の承認フローを型安全に管理する。
-}
module Domain.Audit.ClosingProcess
    ( -- * 集約
      ClosingProcess (..)
    , ClosingState (..)
    , SomeClosingProcess (..)

      -- * 値オブジェクト
    , module Domain.Audit.ClosingProcess.ValueObjects.ClosingProcessId

      -- * 状態遷移
    , startClosingProcess
    , submitForApproval
    , approve
    , finalize
    )
where

import Data.Time (UTCTime)
import Domain.Audit.ClosingProcess.Events (ClosingProcessEventPayload (..))
import Domain.Audit.ClosingProcess.ValueObjects.ClosingProcessId
import Domain.Audit.ClosingProcess.ValueObjects.ClosingState (ClosingState (..))
import Domain.Audit.ClosingProcess.ValueObjects.Version (Version, initialVersion, nextVersion)
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.Shared (FiscalYearMonth)

-- ─────────────────────────────────────────────────────────────────────────────
-- 決算プロセス集約 GADT
-- ─────────────────────────────────────────────────────────────────────────────

data ClosingProcess (s :: ClosingState) where
    CPInProgress ::
        ClosingProcessId ->
        FiscalYearMonth ->
        UTCTime ->
        UserId ->
        Version ->
        ClosingProcess 'InProgress
    CPPendingApproval ::
        ClosingProcessId ->
        FiscalYearMonth ->
        UTCTime ->
        UserId ->
        Version ->
        ClosingProcess 'PendingApproval
    CPApproved ::
        ClosingProcessId ->
        FiscalYearMonth ->
        UTCTime ->
        UserId ->
        Maybe UserId ->
        Version ->
        ClosingProcess 'Approved
    CPFinalized ::
        ClosingProcessId ->
        FiscalYearMonth ->
        UTCTime ->
        UserId ->
        Maybe UserId ->
        Version ->
        ClosingProcess 'Finalized

deriving instance Show (ClosingProcess s)
deriving instance Eq (ClosingProcess s)

data SomeClosingProcess where
    SomeCP :: ClosingProcess s -> SomeClosingProcess

deriving instance Show SomeClosingProcess

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移
-- ─────────────────────────────────────────────────────────────────────────────

startClosingProcess ::
    ClosingProcessId ->
    FiscalYearMonth ->
    UTCTime ->
    UserId ->
    (ClosingProcess 'InProgress, ClosingProcessEventPayload)
startClosingProcess cpId period timestamp actorId =
    ( CPInProgress cpId period timestamp actorId initialVersion,
      ClosingProcessStarted cpId period actorId
    )

submitForApproval ::
    ClosingProcess 'InProgress ->
    (ClosingProcess 'PendingApproval, ClosingProcessEventPayload)
submitForApproval (CPInProgress cpId period timestamp actorId v) =
    ( CPPendingApproval cpId period timestamp actorId (nextVersion v),
      ClosingProcessStateChanged cpId PendingApproval actorId
    )

approve ::
    UserId ->
    ClosingProcess 'PendingApproval ->
    (ClosingProcess 'Approved, ClosingProcessEventPayload)
approve approverId (CPPendingApproval cpId period timestamp actorId v) =
    ( CPApproved cpId period timestamp actorId (Just approverId) (nextVersion v),
      ClosingProcessStateChanged cpId Approved approverId
    )

finalize ::
    ClosingProcess 'Approved ->
    (ClosingProcess 'Finalized, ClosingProcessEventPayload)
finalize (CPApproved cpId period timestamp actorId approverId v) =
    ( CPFinalized cpId period timestamp actorId approverId (nextVersion v),
      ClosingProcessFinalized cpId actorId
    )
