{-# LANGUAGE ImportQualifiedPost #-}

{- | テーブルコンポーネント
データグリッド、一覧表示、ソート、ページネーション等。
-}
module Adapter.View.Components.Table (
    -- * Table Rendering
    renderTable,
    renderTableHeader,
    renderTableRow,
    renderTableCell,

    -- * Pagination
    renderPagination,

    -- * Empty State
    renderEmptyTable,
)
where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    hBox,
    padBottom,
    padLeft,
    padRight,
    padTop,
    str,
    txt,
    vBox,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Data.Text (Text)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Table Rendering
-- ─────────────────────────────────────────────────────────────────────────────

-- | テーブル全体
renderTable ::
    -- | ヘッダー
    [Text] ->
    -- | 行データ
    [[Text]] ->
    Widget n
renderTable headers rows =
    Border.border $
        vBox
            [ renderTableHeader headers
            , Border.hBorder
            , vBox (map renderTableRow rows)
            ]

-- | テーブルヘッダー
renderTableHeader :: [Text] -> Widget n
renderTableHeader headers =
    withAttr (attrName "tableHeader") $
        hBox (map renderHeaderCell headers)

renderHeaderCell :: Text -> Widget n
renderHeaderCell header =
    padLeft (Pad 1) $
        padRight (Pad 1) $
            txt header

-- | テーブル行
renderTableRow :: [Text] -> Widget n
renderTableRow cells =
    padBottom (Pad 1) $
        hBox (map renderTableCell cells)

-- | テーブルセル
renderTableCell :: Text -> Widget n
renderTableCell cell =
    padLeft (Pad 1) $
        padRight (Pad 1) $
            txt cell

-- ─────────────────────────────────────────────────────────────────────────────
-- Pagination
-- ─────────────────────────────────────────────────────────────────────────────

-- | ページネーション
renderPagination ::
    -- | 現在ページ
    Int ->
    -- | 総ページ数
    Int ->
    Widget n
renderPagination currentPage totalPages =
    withAttr (attrName "pagination") $
        hBox
            [ txt "◀ Prev"
            , padLeft (Pad 2) $
                padRight (Pad 2) $
                    txt (T.pack (show currentPage) <> " / " <> T.pack (show totalPages))
            , txt "Next ▶"
            ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Empty State
-- ─────────────────────────────────────────────────────────────────────────────

-- | 空のテーブル表示
renderEmptyTable :: Text -> Widget n
renderEmptyTable message =
    Border.border $
        padLeft (Pad 2) $
            padRight (Pad 2) $
                padBottom (Pad 1) $
                    padTop (Pad 1) $
                        withAttr (attrName "emptyState") $
                            txt message
