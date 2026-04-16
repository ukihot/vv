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
module Adapter.View.Brick.App (runTuiApp) where

import Adapter.Controller.IAM (handleActivateUser, handleListUsers, handleRegisterUser)
import Adapter.Env (mkEnv, runAppM)
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
    renderBreadcrumbs,
    renderHeader,
    renderKeyBinding,
    renderKeyMapHelp,
    renderNavigationMenu,
    renderStatusBar,
    renderTabBar,
 )
import Adapter.View.Components.LogViewer (
    LogEntry (..),
    LogLevel (..),
    LogViewerState (..),
    initialLogViewerState,
 )
import App.DTO.Response.IAM (UserListResponse (..))
import Brick (
    App (..),
    AttrMap,
    AttrName,
    BrickEvent (VtyEvent),
    EventM,
    Padding (Pad),
    Widget,
    attrMap,
    attrName,
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
    str,
    txt,
    vBox,
    vLimit,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Brick.Widgets.Edit (
    Editor,
    applyEdit,
    editorText,
    getEditContents,
 )
import Control.Concurrent.STM (atomically, modifyTVar', newTVarIO, readTVar)
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State qualified
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Zipper qualified as Z
import Data.Time (UTCTime, getCurrentTime)
import Graphics.Vty qualified as V

-- ─────────────────────────────────────────────────────────────────────────────
-- Entry Point
-- ─────────────────────────────────────────────────────────────────────────────

runTuiApp :: IO ()
runTuiApp = do
    -- 共有状態（ログ）を初期化
    logsVar <- newTVarIO ["[INFO] Application started. Press 'h' for help."]

    -- 依存環境を構築
    env <- mkEnv logsVar

    let initialState =
            UiState
                { uiEnv = env
                , uiLogs = logsVar
                , uiLogViewer = initialLogViewerState
                , uiNavigation = initialNavigation
                , uiUserIdEditor = emptyEditor UserIdField
                , uiUserNameEditor = emptyEditor UserNameField
                , uiUserEmailEditor = emptyEditor UserEmailField
                , uiUserRoleEditor = emptyEditor UserRoleField
                , uiUserList = Nothing -- 初期状態では未読み込み
                , uiCurrentFocus = UserNameField -- 初期フォーカス
                , uiShowHelp = False
                , uiNavSelectedIndex = 0
                }

    void $ defaultMain brickApp initialState

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Handling
-- ─────────────────────────────────────────────────────────────────────────────

handleEvent :: BrickEvent Name e -> EventM Name UiState ()
handleEvent ev = do
    st <- Control.Monad.State.get
    case ev of
        VtyEvent vtyEv -> do
            -- ログビューワーを更新（キー入力時に）
            updateLogViewer st

            case vtyEv of
                -- 終了
                V.EvKey (V.KChar 'q') [] -> halt
                -- ヘルプ表示/非表示
                V.EvKey (V.KChar 'h') [] -> do
                    Control.Monad.State.put st {uiShowHelp = not (uiShowHelp st)}

                -- 画面固有のイベント処理を最優先（Tab/Shift+Tabを含む）
                _ -> do
                    let currentScreen = navCurrentScreen (uiNavigation st)
                    handled <- case currentScreen of
                        ScreenUserActivate -> handleUserActivateEventWithResult vtyEv st
                        ScreenUserRegister -> handleUserRegisterEventWithResult vtyEv st
                        _ -> pure False

                    -- 画面固有で処理されなかった場合のみグローバル処理
                    if not handled
                        then handleGlobalEvent vtyEv st
                        else pure ()
        _ -> pure ()

-- グローバルイベント処理（画面固有で処理されなかった場合）
handleGlobalEvent :: V.Event -> UiState -> EventM Name UiState ()
handleGlobalEvent vtyEv st = case vtyEv of
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
                    -- 画面遷移時にフォーカスをリセット
                    newFocus = case selectedScreen of
                        ScreenUserRegister -> UserNameField
                        ScreenUserActivate -> UserIdField
                        _ -> UserNameField

                -- ユーザー一覧画面の場合はデータを読み込み
                newState <-
                    if selectedScreen == ScreenUserList
                        then do
                            -- ログをクリア（画面遷移時）
                            liftIO $ atomically $ modifyTVar' (uiLogs st) (const ["[INFO] Loading user list..."])
                            userListResp <- liftIO $ runAppM (uiEnv st) (handleListUsers Nothing 0 100)
                            pure st {uiUserList = Just userListResp}
                        else do
                            -- 他の画面遷移時もログをクリア
                            liftIO $ atomically $ modifyTVar' (uiLogs st) (const ["[INFO] Screen changed"])
                            pure st

                Control.Monad.State.put
                    newState
                        { uiNavigation = nav'
                        , uiCurrentFocus = newFocus
                        }
            else pure ()

    -- 戻る
    V.EvKey V.KEsc [] -> do
        let nav' = popScreen (uiNavigation st)
        Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

    -- タブ切り替え（次へ）- フォーム画面以外でのみ有効
    V.EvKey (V.KChar '\t') [] -> do
        let currentTab = navCurrentTab (uiNavigation st)
            nextTab = cycleTab currentTab
            nav' = switchTab nextTab (uiNavigation st)
        Control.Monad.State.put st {uiNavigation = nav', uiNavSelectedIndex = 0}

    -- タブ切り替え（前へ）- フォーム画面以外でのみ有効
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
    -- ユーザー一覧画面でのリフレッシュ（r）
    V.EvKey (V.KChar 'r') [] | navCurrentScreen (uiNavigation st) == ScreenUserList -> do
        liftIO $ atomically $ modifyTVar' (uiLogs st) (const ["[INFO] Refreshing user list..."])
        userListResp <- liftIO $ runAppM (uiEnv st) (handleListUsers Nothing 0 100)
        Control.Monad.State.put st {uiUserList = Just userListResp}
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

-- 画面固有のイベント処理（後方互換性のため残す）
handleScreenEvent :: V.Event -> UiState -> EventM Name UiState ()
handleScreenEvent vtyEv st = do
    let currentScreen = navCurrentScreen (uiNavigation st)
    case currentScreen of
        ScreenUserActivate -> do
            _ <- handleUserActivateEventWithResult vtyEv st
            pure ()
        ScreenUserRegister -> do
            _ <- handleUserRegisterEventWithResult vtyEv st
            pure ()
        _ -> pure ()

-- 画面固有のイベント処理（処理したかどうかを返す）
handleUserActivateEventWithResult :: V.Event -> UiState -> EventM Name UiState Bool
handleUserActivateEventWithResult vtyEv st = case vtyEv of
    V.EvKey V.KEnter [] -> do
        let userId = T.strip (T.unlines (getEditContents (uiUserIdEditor st)))
        if T.null userId
            then do
                liftIO $ atomically $ modifyTVar' (uiLogs st) (<> ["[ERROR] User ID is required."])
                Control.Monad.State.put
                    st
                        { uiUserIdEditor = emptyEditor UserIdField
                        , uiCurrentFocus = UserIdField
                        }
            else do
                liftIO $ runAppM (uiEnv st) (handleActivateUser userId)
                Control.Monad.State.put
                    st
                        { uiUserIdEditor = emptyEditor UserIdField
                        , uiCurrentFocus = UserIdField
                        }
        pure True -- 処理した
    ev -> do
        -- エディタへの入力を処理（文字入力、削除、カーソル移動など）
        case ev of
            V.EvKey (V.KChar c) [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit (Z.insertChar c) (uiUserIdEditor st)}
                pure True
            V.EvKey V.KBS [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.deletePrevChar (uiUserIdEditor st)}
                pure True
            V.EvKey V.KDel [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.deleteChar (uiUserIdEditor st)}
                pure True
            V.EvKey V.KLeft [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.moveLeft (uiUserIdEditor st)}
                pure True
            V.EvKey V.KRight [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.moveRight (uiUserIdEditor st)}
                pure True
            V.EvKey V.KHome [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.gotoBOL (uiUserIdEditor st)}
                pure True
            V.EvKey V.KEnd [] -> do
                Control.Monad.State.put st {uiUserIdEditor = applyEdit Z.gotoEOL (uiUserIdEditor st)}
                pure True
            _ -> pure False -- 処理しなかった

-- UserRegister画面のイベント処理（処理したかどうかを返す）
handleUserRegisterEventWithResult :: V.Event -> UiState -> EventM Name UiState Bool
handleUserRegisterEventWithResult vtyEv st = case vtyEv of
    V.EvKey V.KEnter [] -> do
        let name = T.strip (T.unlines (getEditContents (uiUserNameEditor st)))
            email = T.strip (T.unlines (getEditContents (uiUserEmailEditor st)))
            role = T.strip (T.unlines (getEditContents (uiUserRoleEditor st)))
        if T.null name || T.null email || T.null role
            then do
                liftIO $ atomically $ modifyTVar' (uiLogs st) (<> ["[ERROR] All fields are required."])
            else do
                liftIO $ runAppM (uiEnv st) (handleRegisterUser name email role)
                -- フォームをクリア
                Control.Monad.State.put
                    st
                        { uiUserNameEditor = emptyEditor UserNameField
                        , uiUserEmailEditor = emptyEditor UserEmailField
                        , uiUserRoleEditor = emptyEditor UserRoleField
                        , uiCurrentFocus = UserNameField -- フォーカスをリセット
                        }
        pure True -- 処理した

    -- Tab: 次のフィールドへ（フォーム画面でのみ有効）
    V.EvKey (V.KChar '\t') [] -> do
        let nextFocus = getNextFocus (uiCurrentFocus st)
        Control.Monad.State.put st {uiCurrentFocus = nextFocus}
        pure True -- 処理した

    -- Shift+Tab: 前のフィールドへ（フォーム画面でのみ有効）
    V.EvKey V.KBackTab [] -> do
        let prevFocus = getPrevFocus (uiCurrentFocus st)
        Control.Monad.State.put st {uiCurrentFocus = prevFocus}
        pure True -- 処理した

    -- フォーカスされたフィールドのみに入力を送る
    ev -> do
        let currentFocus = uiCurrentFocus st
        case ev of
            V.EvKey (V.KChar c) [] -> do
                Control.Monad.State.put $ applyToFocusedEditor (Z.insertChar c) currentFocus st
                pure True
            V.EvKey V.KBS [] -> do
                Control.Monad.State.put $ applyToFocusedEditor Z.deletePrevChar currentFocus st
                pure True
            V.EvKey V.KDel [] -> do
                Control.Monad.State.put $ applyToFocusedEditor Z.deleteChar currentFocus st
                pure True
            V.EvKey V.KLeft [] -> do
                Control.Monad.State.put $ applyToFocusedEditor Z.moveLeft currentFocus st
                pure True
            V.EvKey V.KRight [] -> do
                Control.Monad.State.put $ applyToFocusedEditor Z.moveRight currentFocus st
                pure True
            V.EvKey V.KHome [] -> do
                Control.Monad.State.put $ applyToFocusedEditor Z.gotoBOL currentFocus st
                pure True
            V.EvKey V.KEnd [] -> do
                Control.Monad.State.put $ applyToFocusedEditor Z.gotoEOL currentFocus st
                pure True
            _ -> pure False -- 処理しなかった

-- フォーカス管理ヘルパー関数
getNextFocus :: Name -> Name
getNextFocus UserNameField = UserEmailField
getNextFocus UserEmailField = UserRoleField
getNextFocus UserRoleField = UserNameField
getNextFocus _ = UserNameField

getPrevFocus :: Name -> Name
getPrevFocus UserNameField = UserRoleField
getPrevFocus UserEmailField = UserNameField
getPrevFocus UserRoleField = UserEmailField
getPrevFocus _ = UserNameField

-- フォーカスされたエディタにのみ操作を適用
applyToFocusedEditor :: (Z.TextZipper Text -> Z.TextZipper Text) -> Name -> UiState -> UiState
applyToFocusedEditor editOp focus st = case focus of
    UserNameField -> st {uiUserNameEditor = applyEdit editOp (uiUserNameEditor st)}
    UserEmailField -> st {uiUserEmailEditor = applyEdit editOp (uiUserEmailEditor st)}
    UserRoleField -> st {uiUserRoleEditor = applyEdit editOp (uiUserRoleEditor st)}
    UserIdField -> st {uiUserIdEditor = applyEdit editOp (uiUserIdEditor st)}
    _ -> st

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
            , -- メインコンテンツ（ログビューワーなし）
              if uiShowHelp st
                then renderHelpScreen
                else
                    if navShowNavigation nav
                        then renderWithNavigation st
                        else padAll 1 $ renderMainContent st
            , -- ステータスバー（ログ統合）
              Border.hBorder
            , renderStatusBarWithLogs st canGoBack
            ]
        ]

-- ナビゲーションメニュー付きレイアウト（ログビューワーなし）
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
                , renderKeyMapHelp "Enter" "Execute/Register/Select"
                , renderKeyMapHelp "Tab" "Next field (in forms)"
                , renderKeyMapHelp "Shift+Tab" "Previous field (in forms)"
                , txt ""
                , withAttr (attrName "title") $ txt "User Registration Form"
                , txt ""
                , renderKeyMapHelp "Tab" "Move to next field"
                , renderKeyMapHelp "Shift+Tab" "Move to previous field"
                , renderKeyMapHelp "Enter" "Register user"
                , renderKeyMapHelp "Backspace" "Delete character"
                , renderKeyMapHelp "Delete" "Delete character forward"
                , renderKeyMapHelp "Home/End" "Move to start/end of field"
                , txt ""
                , withAttr (attrName "hint") $ txt "Press 'h' to close this help"
                ]

-- メインコンテンツ
renderMainContent :: UiState -> Widget Name
renderMainContent st =
    let currentScreen = navCurrentScreen (uiNavigation st)
     in renderScreen currentScreen st

-- ログ統合ステータスバー
renderStatusBarWithLogs :: UiState -> Bool -> Widget Name
renderStatusBarWithLogs st canGoBack =
    withAttr (attrName "statusBar") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                hBox
                    [ -- 左側：ログビューワー（コンパクト版）
                      renderCompactLogViewer (uiLogViewer st)
                    , -- 中央：スペーサー
                      txt "  "
                    , -- 右側：キーマップ
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

-- コンパクトログビューワー（ステータスバー用）
renderCompactLogViewer :: LogViewerState -> Widget Name
renderCompactLogViewer state =
    hBox $ -- 横並びに変更
        case reverse $ lvCompletedLogs state of
            [] -> [withAttr (attrName "hint") $ txt "Ready"]
            (latest : _) -> [renderInlineLogEntry latest]

-- インライン表示用のログエントリ
renderInlineLogEntry :: LogEntry -> Widget Name
renderInlineLogEntry entry =
    hBox
        [ withAttr (logLevelAttr (logLevel entry)) $
            str (logLevelPrefix (logLevel entry))
        , txt " "
        , txt (logMessage entry)
        ]

-- ログレベル属性とプレフィックス（LogViewerから移植）
logLevelPrefix :: LogLevel -> String
logLevelPrefix LogInfo = "[INFO]"
logLevelPrefix LogSuccess = "[OK]  "
logLevelPrefix LogWarning = "[WARN]"
logLevelPrefix LogError = "[ERR] "
logLevelPrefix LogDebug = "[DBG] "

logLevelAttr :: LogLevel -> AttrName
logLevelAttr LogInfo = attrName "logInfo"
logLevelAttr LogSuccess = attrName "logSuccess"
logLevelAttr LogWarning = attrName "logWarning"
logLevelAttr LogError = attrName "logError"
logLevelAttr LogDebug = attrName "logDebug"

emptyEditor :: Name -> Editor Text Name
emptyEditor name = editorText name (Just 1) ""

-- ─────────────────────────────────────────────────────────────────────────────
-- ログ変換ヘルパー
-- ─────────────────────────────────────────────────────────────────────────────

updateLogViewer :: UiState -> EventM Name UiState ()
updateLogViewer st = do
    -- 新しいログをチェックしてログビューワーに追加
    logs <- liftIO $ atomically $ readTVar (uiLogs st)
    currentTime <- liftIO getCurrentTime

    -- 新しいログをLogEntryに変換して直接完了リストに追加（タイプライター効果なし）
    let newEntries = map (textToLogEntry currentTime) logs
        updatedLogViewer = foldr addLogEntryDirect (uiLogViewer st) newEntries

    -- ログをクリア（処理済みなので）
    liftIO $ atomically $ modifyTVar' (uiLogs st) (const [])

    Control.Monad.State.put st {uiLogViewer = updatedLogViewer}
    where
        -- ログを直接完了リストに追加（タイプライター効果をスキップ）
        addLogEntryDirect :: LogEntry -> LogViewerState -> LogViewerState
        addLogEntryDirect entry state =
            let completedLogs' = take (lvMaxDisplayLogs state) (entry : lvCompletedLogs state)
             in state {lvCompletedLogs = completedLogs'}

textToLogEntry :: UTCTime -> Text -> LogEntry
textToLogEntry timestamp logText
    | "[ERROR]" `T.isInfixOf` logText = LogEntry LogError logText timestamp
    | "[WARN]" `T.isInfixOf` logText = LogEntry LogWarning logText timestamp
    | "[SUCCESS]" `T.isInfixOf` logText = LogEntry LogSuccess logText timestamp
    | "[DEBUG]" `T.isInfixOf` logText = LogEntry LogDebug logText timestamp
    | otherwise = LogEntry LogInfo logText timestamp

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
        , -- ログビューワー
          (attrName "logInfo", fg V.brightBlue)
        , (attrName "logSuccess", fg V.brightGreen)
        , (attrName "logWarning", fg V.brightYellow)
        , (attrName "logError", fg V.brightRed)
        , (attrName "logDebug", fg V.brightBlack)
        , (attrName "timestamp", fg V.brightBlack)
        , (attrName "cursor", fg V.brightWhite `V.withStyle` V.blink)
        , (attrName "pending", fg V.brightBlack `V.withStyle` V.italic)
        ]
