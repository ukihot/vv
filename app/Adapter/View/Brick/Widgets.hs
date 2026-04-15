{-# LANGUAGE ImportQualifiedPost #-}

{- | 共通ウィジェット
パンくずリスト、タブバー、ナビゲーションメニュー等の再利用可能なウィジェット。
-}
module Adapter.View.Brick.Widgets
    ( -- * Layout Widgets
      renderBreadcrumbs
    , renderTabBar
    , renderNavigationMenu
    , renderBackButton
    , renderLogPanel
    )
where

import Adapter.View.Brick.Types
    ( DomainTab (..)
    , Name (..)
    , ScreenInfo (..)
    , UiState (..)
    , getScreensByTab
    )
import Brick
    ( Padding (Pad)
    , Widget
    , attrName
    , hBox
    , padBottom
    , padLeft
    , padRight
    , str
    , txt
    , vBox
    , vLimit
    , withAttr
    )
import Brick.Widgets.Border qualified as Border
import Brick.Widgets.Center (hCenter)
import Control.Concurrent.STM (atomically, readTVar)
import Data.Text (Text)
import System.IO.Unsafe (unsafePerformIO)

-- ─────────────────────────────────────────────────────────────────────────────
-- Breadcrumbs (パンくずリスト)
-- ─────────────────────────────────────────────────────────────────────────────

renderBreadcrumbs :: Text -> Widget Name
renderBreadcrumbs breadcrumbs =
    padBottom (Pad 1) $
        withAttr (attrName "breadcrumbs") $
            txt ("📍 " <> breadcrumbs)

-- ─────────────────────────────────────────────────────────────────────────────
-- Tab Bar (タブバー)
-- ─────────────────────────────────────────────────────────────────────────────

renderTabBar :: DomainTab -> Widget Name
renderTabBar currentTab =
    padBottom (Pad 1) $
        vBox
            [ Border.hBorder,
              hCenter
                ( hBox
                    [ renderTab TabIAM currentTab,
                      str " ",
                      renderTab TabAccounting currentTab,
                      str " ",
                      renderTab TabIFRS currentTab,
                      str " ",
                      renderTab TabOps currentTab,
                      str " ",
                      renderTab TabAudit currentTab,
                      str " ",
                      renderTab TabOrg currentTab
                    ]
                ),
              Border.hBorder
            ]

renderTab :: DomainTab -> DomainTab -> Widget Name
renderTab tab currentTab =
    let label = tabLabel tab
        widget = txt (" " <> label <> " ")
     in if tab == currentTab
            then withAttr (attrName "tabActive") widget
            else withAttr (attrName "tabInactive") widget

tabLabel :: DomainTab -> Text
tabLabel TabIAM = "IAM"
tabLabel TabAccounting = "Accounting"
tabLabel TabIFRS = "IFRS"
tabLabel TabOps = "Operations"
tabLabel TabAudit = "Audit"
tabLabel TabOrg = "Organization"

-- ─────────────────────────────────────────────────────────────────────────────
-- Navigation Menu (ナビゲーションメニュー)
-- ─────────────────────────────────────────────────────────────────────────────

renderNavigationMenu :: DomainTab -> Widget Name
renderNavigationMenu currentTab =
    Border.borderWithLabel (txt " Navigation ") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                vBox $
                    map renderScreenItem (getScreensByTab currentTab)

renderScreenItem :: ScreenInfo -> Widget Name
renderScreenItem info =
    padBottom (Pad 1) $
        vBox
            [ withAttr (attrName "navItem") $ txt ("▸ " <> screenTitle info),
              padLeft (Pad 2) $
                withAttr (attrName "navDescription") $
                    txt (screenDescription info)
            ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Back Button (戻るボタン)
-- ─────────────────────────────────────────────────────────────────────────────

renderBackButton :: Bool -> Widget Name
renderBackButton canGoBack =
    if canGoBack
        then withAttr (attrName "backButton") $ txt "◀ Back (Esc)"
        else withAttr (attrName "backButtonDisabled") $ txt "◀ Back (Esc)"

-- ─────────────────────────────────────────────────────────────────────────────
-- Log Panel (ログパネル)
-- ─────────────────────────────────────────────────────────────────────────────

renderLogPanel :: UiState -> Widget Name
renderLogPanel st =
    Border.borderWithLabel (txt " Log ") $
        vLimit 8 $
            padLeft (Pad 1) $
                padRight (Pad 1) $
                    vBox (map (padBottom (Pad 1) . txt) (takeLast 8 (readLogsSync st)))

-- Presenterの状態を同期的に読み取る（Brick描画時）
readLogsSync :: UiState -> [Text]
readLogsSync st = unsafePerformIO $ atomically $ readTVar (uiLogs st)

takeLast :: Int -> [a] -> [a]
takeLast n xs = drop (length xs - min n (length xs)) xs
