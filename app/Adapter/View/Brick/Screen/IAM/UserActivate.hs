{-# LANGUAGE ImportQualifiedPost #-}

{- | ユーザー有効化画面
ユーザーIDを入力してユーザーを有効化する。
-}
module Adapter.View.Brick.Screen.IAM.UserActivate (
    renderUserActivateScreen,
) where

import Adapter.View.Brick.Types (Name (..), UiState (..))
import Adapter.View.Components.Button (renderPrimaryButton)
import Adapter.View.Components.Form (renderTextInput)
import Adapter.View.Components.Layout (renderCard)
import Brick (Padding (Pad), Widget, padTop, vBox)

-- ─────────────────────────────────────────────────────────────────────────────
-- User Activate Screen
-- ─────────────────────────────────────────────────────────────────────────────

renderUserActivateScreen :: UiState -> Widget Name
renderUserActivateScreen st =
    renderCard (Just "User Activation") $
        vBox
            [ renderTextInput "User ID" (uiUserIdEditor st) True
            , padTop (Pad 1) $
                renderPrimaryButton "Activate" "Enter"
            ]
