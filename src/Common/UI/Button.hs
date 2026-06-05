{-# LANGUAGE ImportQualifiedPost #-}

module Common.UI.Button (
    renderPrimaryButton,
    renderSecondaryButton,
    renderDangerButton,
    renderLinkButton,
    renderDisabledButton,
    renderLoadingButton,
) where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    padLeft,
    padRight,
    txt,
    withAttr,
 )
import Data.Text (Text)

renderPrimaryButton :: Text -> Text -> Widget n
renderPrimaryButton label hint =
    withAttr (attrName "buttonPrimary") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> " (" <> hint <> ")")

renderSecondaryButton :: Text -> Text -> Widget n
renderSecondaryButton label hint =
    withAttr (attrName "buttonSecondary") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> " (" <> hint <> ")")

renderDangerButton :: Text -> Text -> Widget n
renderDangerButton label hint =
    withAttr (attrName "buttonDanger") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> " (" <> hint <> ")")

renderLinkButton :: Text -> Widget n
renderLinkButton label =
    withAttr (attrName "buttonLink") $
        txt label

renderDisabledButton :: Text -> Widget n
renderDisabledButton label =
    withAttr (attrName "buttonDisabled") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt label

renderLoadingButton :: Text -> Widget n
renderLoadingButton label =
    withAttr (attrName "buttonLoading") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> "...")
