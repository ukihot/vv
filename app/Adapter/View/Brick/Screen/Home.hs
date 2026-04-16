{-# LANGUAGE ImportQualifiedPost #-}

{- | ホーム画面
アプリケーションのメイン画面。
-}
module Adapter.View.Brick.Screen.Home (
    renderHomeScreen,
) where

import Adapter.View.Brick.Types (Name (..), UiState (..))
import Adapter.View.Components.Layout (
    renderCard,
    renderSection,
    renderSpacer,
 )
import Brick (Widget, txt, vBox)

-- ─────────────────────────────────────────────────────────────────────────────
-- Home Screen
-- ─────────────────────────────────────────────────────────────────────────────

renderHomeScreen :: UiState -> Widget Name
renderHomeScreen _st =
    renderCard (Just "Home") $
        vBox
            [ renderSection "Welcome to VV!" $
                vBox
                    [ txt "IFRS-based Accounting System"
                    , renderSpacer 1
                    , txt "Built with Haskell + Event Sourcing + CQRS"
                    ]
            , renderSpacer 1
            , renderSection "Quick Start" $
                vBox
                    [ txt "• Press 'n' to open navigation menu"
                    , txt "• Press 'Tab' to switch domain tabs"
                    , txt "• Press 'Esc' to go back"
                    , txt "• Press 'q' to quit"
                    ]
            ]
