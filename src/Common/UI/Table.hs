{-# LANGUAGE ImportQualifiedPost #-}

module Common.UI.Table (
    renderTable,
    renderTableHeader,
    renderTableRow,
    renderTableCell,
    renderPagination,
    renderEmptyTable,
) where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    hBox,
    padBottom,
    padLeft,
    padRight,
    padTop,
    txt,
    vBox,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Data.Text (Text)
import Data.Text qualified as T

renderTable :: [Text] -> [[Text]] -> Widget n
renderTable headers rows =
    Border.border $
        vBox
            [ renderTableHeader headers
            , Border.hBorder
            , vBox (map renderTableRow rows)
            ]

renderTableHeader :: [Text] -> Widget n
renderTableHeader headers =
    withAttr (attrName "tableHeader") $
        hBox (map renderHeaderCell headers)

renderHeaderCell :: Text -> Widget n
renderHeaderCell header =
    padLeft (Pad 1) $
        padRight (Pad 1) $
            txt header

renderTableRow :: [Text] -> Widget n
renderTableRow cells =
    padBottom (Pad 1) $
        hBox (map renderTableCell cells)

renderTableCell :: Text -> Widget n
renderTableCell cell =
    padLeft (Pad 1) $
        padRight (Pad 1) $
            txt cell

renderPagination :: Int -> Int -> Widget n
renderPagination currentPage totalPages =
    withAttr (attrName "pagination") $
        hBox
            [ txt "< Prev"
            , padLeft (Pad 2) $
                padRight (Pad 2) $
                    txt (T.pack (show currentPage) <> " / " <> T.pack (show totalPages))
            , txt "Next >"
            ]

renderEmptyTable :: Text -> Widget n
renderEmptyTable message =
    Border.border $
        padLeft (Pad 2) $
            padRight (Pad 2) $
                padBottom (Pad 1) $
                    padTop (Pad 1) $
                        withAttr (attrName "emptyState") $
                            txt message
