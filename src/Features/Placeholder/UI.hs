{-# LANGUAGE ImportQualifiedPost #-}

module Features.Placeholder.UI (
    draw,
) where

import Brick (Widget, attrName, txt, vBox, withAttr)
import Common.UI.Layout (renderCard, renderSpacer)
import Data.Text (Text)

draw :: Text -> Text -> Widget n
draw title description =
    renderCard (Just title) $
        vBox
            [ txt description
            , renderSpacer 1
            , withAttr (attrName "hint") $ txt "This screen is not yet implemented."
            ]
