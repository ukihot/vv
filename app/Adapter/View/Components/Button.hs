{-# LANGUAGE ImportQualifiedPost #-}

{- | ボタンコンポーネント
プライマリボタン、セカンダリボタン、危険ボタン等。
-}
module Adapter.View.Components.Button (
    -- * Button Types
    renderPrimaryButton,
    renderSecondaryButton,
    renderDangerButton,
    renderLinkButton,

    -- * Button States
    renderDisabledButton,
    renderLoadingButton,
)
where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    padLeft,
    padRight,
    str,
    txt,
    withAttr,
 )
import Data.Text (Text)

-- ─────────────────────────────────────────────────────────────────────────────
-- Button Types
-- ─────────────────────────────────────────────────────────────────────────────

-- | プライマリボタン（主要アクション）
renderPrimaryButton :: Text -> Text -> Widget n
renderPrimaryButton label hint =
    withAttr (attrName "buttonPrimary") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> " (" <> hint <> ")")

-- | セカンダリボタン（補助アクション）
renderSecondaryButton :: Text -> Text -> Widget n
renderSecondaryButton label hint =
    withAttr (attrName "buttonSecondary") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> " (" <> hint <> ")")

-- | 危険ボタン（削除等の破壊的アクション）
renderDangerButton :: Text -> Text -> Widget n
renderDangerButton label hint =
    withAttr (attrName "buttonDanger") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt (label <> " (" <> hint <> ")")

-- | リンクボタン（テキストリンク風）
renderLinkButton :: Text -> Widget n
renderLinkButton label =
    withAttr (attrName "buttonLink") $
        txt label

-- ─────────────────────────────────────────────────────────────────────────────
-- Button States
-- ─────────────────────────────────────────────────────────────────────────────

-- | 無効化ボタン
renderDisabledButton :: Text -> Widget n
renderDisabledButton label =
    withAttr (attrName "buttonDisabled") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt label

-- | ローディング中ボタン
renderLoadingButton :: Text -> Widget n
renderLoadingButton label =
    withAttr (attrName "buttonLoading") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                txt ("⏳ " <> label <> "...")
