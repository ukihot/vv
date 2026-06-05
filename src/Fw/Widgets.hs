{-# LANGUAGE ImportQualifiedPost #-}

module Fw.Widgets (
    renderHeader,
    renderBreadcrumbs,
    renderTabBar,
    renderNavigationMenu,
    renderKeyMapHelp,
    renderKeyBinding,
) where

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
    withAttr,
    (<+>),
 )
import Brick.Widgets.Center (hCenter)
import Data.Text (Text)
import Data.Text qualified as T
import Fw.AppState (
    DomainTab (..),
    Name,
    ScreenInfo (..),
    getScreensByTab,
 )

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

renderBreadcrumbs :: Text -> Widget Name
renderBreadcrumbs breadcrumbs =
    padLeft (Pad 2) $
        padTop (Pad 1) $
            padBottom (Pad 1) $
                withAttr (attrName "breadcrumbs") $
                    txt ("> " <> breadcrumbs)

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
        prefix = if isSelected then "> " else "  "
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

renderKeyBinding :: Text -> Text -> Widget Name
renderKeyBinding key label =
    withAttr (attrName "keyMapSep") (txt "[")
        <+> withAttr (attrName "keyMapKey") (txt key)
        <+> withAttr (attrName "keyMapSep") (txt ":")
        <+> withAttr (attrName "keyMap") (txt label)
        <+> withAttr (attrName "keyMapSep") (txt "]")

renderKeyMapHelp :: Text -> Text -> Widget Name
renderKeyMapHelp key description =
    hBox
        [ hLimit 15 $ withAttr (attrName "keyMapKey") $ txt ("  " <> key)
        , withAttr (attrName "keyMapSep") $ txt " : "
        , txt description
        ]
