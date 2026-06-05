{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserList.UI (
    draw,
) where

import App.DTO.Response.IAM (UserListResponse (..), UserResponse (..))
import Brick (Widget, attrName, txt, vBox, withAttr)
import Common.UI.Layout (renderCard, renderSection, renderSpacer)
import Common.UI.Table (renderTable)
import Data.Text qualified as T
import Features.IAM.UserList.Core (UserListState (..))

draw :: UserListState -> Widget n
draw state =
    renderCard (Just "User List") $
        case ulsUsers state of
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
                    , withAttr (attrName "hint") $ txt "Press 'r' to refresh"
                    ]

renderUserTable :: [UserResponse] -> Widget n
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
