{-# LANGUAGE ImportQualifiedPost #-}

module Adapter.View.Components.Modal
    ( renderConfirmModal
    , renderAlertModal
    , renderInfoModal
    , renderModalOverlay
    ) where

import Brick
import Brick.Widgets.Border qualified as Border
import Brick.Widgets.Center (center, hCenter)
import Data.Text (Text)

renderConfirmModal :: Text -> Text -> Widget n
renderConfirmModal title message =
    renderModalOverlay $
        Border.borderWithLabel (txt (" " <> title <> " ")) $
            padAll 2 $
                vBox
                    [ txt message,
                      padTop (Pad 2) $
                        hCenter $
                            hBox
                                [ withAttr (attrName "buttonPrimary") $ txt " Yes (y) ",
                                  str "  ",
                                  withAttr (attrName "buttonSecondary") $ txt " No (n) "
                                ]
                    ]

renderAlertModal :: Text -> Text -> Widget n
renderAlertModal title message =
    renderModalOverlay $
        Border.borderWithLabel (txt (" ⚠ " <> title <> " ")) $
            padAll 2 $
                vBox
                    [ withAttr (attrName "alertMessage") $ txt message,
                      padTop (Pad 2) $
                        hCenter $
                            withAttr (attrName "buttonPrimary") $
                                txt " OK (Enter) "
                    ]

renderInfoModal :: Text -> Text -> Widget n
renderInfoModal title message =
    renderModalOverlay $
        Border.borderWithLabel (txt (" ℹ " <> title <> " ")) $
            padAll 2 $
                vBox
                    [ txt message,
                      padTop (Pad 2) $
                        hCenter $
                            withAttr (attrName "buttonPrimary") $
                                txt " OK (Enter) "
                    ]

renderModalOverlay :: Widget n -> Widget n
renderModalOverlay content =
    center $
        hLimit 60 $
            vLimit 10 $
                withAttr (attrName "modalOverlay") content
