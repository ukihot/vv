{-# LANGUAGE ImportQualifiedPost #-}

module Features.Home.UI (
    draw,
) where

import Brick (Widget, txt, vBox)
import Common.UI.Layout (renderCard, renderSection, renderSpacer)

draw :: Widget n
draw =
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
                    [ txt "- Press 'n' to open navigation menu"
                    , txt "- Press 'Tab' to switch domain tabs"
                    , txt "- Press 'Esc' to go back"
                    , txt "- Press 'q' to quit"
                    ]
            ]
