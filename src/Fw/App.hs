{-# LANGUAGE ImportQualifiedPost #-}

module Fw.App (
    runTuiApp,
) where

import Brick (
    App (..),
    AttrMap,
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
    invalidateCache,
    on,
    padAll,
    padLeft,
    padRight,
    showFirstCursor,
    txt,
    vBox,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Common.UI.LogViewer (
    LogEntry (..),
    LogLevel (..),
    LogViewerState (..),
 )
import Control.Concurrent.STM (atomically, modifyTVar', newTVarIO, readTVar)
import Control.Monad (void, when)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State qualified as State
import Data.Foldable (traverse_)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (UTCTime, getCurrentTime)
import Features.IAM.UserActivate.Core qualified as UserActivate
import Features.IAM.UserActivate.Shell qualified as UserActivateShell
import Features.IAM.UserList.Core qualified as UserList
import Features.IAM.UserList.Shell qualified as UserListShell
import Features.IAM.UserRegister.Core qualified as UserRegister
import Features.IAM.UserRegister.Shell qualified as UserRegisterShell
import Fw.AppState (
    AppState (..),
    DomainTab (..),
    Name,
    NavigationState (..),
    Screen (..),
    ScreenInfo (..),
    getScreensByTab,
    initialAppState,
    screenId,
 )
import Fw.Navigation (
    getBreadcrumbs,
    popScreen,
    pushScreen,
    switchTab,
    toggleNavigation,
 )
import Fw.Screens (renderScreen)
import Fw.Types (mkEnv)
import Fw.Widgets (
    renderBreadcrumbs,
    renderHeader,
    renderKeyBinding,
    renderKeyMapHelp,
    renderNavigationMenu,
    renderTabBar,
 )
import Graphics.Vty qualified as V

runTuiApp :: IO ()
runTuiApp = do
    logsVar <- newTVarIO []
    env <- mkEnv logsVar
    void $ defaultMain brickApp (initialAppState env logsVar)

brickApp :: App AppState e Name
brickApp =
    App
        { appDraw = drawUi
        , appChooseCursor = showFirstCursor
        , appHandleEvent = handleEvent
        , appStartEvent = do
            st <- State.get
            updateLogViewer st
        , appAttrMap = const theMap
        }

handleEvent :: BrickEvent Name e -> EventM Name AppState ()
handleEvent = \case
    VtyEvent vtyEv -> do
        st <- State.get
        case vtyEv of
            V.EvKey (V.KChar 'q') [] -> halt
            V.EvKey (V.KChar 'h') [] ->
                State.put st {appShowHelp = not (appShowHelp st)}
            _ -> do
                handled <- handleFeatureEvent vtyEv st
                when (not handled) $
                    handleGlobalEvent vtyEv st

        st' <- State.get
        updateLogViewer st'
    _ -> pure ()

handleFeatureEvent :: V.Event -> AppState -> EventM Name AppState Bool
handleFeatureEvent vtyEv state =
    case navCurrentScreen (appNavigation state) of
        ScreenUserActivate -> handleUserActivateEvent vtyEv state
        ScreenUserRegister -> handleUserRegisterEvent vtyEv state
        _ -> pure False

handleUserActivateEvent :: V.Event -> AppState -> EventM Name AppState Bool
handleUserActivateEvent vtyEv state =
    case activateCommandFromEvent vtyEv of
        Nothing -> pure False
        Just command -> do
            let step = UserActivate.handleCommand command (appUserActivate state)
                state' = state {appUserActivate = UserActivate.stepState step}
            State.put state'
            liftIO $ traverse_ (UserActivateShell.runEffect (appEnv state')) (UserActivate.stepEffects step)
            invalidateCache
            pure True

handleUserRegisterEvent :: V.Event -> AppState -> EventM Name AppState Bool
handleUserRegisterEvent vtyEv state =
    case registerCommandFromEvent vtyEv of
        Nothing -> pure False
        Just command -> do
            let step = UserRegister.handleCommand command (appUserRegister state)
                state' = state {appUserRegister = UserRegister.stepState step}
            State.put state'
            liftIO $ traverse_ (UserRegisterShell.runEffect (appEnv state')) (UserRegister.stepEffects step)
            invalidateCache
            pure True

handleGlobalEvent :: V.Event -> AppState -> EventM Name AppState ()
handleGlobalEvent vtyEv state = case vtyEv of
    V.EvKey (V.KChar 'n') [] -> do
        let nav' = toggleNavigation (appNavigation state)
        State.put state {appNavigation = nav', appNavSelectedIndex = 0}
    V.EvKey (V.KChar 'j') [] | navShowNavigation (appNavigation state) -> do
        let currentTab = navCurrentTab (appNavigation state)
            screens = getScreensByTab currentTab
            maxIndex = length screens - 1
            newIndex = min maxIndex (appNavSelectedIndex state + 1)
        State.put state {appNavSelectedIndex = newIndex}
    V.EvKey (V.KChar 'k') [] | navShowNavigation (appNavigation state) -> do
        let newIndex = max 0 (appNavSelectedIndex state - 1)
        State.put state {appNavSelectedIndex = newIndex}
    V.EvKey (V.KChar ' ') [] | navShowNavigation (appNavigation state) -> do
        let currentTab = navCurrentTab (appNavigation state)
            screens = getScreensByTab currentTab
            selectedIndex = appNavSelectedIndex state
        when (selectedIndex < length screens) $ do
            let selectedScreen = screenId (screens !! selectedIndex)
                nav' = pushScreen selectedScreen (appNavigation state)
                state' = state {appNavigation = nav', appNavSelectedIndex = 0}
            State.put state'
            when (selectedScreen == ScreenUserList) $
                refreshUserList state'
    V.EvKey V.KEsc [] -> do
        let nav' = popScreen (appNavigation state)
        State.put state {appNavigation = nav', appNavSelectedIndex = 0}
    V.EvKey (V.KChar '\t') [] -> do
        let nav = appNavigation state
            nav' = switchTab (cycleTab (navCurrentTab nav)) nav
        State.put state {appNavigation = nav', appNavSelectedIndex = 0}
    V.EvKey V.KBackTab [] -> do
        let nav = appNavigation state
            nav' = switchTab (cycleTabReverse (navCurrentTab nav)) nav
        State.put state {appNavigation = nav', appNavSelectedIndex = 0}
    V.EvKey (V.KChar '1') [] -> switchToTab TabIAM state
    V.EvKey (V.KChar '2') [] -> switchToTab TabAccounting state
    V.EvKey (V.KChar '3') [] -> switchToTab TabIFRS state
    V.EvKey (V.KChar '4') [] -> switchToTab TabOps state
    V.EvKey (V.KChar '5') [] -> switchToTab TabAudit state
    V.EvKey (V.KChar '6') [] -> switchToTab TabOrg state
    V.EvKey (V.KChar 'r') []
        | navCurrentScreen (appNavigation state) == ScreenUserList ->
            refreshUserList state
    _ -> pure ()

refreshUserList :: AppState -> EventM Name AppState ()
refreshUserList state = do
    let step = UserList.handleCommand UserList.RequestRefresh (appUserList state)
        effects = UserList.stepEffects step
    case effects of
        [] -> State.put state {appUserList = UserList.stepState step}
        effect : _ -> do
            response <- liftIO $ UserListShell.runEffect (appEnv state) effect
            let loadedStep = UserList.handleCommand (UserList.UsersLoaded response) (UserList.stepState step)
            State.put state {appUserList = UserList.stepState loadedStep}
            invalidateCache

switchToTab :: DomainTab -> AppState -> EventM Name AppState ()
switchToTab tab state =
    State.put state {appNavigation = switchTab tab (appNavigation state), appNavSelectedIndex = 0}

cycleTab :: DomainTab -> DomainTab
cycleTab TabIAM = TabAccounting
cycleTab TabAccounting = TabIFRS
cycleTab TabIFRS = TabOps
cycleTab TabOps = TabAudit
cycleTab TabAudit = TabOrg
cycleTab TabOrg = TabIAM

cycleTabReverse :: DomainTab -> DomainTab
cycleTabReverse TabIAM = TabOrg
cycleTabReverse TabAccounting = TabIAM
cycleTabReverse TabIFRS = TabAccounting
cycleTabReverse TabOps = TabIFRS
cycleTabReverse TabAudit = TabOps
cycleTabReverse TabOrg = TabAudit

activateCommandFromEvent :: V.Event -> Maybe UserActivate.UserActivateCommand
activateCommandFromEvent = \case
    V.EvKey V.KEnter [] -> Just UserActivate.Submit
    event -> fmap (UserActivate.EditUserId . toActivateEditAction) (editActionFromEvent event)

registerCommandFromEvent :: V.Event -> Maybe UserRegister.UserRegisterCommand
registerCommandFromEvent = \case
    V.EvKey V.KEnter [] -> Just UserRegister.Submit
    V.EvKey (V.KChar '\t') [] -> Just UserRegister.FocusNext
    V.EvKey V.KBackTab [] -> Just UserRegister.FocusPrev
    event -> fmap (UserRegister.EditFocused . toRegisterEditAction) (editActionFromEvent event)

data SharedEditAction
    = SharedInsert Char
    | SharedDeletePrev
    | SharedDelete
    | SharedMoveLeft
    | SharedMoveRight
    | SharedMoveHome
    | SharedMoveEnd

editActionFromEvent :: V.Event -> Maybe SharedEditAction
editActionFromEvent = \case
    V.EvKey (V.KChar c) [] -> Just (SharedInsert c)
    V.EvKey V.KBS [] -> Just SharedDeletePrev
    V.EvKey V.KDel [] -> Just SharedDelete
    V.EvKey V.KLeft [] -> Just SharedMoveLeft
    V.EvKey V.KRight [] -> Just SharedMoveRight
    V.EvKey V.KHome [] -> Just SharedMoveHome
    V.EvKey V.KEnd [] -> Just SharedMoveEnd
    _ -> Nothing

toActivateEditAction :: SharedEditAction -> UserActivate.EditAction
toActivateEditAction = \case
    SharedInsert c -> UserActivate.InsertChar c
    SharedDeletePrev -> UserActivate.DeletePrevChar
    SharedDelete -> UserActivate.DeleteChar
    SharedMoveLeft -> UserActivate.MoveLeft
    SharedMoveRight -> UserActivate.MoveRight
    SharedMoveHome -> UserActivate.MoveHome
    SharedMoveEnd -> UserActivate.MoveEnd

toRegisterEditAction :: SharedEditAction -> UserRegister.EditAction
toRegisterEditAction = \case
    SharedInsert c -> UserRegister.InsertChar c
    SharedDeletePrev -> UserRegister.DeletePrevChar
    SharedDelete -> UserRegister.DeleteChar
    SharedMoveLeft -> UserRegister.MoveLeft
    SharedMoveRight -> UserRegister.MoveRight
    SharedMoveHome -> UserRegister.MoveHome
    SharedMoveEnd -> UserRegister.MoveEnd

drawUi :: AppState -> [Widget Name]
drawUi state =
    let nav = appNavigation state
        breadcrumbs = getBreadcrumbs nav
        canGoBack = not (null (navScreenStack nav))
     in [ vBox
            [ renderHeader
            , renderTabBar (navCurrentTab nav)
            , renderBreadcrumbs breadcrumbs
            , Border.hBorder
            , if appShowHelp state
                then renderHelpScreen
                else
                    if navShowNavigation nav
                        then renderWithNavigation state
                        else padAll 1 $ renderMainContent state
            , Border.hBorder
            , renderStatusBarWithLogs state canGoBack
            ]
        ]

renderWithNavigation :: AppState -> Widget Name
renderWithNavigation state =
    hBox
        [ hLimit 45 $
            vBox
                [ Border.borderWithLabel (txt " Navigation (j/k:move Space:select) ") $
                    renderNavigationMenu (navCurrentTab (appNavigation state)) (appNavSelectedIndex state)
                ]
        , Border.vBorder
        , padAll 1 $ renderMainContent state
        ]

renderMainContent :: AppState -> Widget Name
renderMainContent state =
    renderScreen (navCurrentScreen (appNavigation state)) state

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
                , renderKeyMapHelp "1-6" "Switch tab"
                , txt ""
                , withAttr (attrName "title") $ txt "Screen Actions"
                , txt ""
                , renderKeyMapHelp "Enter" "Execute/Register/Select"
                , renderKeyMapHelp "r" "Refresh current list"
                ]

renderStatusBarWithLogs :: AppState -> Bool -> Widget Name
renderStatusBarWithLogs state canGoBack =
    withAttr (attrName "statusBar") $
        padLeft (Pad 1) $
            padRight (Pad 1) $
                hBox
                    [ renderCompactLogViewer (appLogViewer state)
                    , txt "  "
                    , hBox
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

renderCompactLogViewer :: LogViewerState -> Widget Name
renderCompactLogViewer state =
    let logCount = length (lvCompletedLogs state)
     in withAttr (attrName "logInfo") $ txt $ "Logs: " <> T.pack (show logCount)

updateLogViewer :: AppState -> EventM Name AppState ()
updateLogViewer state = do
    logs <- liftIO $ atomically $ readTVar (appLogs state)
    when (not (null logs)) $ do
        currentTime <- liftIO getCurrentTime
        let newEntries = map (textToLogEntry currentTime) logs
            updatedLogViewer = foldr addLogEntryDirect (appLogViewer state) newEntries
        liftIO $ atomically $ modifyTVar' (appLogs state) (const [])
        State.put state {appLogViewer = updatedLogViewer}
        invalidateCache
    where
        addLogEntryDirect :: LogEntry -> LogViewerState -> LogViewerState
        addLogEntryDirect entry viewer =
            let completedLogs' = take (lvMaxDisplayLogs viewer) (entry : lvCompletedLogs viewer)
             in viewer {lvCompletedLogs = completedLogs'}

textToLogEntry :: UTCTime -> Text -> LogEntry
textToLogEntry timestamp logText
    | "error" `T.isInfixOf` T.toLower logText || "required" `T.isInfixOf` T.toLower logText =
        LogEntry LogError logText timestamp
    | "warn" `T.isInfixOf` T.toLower logText = LogEntry LogWarning logText timestamp
    | "success" `T.isInfixOf` T.toLower logText || "activated" `T.isInfixOf` T.toLower logText =
        LogEntry LogSuccess logText timestamp
    | "debug" `T.isInfixOf` T.toLower logText = LogEntry LogDebug logText timestamp
    | otherwise = LogEntry LogInfo logText timestamp

theMap :: AttrMap
theMap =
    attrMap
        V.defAttr
        [ (attrName "hint", fg V.brightBlack)
        , (attrName "title", fg V.brightCyan `V.withStyle` V.bold)
        , (attrName "subtitle", fg V.cyan)
        , (attrName "success", fg V.brightGreen)
        , (attrName "error", fg V.brightRed)
        , (attrName "warning", fg V.brightYellow)
        , (attrName "header", V.white `on` V.blue `V.withStyle` V.bold)
        , (attrName "appTitle", fg V.brightWhite `V.withStyle` V.bold)
        , (attrName "breadcrumbs", fg V.brightYellow)
        , (attrName "tabActive", V.black `on` V.brightCyan `V.withStyle` V.bold)
        , (attrName "tabInactive", fg V.brightBlack)
        , (attrName "tabNumber", fg V.brightBlue)
        , (attrName "navItem", fg V.brightWhite `V.withStyle` V.bold)
        , (attrName "navItemSelected", V.black `on` V.brightYellow `V.withStyle` V.bold)
        , (attrName "navDescription", fg V.brightBlack)
        , (attrName "statusBar", V.white `on` V.black)
        , (attrName "keyMap", fg V.brightCyan)
        , (attrName "keyMapKey", fg V.brightYellow `V.withStyle` V.bold)
        , (attrName "keyMapSep", fg V.brightBlack)
        , (attrName "cardBorder", fg V.cyan)
        , (attrName "sectionTitle", fg V.brightCyan `V.withStyle` V.bold)
        , (attrName "buttonPrimary", V.black `on` V.brightGreen `V.withStyle` V.bold)
        , (attrName "buttonSecondary", fg V.brightCyan)
        , (attrName "buttonDanger", V.black `on` V.brightRed `V.withStyle` V.bold)
        , (attrName "buttonDisabled", fg V.brightBlack)
        , (attrName "buttonLoading", fg V.brightYellow)
        , (attrName "buttonLink", fg V.brightBlue)
        , (attrName "validationError", fg V.brightRed)
        , (attrName "validationSuccess", fg V.brightGreen)
        , (attrName "tableHeader", fg V.brightCyan `V.withStyle` V.bold)
        , (attrName "emptyState", fg V.brightBlack)
        , (attrName "logInfo", fg V.brightBlue)
        , (attrName "logSuccess", fg V.brightGreen)
        , (attrName "logWarning", fg V.brightYellow)
        , (attrName "logError", fg V.brightRed)
        , (attrName "logDebug", fg V.brightBlack)
        , (attrName "timestamp", fg V.brightBlack)
        , (attrName "cursor", fg V.brightWhite `V.withStyle` V.blink)
        , (attrName "pending", fg V.brightBlack `V.withStyle` V.italic)
        ]
