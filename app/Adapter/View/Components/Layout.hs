{-# LANGUAGE ImportQualifiedPost #-}

{- | レイアウトコンポーネント
カード、パネル、セクション等のレイアウト要素。
-}
module Adapter.View.Components.Layout (
    -- * Containers
    renderCard,
    renderPanel,
    renderSection,

    -- * Spacing
    renderSpacer,
    renderDivider,

    -- * Grid
    renderTwoColumn,
    renderThreeColumn,
)
where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    hBox,
    hLimit,
    padAll,
    padBottom,
    padLeft,
    padRight,
    padTop,
    str,
    txt,
    vBox,
    vLimit,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Data.Text (Text)

-- ─────────────────────────────────────────────────────────────────────────────
-- Containers
-- ─────────────────────────────────────────────────────────────────────────────

-- | カード（枠線付きコンテナ）
renderCard ::
    -- | タイトル
    Maybe Text ->
    -- | コンテンツ
    Widget n ->
    Widget n
renderCard Nothing content =
    Border.border $
        padAll 1 content
renderCard (Just title) content =
    Border.borderWithLabel (txt (" " <> title <> " ")) $
        padAll 1 content

-- | パネル（背景色付きコンテナ）
renderPanel ::
    Text ->
    Widget n ->
    Widget n
renderPanel title content =
    vBox
        [ withAttr (attrName "panelTitle") $ txt title
        , padLeft (Pad 2) content
        ]

-- | セクション（見出し付きコンテンツ）
renderSection ::
    Text ->
    Widget n ->
    Widget n
renderSection title content =
    vBox
        [ withAttr (attrName "sectionTitle") $ txt ("■ " <> title)
        , padTop (Pad 1) $
            padLeft (Pad 2) content
        ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Spacing
-- ─────────────────────────────────────────────────────────────────────────────

-- | スペーサー（垂直方向の余白）
renderSpacer :: Int -> Widget n
renderSpacer n = vLimit n $ str ""

-- | 区切り線
renderDivider :: Widget n
renderDivider = Border.hBorder

-- ─────────────────────────────────────────────────────────────────────────────
-- Grid Layout
-- ─────────────────────────────────────────────────────────────────────────────

-- | 2カラムレイアウト
renderTwoColumn ::
    -- | 左カラム
    Widget n ->
    -- | 右カラム
    Widget n ->
    Widget n
renderTwoColumn left right =
    hBox
        [ hLimit 40 left
        , padLeft (Pad 2) right
        ]

-- | 3カラムレイアウト
renderThreeColumn ::
    Widget n ->
    Widget n ->
    Widget n ->
    Widget n
renderThreeColumn left center right =
    hBox
        [ hLimit 30 left
        , padLeft (Pad 1) $ hLimit 40 center
        , padLeft (Pad 1) right
        ]
