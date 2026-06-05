{- | IAM Projector
Write 側（SQLite）へのイベント書き込み完了後、TBQueue 経由で通知を受け取り、
acid-state の Read モデルを非同期で更新する。

起動順序（アプリケーション起動時に厳守）:
  1. openLocalState でacid-state を開く
  2. replayFromSqlite で差分をリプレイ（SQLite に追いつかせる）
  3. newProjectionQueue でキューを生成
  4. startIamProjector でスレッドを起動
  ※ 2 と 4 の間にイベントが発生しても TBQueue に積まれるため問題ない

Eventually Consistent: Write のコミット完了後、Projector が処理するまでの間、
Read モデルは古い状態を返す可能性がある。
最新性が必要な場合は Write 側（SQLite）に直接問い合わせること。
-}
module Infra.Write.Projection (
    -- * キュー型
    ProjectionQueue,
    ProjectionEvent (..),
    newProjectionQueue,

    -- * Projector 起動
    startIamProjector,

    -- * 再起動時リプレイ
    replayFromSqlite,
) where

import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.STM (atomically)
import Control.Concurrent.STM.TBQueue (
    TBQueue,
    newTBQueueIO,
    readTBQueue,
 )
import Control.Exception (SomeException, catch)
import Control.Monad (forever)
import Data.Acid (AcidState, query, update)
import Data.Text (Text)
import Database.Persist (Entity (..), SelectOpt (Asc), selectList, (>.))
import Database.Persist.Sqlite (ConnectionPool, runSqlPool)
import Infra.Read.IAM (
    ApplyPermissionEvent (..),
    ApplyRoleEvent (..),
    ApplyUserEvent (..),
    GetLastPermissionSeq (..),
    GetLastRoleSeq (..),
    GetLastUserSeq (..),
    IamReadModel,
 )
import Infra.Write.Schema (
    EntityField (..),
    PermissionEvent (..),
    RoleEvent (..),
    UserEvent (..),
 )

-- ─────────────────────────────────────────────────────────────────────────────
-- キュー型
-- ─────────────────────────────────────────────────────────────────────────────

-- | Projector に送るイベント通知
data ProjectionEvent
    = UserEventAppended
        { peUserSeq :: Int
        , peUserEventType :: Text
        , peUserPayload :: Text
        }
    | RoleEventAppended
        { peRoleSeq :: Int
        , peRoleEventType :: Text
        , peRolePayload :: Text
        }
    | PermissionEventAppended
        { pePermSeq :: Int
        , pePermEventType :: Text
        , pePermPayload :: Text
        }

-- | Projector への通知キュー（bounded: バックプレッシャーあり）
type ProjectionQueue = TBQueue ProjectionEvent

-- | キューを生成する（容量 1024）
newProjectionQueue :: IO ProjectionQueue
newProjectionQueue = newTBQueueIO 1024

-- ─────────────────────────────────────────────────────────────────────────────
-- Projector 起動
-- ─────────────────────────────────────────────────────────────────────────────

{- | IAM Projector スレッドを起動する。
forkIO で起動し、TBQueue からイベントを受け取り acid-state を更新する。
例外が発生してもスレッドを再起動し、静かに終了しない。
アプリケーション起動時に一度だけ呼ぶ。
-}
startIamProjector :: AcidState IamReadModel -> ProjectionQueue -> IO ()
startIamProjector acidSt queue = do
    _ <- forkIO $ runProjector
    pure ()
    where
        runProjector = forever $ do
            event <- atomically $ readTBQueue queue
            applyProjectionEvent acidSt event
                `catch` \(_ :: SomeException) -> do
                    -- 例外をログに出力してスレッドを継続（静かに終了させない）
                    -- putStrLn は UI を崩すため削除
                    -- TODO: 適切なログシステムに置き換え
                    -- 短いバックオフ後に次のイベントへ
                    threadDelay 100000 -- 100ms

-- | キューから受け取ったイベントを acid-state に適用する
applyProjectionEvent :: AcidState IamReadModel -> ProjectionEvent -> IO ()
applyProjectionEvent acidSt (UserEventAppended seq' evType payload) = do
    -- ファイルにデバッグログを出力（UIを崩さない）
    appendFile "data/projection.log" $
        "[Projector] Applying UserEvent: seq="
            <> show seq'
            <> " type="
            <> show evType
            <> " payload="
            <> show payload
            <> "\n"
    update acidSt (ApplyUserEvent seq' evType payload)
applyProjectionEvent acidSt (RoleEventAppended seq' evType payload) = do
    appendFile "data/projection.log" $
        "[Projector] Applying RoleEvent: seq=" <> show seq' <> " type=" <> show evType <> "\n"
    update acidSt (ApplyRoleEvent seq' evType payload)
applyProjectionEvent acidSt (PermissionEventAppended seq' evType payload) = do
    appendFile "data/projection.log" $
        "[Projector] Applying PermissionEvent: seq=" <> show seq' <> " type=" <> show evType <> "\n"
    update acidSt (ApplyPermissionEvent seq' evType payload)

-- ─────────────────────────────────────────────────────────────────────────────
-- 再起動時リプレイ
-- ─────────────────────────────────────────────────────────────────────────────

{- | 再起動時に SQLite と acid-state の差分をリプレイする。
acid-state が保持する最終反映済みシーケンス番号より大きい version を持つ
イベントのみを SQLite から取得し、順序通りに適用する。
アプリケーション起動時、startIamProjector の前に呼ぶ。
-}
replayFromSqlite :: ConnectionPool -> AcidState IamReadModel -> IO ()
replayFromSqlite pool acidSt = do
    replayUsers
    replayRoles
    replayPermissions
    where
        replayUsers = do
            lastSeq <- query acidSt GetLastUserSeq
            -- SQLite 側でフィルタリング（全件取得を避ける）
            rows <-
                runSqlPool
                    (selectList [UserEventVersion >. lastSeq] [Asc UserEventVersion])
                    pool
            mapM_
                ( \(i, row) ->
                    update acidSt $
                        ApplyUserEvent
                            (lastSeq + i + 1)
                            (userEventEventType row)
                            (userEventPayload row)
                )
                (zip [0 ..] (map entityVal rows))

        replayRoles = do
            lastSeq <- query acidSt GetLastRoleSeq
            rows <-
                runSqlPool
                    (selectList [RoleEventVersion >. lastSeq] [Asc RoleEventVersion])
                    pool
            mapM_
                ( \(i, row) ->
                    update acidSt $
                        ApplyRoleEvent
                            (lastSeq + i + 1)
                            (roleEventEventType row)
                            (roleEventPayload row)
                )
                (zip [0 ..] (map entityVal rows))

        replayPermissions = do
            lastSeq <- query acidSt GetLastPermissionSeq
            rows <-
                runSqlPool
                    (selectList [PermissionEventVersion >. lastSeq] [Asc PermissionEventVersion])
                    pool
            mapM_
                ( \(i, row) ->
                    update acidSt $
                        ApplyPermissionEvent
                            (lastSeq + i + 1)
                            (permissionEventEventType row)
                            (permissionEventPayload row)
                )
                (zip [0 ..] (map entityVal rows))
