{-# LANGUAGE ImportQualifiedPost #-}

{- | ユーザー一覧画面
登録済みユーザーの一覧表示とフィルタリング。
-}
module Adapter.View.Brick.Screen.IAM.UserList (
    renderUserListScreen,
) where

import Adapter.View.Brick.Types (Name (..), UiState (..))
import Adapter.View.Components.Layout (renderCard, renderSection, renderSpacer)
import Adapter.View.Components.Table (renderTable)
import App.DTO.Response.IAM (UserListResponse (..), UserResponse (..))
import Brick (Widget, attrName, txt, vBox, withAttr)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- User List Screen
-- ─────────────────────────────────────────────────────────────────────────────

renderUserListScreen :: UiState -> Widget Name
renderUserListScreen st =
    renderCard (Just "User List") $
        case uiUserList st of
            Nothing ->
                vBox
                    [ txt "Loading users..."
                    , renderSpacer 1
                    , withAttr (attrName "hint") $ txt "Press 'r' to refresh"
                    ]
            Just userListResp ->
                vBox
                    [ renderSection ("Users (" <> T.pack (show (userListTotal userListResp)) <> " total)") $
                        renderUserTable (userListItems userListResp)
                    , renderSpacer 1
                    , withAttr (attrName "hint") $ txt "Press 'r' to refresh, 'n' to register new user"
                    ]

renderUserTable :: [UserResponse] -> Widget Name
renderUserTable users =
    renderTable
        ["ID", "Name", "Email", "Status", "Roles"]
        (map userToRow users)
    where
        userToRow :: UserResponse -> [T.Text]
        userToRow user =
            [ userResponseId user
            , userResponseName user
            , userResponseEmail user
            , userResponseStatus user
            , T.intercalate ", " (userResponseRoles user)
            ]
