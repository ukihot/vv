{-# LANGUAGE ScopedTypeVariables #-}

{- | ユーザー一覧取得ユースケース
CQRS原則に従い、acid-stateのReadModelから読み取り専用でクエリを実行する。
WriteモデルのEventStoreには一切アクセスしない。
-}
module App.UseCase.IAM.ListUsers (
    executeListUsers,
    ListUsersEnv (..),
) where

import App.DTO.Response.IAM (UserListResponse (..), UserResponse (..))
import App.Ports.Query.IAM (ListUsersRequest (..))
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Text (Text)
import Infra.Read.IAM (UserRecord (..))

-- ─────────────────────────────────────────────────────────────────────────────
-- Query環境レコード（Handle パターン）
-- ─────────────────────────────────────────────────────────────────────────────

data ListUsersEnv m = ListUsersEnv
    { -- ReadModel Query Port
      envQueryAllUsers :: m [UserRecord]
    , envQueryUsersByFilter :: Text -> m [UserRecord]
    }

-- ─────────────────────────────────────────────────────────────────────────────
-- ユーザー一覧取得ユースケース
-- ─────────────────────────────────────────────────────────────────────────────

executeListUsers ::
    forall m.
    MonadIO m =>
    ListUsersEnv m ->
    ListUsersRequest ->
    m UserListResponse
executeListUsers env req = do
    -- デバッグログは一旦削除（UIを崩さないため）

    -- ReadModelからユーザー一覧を取得
    allUsers <- case listUsersReqFilter req of
        Nothing -> envQueryAllUsers env
        Just filterText -> envQueryUsersByFilter env filterText

    -- ページネーション適用
    let offset = listUsersReqOffset req
        limit = listUsersReqLimit req
        total = length allUsers
        pagedUsers = take limit $ drop offset allUsers

    -- UserRecord → UserResponse 変換
    let userResponses = map toUserResponse pagedUsers

    pure
        UserListResponse
            { userListItems = userResponses
            , userListTotal = total
            , userListOffset = offset
            , userListLimit = limit
            }

-- ─────────────────────────────────────────────────────────────────────────────
-- 変換ヘルパー
-- ─────────────────────────────────────────────────────────────────────────────

toUserResponse :: UserRecord -> UserResponse
toUserResponse ur =
    UserResponse
        { userResponseId = urId ur
        , userResponseName = urName ur
        , userResponseEmail = urEmail ur
        , userResponseStatus = urStatus ur
        , userResponseRoles = urRoles ur
        , userResponseCreatedAt = read "2026-04-16 00:00:00 UTC" -- TODO: 実際の値
        , userResponseUpdatedAt = Nothing -- TODO: 実際の値
        }
