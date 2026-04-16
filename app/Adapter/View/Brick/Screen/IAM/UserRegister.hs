{-# LANGUAGE ImportQualifiedPost #-}

{- | ユーザー登録画面
新規ユーザーの登録フォーム。
-}
module Adapter.View.Brick.Screen.IAM.UserRegister (
    renderUserRegisterScreen,
) where

import Adapter.View.Brick.Types (Name (..), UiState (..))
import Adapter.View.Components.Button (renderPrimaryButton)
import Adapter.View.Components.Form (renderTextInput)
import Adapter.View.Components.Layout (renderCard, renderSpacer)
import Brick (Padding (Pad), Widget, attrName, padTop, txt, vBox, withAttr)

-- ─────────────────────────────────────────────────────────────────────────────
-- User Register Screen
-- ─────────────────────────────────────────────────────────────────────────────

renderUserRegisterScreen :: UiState -> Widget Name
renderUserRegisterScreen st =
    renderCard (Just "User Registration") $
        vBox
            [ renderTextInput "Name" (uiUserNameEditor st) (uiCurrentFocus st == UserNameField)
            , renderSpacer 1
            , renderTextInput "Email" (uiUserEmailEditor st) (uiCurrentFocus st == UserEmailField)
            , renderSpacer 1
            , renderTextInput "Role" (uiUserRoleEditor st) (uiCurrentFocus st == UserRoleField)
            , padTop (Pad 2) $
                renderPrimaryButton "Register User" "Enter"
            , renderSpacer 1
            , withAttr (attrName "hint") $ txt "Tab/Shift+Tab: Navigate fields, Enter: Register"
            ]
