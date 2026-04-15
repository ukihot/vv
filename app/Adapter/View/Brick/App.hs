{-# LANGUAGE ImportQualifiedPost #-}
{-# OPTIONS_GHC -Wno-incomplete-patterns #-}

{- | Brick View
Presenterの状態変更を非同期/リアクティブに検知してUIに反映する。
Controllerに生データを渡す。

画面構成:
  - ヘッダー（タイトル + キーマップヘルプ）
  - タブバー（ドメイン集約単位）
  - パンくずリスト
  - メインコンテンツ（ナビゲーション + コンテンツ）
  - ステータスバー（ログ + キーマップ）

キーマップ:
  q       : 終了
  Tab     : 次のタブへ
  S-Tab   : 前のタブへ
  n       : ナビゲーション表示/非表示
  Esc     : 戻る
  h       : ヘルプ表示
  1-6     : タブ直接選択
  Enter   : 選択/実行
-}
module Adapter.View.Brick.App (runBrickApp) where

import Adapter.Controller.IAM (handleActivateUser)
import Adapter.Env (Env, mkEnv, runAppM)
import Adapter.View.Brick.Navigation (
    getBreadcrumbs,
    initialNavigation,
    popScreen,
    pushScreen,
    switchTab,
    toggleNavigation,
 )
import Adapter.View.Brick.Screens (renderScreen)
import Adapter.View.Brick.Types (
    DomainTab (..),
    Name (..),
    NavigationState (..),
    Screen (..),
    ScreenInfo (..),
    UiState (..),
    getScreensByTab,
    screenId,
 )
import Adapter.View.Brick.Widgets (
    renderBackButton,
    renderBreadcrumbs,
    renderHeader,
    renderKeyMapHelp,
    renderLogPanel,
    renderNavigationMenu,
    renderStatusBar,
    renderTabBar,
 )
import Brick (
    App (..),
    AttrMap,
    AttrName,
    BrickEvent (VtyEvent),
    EventM,
    Padding (Max, Pad),
    Widget,
    attrMap,
    attrName,
    bg,
    defaultMain,
    fg,
    hBox,
    hLimit,
    halt,
    on,
    padAll,
    padLeft,
    padRight,
    showFirstCursor,
    txt,
    vBox,
    vLimit,
    withAttr,
    (<+>),
 )
import Brick.Widgets.Border qualified as Border
import Brick.Widgets.Border.Style qualified as BorderStyle
import Brick.Widgets.Edit (
    Editor,
    applyEdit,
    editorText,
    getEditContents,
    handleEditorEvent,
 )
import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State qualified
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Zipper qualified as Z
import Graphics.Vty qualified as V

-- ─────────────────────────────────────────────────────────────────────────────
-- Entry Point
-- ─────────────────────────────────────────────────────────────────────────────

runBrickApp :: IO ()
runBrickApp = do
    -- 共有状態（ログ）を初期化
    logsVar <- newTVarIO ["[INFO] Application started. Press 'h' for help."]

    -- 依存環境を構築
    env <- mkEnv logsVar

    let initialState =
            UiState
                { uiEnv = env
                , uiLogs = logsVar
                , uiNavigation = initialNavigation
                , uiUserIdEditor = emptyEditor
                , uiShowHelp = False
                , uiNavSelectedIndex = 0
                }

    _ <- defaultMain brickApp initialState
    pure ()

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Handling
-- ─────────────────────────────────────────────────────────────────────────────

handleEvent :: BrickEvent Name e -> EventM Name UiState ()
handleEvent ev = do
    st <- Control.Monad.State.get
    case ev of
        VtyEvent vtyEv ->
            case vtyEv of
                -- 終了
                V.EvKey (V.KChar 'q') [] -> halt
                -- ヘルプ表示/非表示
                V.EvKey (V.KChar 'h') [] -> do
                    Control.Monad.State.put st {uiShowHelp = not (uiShowHelp st)}

                -- ナビゲーション表示/非表示
                V.EvKey (V.KChar 'n') [] -> do
                    let nav' = toggleNavigation (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

                -- ナビゲーションメニュー内での移動（j: 下へ）
                V.EvKey (V.KChar 'j') [] | navShowNavigation (uiNavigation st) -> do
                    let currentTab = navCurrentTab (uiNavigation st)
                        screens = getScreensByTab currentTab
                        maxIndex = length screens - 1
                        newIndex = min maxIndex (uiNavSelectedIndex st + 1)
                    Control.Monad.State.put st {uiNavSelectedIndex = newIndex}

                -- ナビゲーションメニュー内での移動（k: 上へ）
                V.EvKey (V.KChar 'k') [] | navShowNavigation (uiNavigation st) -> do
                    let newIndex = max 0 (uiNavSelectedIndex st - 1)
                    Control.Monad.State.put st {uiNavSelectedIndex = newIndex}

                -- ナビゲーションメニューから画面起動（Space）
                V.EvKey (V.KChar ' ') [] | navShowNavigation (uiNavigation st) -> do
                    let currentTab = navCurrentTab (uiNavigation st)
                        screens = getScreensByTab currentTab
                        selectedIndex = uiNavSelectedIndex st
                    if selectedIndex < length screens
                        then do
                            let selectedScreen = screenId (screens !! selectedIndex)
                                nav' = pushScreen selectedScreen (uiNavigation st)
                            Control.Monad.State.put st {uiNavigation = nav'}
                        else pure ()

                -- 戻る
                V.EvKey V.KEsc [] -> do
                    let nav' = popScreen (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

                -- タブ切り替え（次へ）
                V.EvKey (V.KChar '\t') [] -> do
                    let currentTab = navCurrentTab (uiNavigation st)
                        nextTab = cycleTab currentTab
                        nav' = switchTab nextTab (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

                -- タブ切り替え（前へ）
                V.EvKey V.KBackTab [] -> do
                    let currentTab = navCurrentTab (uiNavigation st)
                        prevTab = cycleTabReverse currentTab
                        nav' = switchTab prevTab (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

                -- タブ直接選択（1-6）
                V.EvKey (V.KChar '1') [] -> switchToTab TabIAM st
                V.EvKey (V.KChar '2') [] -> switchToTab TabAccounting st
                V.EvKey (V.KChar '3') [] -> switchToTab TabIFRS st
                V.EvKey (V.KChar '4') [] -> switchToTab TabOps st
                V.EvKey (V.KChar '5') [] -> switchToTab TabAudit st
                V.EvKey (V.KChar '6') [] -> switchToTab TabOrg st
                -- 画面固有のイベント処理
                _ -> handleScreenEvent vtyEv st
        _ -> pure ()

-- タブへ直接切り替え
switchToTab :: DomainTab -> UiState -> EventM Name UiState ()
switchToTab tab st = do
    let nav' = switchTab tab (uiNavigation st)
    Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

-- タブを循環（次へ）
cycleTab :: DomainTab -> DomainTab
cycleTab TabIAM = TabAccounting
cycleTab TabAccounting = TabIFRS
cycleTab TabIFRS = TabOps
cycleTab TabOps = TabAudit
cycleTab TabAudit = TabOrg
cycleTab TabOrg = TabIAM

-- タブを循環（前へ）
cycleTabReverse :: DomainTab -> DomainTab
cycleTabReverse TabIAM = TabOrg
cycleTabReverse TabAccounting = TabIAM
cycleTabReverse TabIFRS = TabAccounting
cycleTabReverse TabOps = TabIFRS
cycleTabReverse TabAudit = TabOps
cycleTabReverse TabOrg = TabAudit

-- 画面固有のイベント処理
handleScreenEvent :: V.Event -> UiState -> EventM Name UiState ()
handleScreenEvent vtyEv st = do
    let currentScreen = navCurrentScreen (uiNavigation st)
    case currentScreen of
        ScreenUserActivate -> handleUserActivateEvent vtyEv st
        _ -> pure ()

-- UserActivate画面のイベント処理
handleUserActivateEvent :: V.Event -> UiState -> EventM Name UiState ()
handleUserActivateEvent vtyEv st = case vtyEv of
    V.EvKey V.KEnter [] -> do
        let userId = T.strip (T.unlines (getEditContents (uiUserIdEditor st)))
        if T.null userId
            then do
                liftIO $ atomically $ modifyTVar' (uiLogs st) (<> ["[ERROR] User ID is required."])
                Control.Monad.State.put st {uiUserIdEditor = emptyEditor}
            else do
                liftIO $ runAppM (uiEnv st) (handleActivateUser userId)
                Control.Monad.State.put st {uiUserIdEditor = emptyEditor}
    ev -> do
        -- エディタへの入力を処理（文字入力、削除、カーソル移動など）
        case ev of
            V.EvKey (V.KChar c) [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit (Z.insertChar c) (uiUserIdEditor st)}
            V.EvKey V.KBS [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.deletePrevChar (uiUserIdEditor st)}
            V.EvKey V.KDel [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.deleteChar (uiUserIdEditor st)}
            V.EvKey V.KLeft [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.moveLeft (uiUserIdEditor st)}
            V.EvKey V.KRight [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.moveRight (uiUserIdEditor st)}
            V.EvKey V.KHome [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.gotoBOL (uiUserIdEditor st)}
            V.EvKey V.KEnd [] ->
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.gotoEOL (uiUserIdEditor st)}
            _ -> pure ()

-- ─────────────────────────────────────────────────────────────────────────────
-- Brick App Definition
-- ─────────────────────────────────────────────────────────────────────────────

brickApp :: App UiState e Name
brickApp =
    App
        { appDraw = drawUi
        , appChooseCursor = showFirstCursor
        , appHandleEvent = handleEvent
        , appStartEvent = pure ()
        , appAttrMap = const theMap
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Rendering
-- ─────────────────────────────────────────────────────────────────────────────

drawUi :: UiState -> [Widget Name]
drawUi st =
    let nav = uiNavigation st
        breadcrumbs = getBreadcrumbs nav
        canGoBack = not (null (navScreenStack nav))
     in [ vBox
            [ -- ヘッダー
              renderHeader
            , -- タブバー
              renderTabBar (navCurrentTab nav)
            , -- パンくずリスト
              renderBreadcrumbs breadcrumbs
            , Border.hBorder
            , -- メインコンテンツ
              if uiShowHelp st
                then renderHelpScreen
                else
                    if navShowNavigation nav
                        then renderWithNavigation st
                        else padAll 1 $ renderMainContent st
            , -- ステータスバー
              Border.hBorder
            , renderStatusBar st canGoBack
            ]
        ]

-- ナビゲーションメニュー付きレイアウト
renderWithNavigation :: UiState -> Widget Name
renderWithNavigation st =
    hBox
        [ hLimit 45 $
            vBox
                [ Border.borderWithLabel (txt " Navigation (j/k:move Space:select) ") $
                    renderNavigationMenu (navCurrentTab (uiNavigation st)) (uiNavSelectedIndex st)
                ]
        , Border.vBorder
        , padAll 1 $ renderMainContent st
        ]

-- ヘルプ画面
renderHelpScreen :: Widget Name
renderHelpScreen =
    Border.borderWithLabel (txt " Help ") $
        padAll 2 $
            vBox
                [ withAttr (attrName "title") $ txt "Keyboard Shortcuts"
                , txt ""
                , renderKeyMapHelp "q" "Quit application"
                , renderKeyMapHelp "h" "Toggle help screen"
                , renderKeyMapHelp "n" "Toggle navigation menu"
                , renderKeyMapHelp "Esc" "Go back"
                , txt ""
                , withAttr (attrName "title") $ txt "Navigation Menu"
                , txt ""
                , renderKeyMapHelp "j" "Move down"
                , renderKeyMapHelp "k" "Move up"
                , renderKeyMapHelp "Space" "Select/Launch screen"
                , txt ""
                , withAttr (attrName "title") $ txt "Tab Navigation"
                , txt ""
                , renderKeyMapHelp "Tab" "Next tab"
                , renderKeyMapHelp "Shift+Tab" "Previous tab"
                , renderKeyMapHelp "1" "IAM tab"
                , renderKeyMapHelp "2" "Accounting tab"
                , renderKeyMapHelp "3" "IFRS tab"
                , renderKeyMapHelp "4" "Operations tab"
                , renderKeyMapHelp "5" "Audit tab"
                , renderKeyMapHelp "6" "Organization tab"
                , txt ""
                , withAttr (attrName "title") $ txt "Screen Actions"
                , txt ""
                , renderKeyMapHelp "Enter" "Execute/Select"
                , txt ""
                , withAttr (attrName "hint") $ txt "Press 'h' to close this help"
                ]

-- メインコンテンツ
renderMainContent :: UiState -> Widget Name
renderMainContent st =
    let currentScreen = navCurrentScreen (uiNavigation st)
     in renderScreen currentScreen st

emptyEditor :: Editor Text Name
emptyEditor = editorText UserIdField (Just 1) ""

-- ─────────────────────────────────────────────────────────────────────────────
-- Attributes
-- ─────────────────────────────────────────────────────────────────────────────

theMap :: AttrMap
theMap =
    attrMap
        V.defAttr
        [ -- テキスト
          (attrName "hint", fg V.brightBlack)
        , (attrName "title", fg V.brightCyan `V.withStyle` V.bold)
        , (attrName "subtitle", fg V.cyan)
        , (attrName "success", fg V.brightGreen)
        , (attrName "error", fg V.brightRed)
        , (attrName "warning", fg V.brightYellow)
        , -- ヘッダー
          (attrName "header", V.white `on` V.blue `V.withStyle` V.bold)
        , (attrName "appTitle", fg V.brightWhite `V.withStyle` V.bold)
        , -- パンくずリスト
          (attrName "breadcrumbs", fg V.brightYellow)
        , -- タブ
          (attrName "tabActive", V.black `on` V.brightCyan `V.withStyle` V.bold)
        , (attrName "tabInactive", fg V.brightBlack)
        , (attrName "tabNumber", fg V.brightBlue)
        , -- ナビゲーション
          (attrName "navItem", fg V.brightWhite `V.withStyle` V.bold)
        , (attrName "navItemSelected", V.black `on` V.brightYellow `V.withStyle` V.bold)
        , (attrName "navDescription", fg V.brightBlack)
        , (attrName "navBorder", fg V.cyan)
        , -- ステータスバー
          (attrName "statusBar", V.white `on` V.black)
        , (attrName "keyMap", fg V.brightCyan)
        , (attrName "keyMapKey", fg V.brightYellow `V.withStyle` V.bold)
        , (attrName "keyMapSep", fg V.brightBlack)
        , -- ボタン
          (attrName "backButton", fg V.brightGreen `V.withStyle` V.bold)
        , (attrName "backButtonDisabled", fg V.brightBlack)
        , -- コンポーネント
          (attrName "cardBorder", fg V.cyan)
        , (attrName "sectionTitle", fg V.brightCyan `V.withStyle` V.bold)
        ]
