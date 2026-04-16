{-# LANGUAGE ImportQualifiedPost #-}

{- | プレースホルダー画面
未実装画面用の汎用プレースホルダー。
-}
module Adapter.View.Brick.Screen.Placeholder (
    renderPlaceholderScreen,
) where

import Adapter.View.Brick.Types (Name (..), UiState (..))
import Adapter.View.Components.Layout (renderCard, renderSpacer)
import Brick (Widget, attrName, txt, vBox, withAttr)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Placeholder Screen
-- ─────────────────────────────────────────────────────────────────────────────

renderPlaceholderScreen :: String -> String -> UiState -> Widget Name
renderPlaceholderScreen title description _st =
    renderCard (Just (T.pack title)) $
        vBox
            [ txt (T.pack description)
            , renderSpacer 1
            , withAttr (attrName "hint") $ txt "This screen is not yet implemented."
            ]
