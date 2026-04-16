{-# LANGUAGE ImportQualifiedPost #-}

{- | 共通ウィジェット
ヘッダー、タブバー、ナビゲーションメニュー、ステータスバー等の再利用可能なウィジェット。
洗練されたUI/UXを提供する。
-}
module Adapter.View.Brick.Widgets (
    -- * Layout Widgets
    renderHeader,
    renderBreadcrumbs,
    renderTabBar,
    renderNavigationMenu,
    renderStatusBar,
    renderBackButton,
    renderLogPanel,
    renderKeyMapHelp,
    renderKeyBinding,
)
where

import Adapter.View.Brick.Types (
    DomainTab (..),
    Name (..),
    ScreenInfo (..),
    UiState (..),
    getScreensByTab,
 )
import Brick (
    Padding (Pad),
    Widget,
    attrName,
    hBox,
    hLimit,
    padBottom,
    padLeft,
    padRight,
    padTop,
    str,
    txt,
    vBox,
    vLimit,
    withAttr,
    (<+>),
 )
import Brick.Widgets.Border qualified as Border
import Brick.Widgets.Center (hCenter)
import Control.Concurrent.STM (atomically, readTVar)
import Data.Text (Text)
import Data.Text qualified as T
import System.IO.Unsafe (unsafePerformIO)

-- ─────────────────────────────────────────────────────────────────────────────
-- Header (ヘッダー)
-- ─────────────────────────────────────────────────────────────────────────────

renderHeader :: Widget Name
renderHeader =
    withAttr (attrName "header") $
        padLeft (Pad 2) $
            padRight (Pad 2) $
                hBox
                    [ withAttr (attrName "appTitle") $ txt "VV - IFRS Accounting System"
                    , txt "  "
                    , withAttr (attrName "hint") $ txt "[Press 'h' for help]"
                    ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Breadcrumbs (パンくずリスト)
-- ─────────────────────────────────────────────────────────────────────────────

renderBreadcrumbs :: Text -> Widget Name
renderBreadcrumbs breadcrumbs =
    padLeft (Pad 2) $
        padTop (Pad 1) $
            padBottom (Pad 1) $
                withAttr (attrName "breadcrumbs") $
                    txt ("📍 " <> breadcrumbs)

-- ─────────────────────────────────────────────────────────────────────────────
-- Tab Bar (タブバー)
-- ─────────────────────────────────────────────────────────────────────────────

renderTabBar :: DomainTab -> Widget Name
renderTabBar currentTab =
    padTop (Pad 1) $
        padBottom (Pad 1) $
            hCenter $
                hBox
                    [ renderTab 1 TabIAM currentTab
                    , str "  "
                    , renderTab 2 TabAccounting currentTab
                    , str "  "
                    , renderTab 3 TabIFRS currentTab
                    , str "  "
                    , renderTab 4 TabOps currentTab
                    , str "  "
                    , renderTab 5 TabAudit currentTab
                    , str "  "
                    , renderTab 6 TabOrg currentTab
                    ]

renderTab :: Int -> DomainTab -> DomainTab -> Widget Name
renderTab num tab currentTab =
    let label = tabLabel tab
        numStr = T.pack (show num)
        widget =
            withAttr (attrName "tabNumber") (txt (numStr <> ":"))
                <+> txt " "
                <+> txt label
                <+> txt " "
     in if tab == currentTab
            then withAttr (attrName "tabActive") $ txt " " <+> widget <+> txt " "
            else withAttr (attrName "tabInactive") $ txt " " <+> widget <+> txt " "

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

renderNavigationMenu :: DomainTab -> Int -> Widget Name
renderNavigationMenu currentTab selectedIndex =
    padLeft (Pad 1) $
        padRight (Pad 1) $
            padTop (Pad 1) $
                vBox $
                    zipWith (renderScreenItem selectedIndex) [0 ..] (getScreensByTab currentTab)

renderScreenItem :: Int -> Int -> ScreenInfo -> Widget Name
renderScreenItem selectedIndex index info =
    let isSelected = index == selectedIndex
        prefix = if isSelected then "▶ " else "  "
        titleWidget =
            if isSelected
                then withAttr (attrName "navItemSelected") $ txt (prefix <> screenTitle info)
                else withAttr (attrName "navItem") $ txt (prefix <> screenTitle info)
     in padBottom (Pad 1) $
            vBox
                [ titleWidget
                , padLeft (Pad 2) $
                    withAttr (attrName "navDescription") $
                        txt (screenDescription info)
                ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Status Bar (ステータスバー)
-- ─────────────────────────────────────────────────────────────────────────────

renderStatusBar :: UiState -> Bool -> Widget Name
renderStatusBar _st canGoBack =
    withAttr (attrName "statusBar") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                hBox
                    [ -- キーマップのみ表示（ログは右側のログビューワーに統合）
                      hBox
                        [ renderKeyBinding "q" "Quit"
                        , txt " "
                        , renderKeyBinding "h" "Help"
                        , txt " "
                        , renderKeyBinding "n" "Nav"
                        , txt " "
                        , if canGoBack
                            then renderKeyBinding "Esc" "Back"
                            else withAttr (attrName "hint") $ txt "[Esc:Back]"
                        , txt " "
                        , renderKeyBinding "r" "Refresh"
                        ]
                    ]

renderKeyBinding :: Text -> Text -> Widget Name
renderKeyBinding key label =
    withAttr (attrName "keyMapSep") (txt "[")
        <+> withAttr (attrName "keyMapKey") (txt key)
        <+> withAttr (attrName "keyMapSep") (txt ":")
        <+> withAttr (attrName "keyMap") (txt label)
        <+> withAttr (attrName "keyMapSep") (txt "]")

-- ─────────────────────────────────────────────────────────────────────────────
-- Key Map Help (キーマップヘルプ)
-- ─────────────────────────────────────────────────────────────────────────────

renderKeyMapHelp :: Text -> Text -> Widget Name
renderKeyMapHelp key description =
    hBox
        [ hLimit 15 $ withAttr (attrName "keyMapKey") $ txt ("  " <> key)
        , withAttr (attrName "keyMapSep") $ txt " : "
        , txt description
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
