{-# LANGUAGE ImportQualifiedPost #-}

module Common.UI.Layout (
    renderCard,
    renderPanel,
    renderSection,
    renderSpacer,
    renderDivider,
    renderTwoColumn,
    renderThreeColumn,
) where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    hBox,
    hLimit,
    padAll,
    padLeft,
    padTop,
    txt,
    vBox,
    vLimit,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Data.Text (Text)

renderCard :: Maybe Text -> Widget n -> Widget n
renderCard Nothing content =
    Border.border $
        padAll 1 content
renderCard (Just title) content =
    Border.borderWithLabel (txt (" " <> title <> " ")) $
        padAll 1 content

renderPanel :: Text -> Widget n -> Widget n
renderPanel title content =
    vBox
        [ withAttr (attrName "panelTitle") $ txt title
        , padLeft (Pad 2) content
        ]

renderSection :: Text -> Widget n -> Widget n
renderSection title content =
    vBox
        [ withAttr (attrName "sectionTitle") $ txt ("# " <> title)
        , padTop (Pad 1) $
            padLeft (Pad 2) content
        ]

renderSpacer :: Int -> Widget n
renderSpacer n = vLimit n $ txt ""

renderDivider :: Widget n
renderDivider = Border.hBorder

renderTwoColumn :: Widget n -> Widget n -> Widget n
renderTwoColumn left right =
    hBox
        [ hLimit 40 left
        , padLeft (Pad 2) right
        ]

renderThreeColumn :: Widget n -> Widget n -> Widget n -> Widget n
renderThreeColumn left center right =
    hBox
        [ hLimit 30 left
        , padLeft (Pad 1) $ hLimit 40 center
        , padLeft (Pad 1) right
        ]
