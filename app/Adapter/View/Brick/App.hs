{-# LANGUAGE ImportQualifiedPost #-}
{-# OPTIONS_GHC -Wno-incomplete-patterns #-}

{- | Brick View
Presenterの状態変更を非同期/リアクティブに検知してUIに反映する。
Controllerに生データを渡す。

画面構成:
  - パンくずリスト
  - タブバー（ドメイン集約単位）
  - ナビゲーションメニュー（タブ内の画面一覧）
  - メインコンテンツ
  - ログパネル
  - 戻るボタン
-}
module Adapter.View.Brick.App (runBrickApp) where

import Adapter.Controller.IAM (handleActivateUser)
import Adapter.Env (Env, mkEnv, runAppM)
import Adapter.View.Brick.Navigation
    ( getBreadcrumbs
    , initialNavigation
    , popScreen
    , pushScreen
    , switchTab
    , toggleNavigation
    )
import Adapter.View.Brick.Screens (renderScreen)
import Adapter.View.Brick.Types
    ( DomainTab (..)
    , Name (..)
    , NavigationState (..)
    , Screen (..)
    , UiState (..)
    )
import Adapter.View.Brick.Widgets
    ( renderBackButton
    , renderBreadcrumbs
    , renderLogPanel
    , renderNavigationMenu
    , renderTabBar
    )
import Brick
    ( App (..)
    , AttrMap
    , AttrName
    , BrickEvent (VtyEvent)
    , EventM
    , Padding (Max, Pad)
    , Widget
    , attrMap
    , attrName
    , defaultMain
    , fg
    , hBox
    , hLimit
    , halt
    , on
    , padAll
    , padLeft
    , padRight
    , showFirstCursor
    , vBox
    , vLimit
    )
import Brick.Widgets.Edit
    ( Editor
    , editorText
    , getEditContents
    )
import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State qualified
import Data.Text (Text)
import Data.Text qualified as T
import Graphics.Vty qualified as V

-- ─────────────────────────────────────────────────────────────────────────────
-- Entry Point
-- ─────────────────────────────────────────────────────────────────────────────

runBrickApp :: IO ()
runBrickApp = do
    -- 共有状態（ログ）を初期化
    logsVar <- newTVarIO ["Ready. Press 'n' to open navigation."]

    -- 依存環境を構築
    env <- mkEnv logsVar

    let initialState =
            UiState
                { uiEnv = env,
                  uiLogs = logsVar,
                  uiNavigation = initialNavigation,
                  uiUserIdEditor = emptyEditor
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
                -- ナビゲーション表示/非表示
                V.EvKey (V.KChar 'n') [] -> do
                    let nav' = toggleNavigation (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav'}
                -- 戻る
                V.EvKey V.KEsc [] -> do
                    let nav' = popScreen (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav'}
                -- タブ切り替え
                V.EvKey (V.KChar '\t') [] -> do
                    let currentTab = navCurrentTab (uiNavigation st)
                        nextTab = cycleTab currentTab
                        nav' = switchTab nextTab (uiNavigation st)
                    Control.Monad.State.put st {uiNavigation = nav'}
                -- 画面固有のイベント処理
                _ -> handleScreenEvent vtyEv st
        _ -> pure ()

-- タブを循環
cycleTab :: DomainTab -> DomainTab
cycleTab TabIAM = TabAccounting
cycleTab TabAccounting = TabIFRS
cycleTab TabIFRS = TabOps
cycleTab TabOps = TabAudit
cycleTab TabAudit = TabOrg
cycleTab TabOrg = TabIAM

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
    _ -> pure ()

-- ─────────────────────────────────────────────────────────────────────────────
-- Brick App Definition
-- ─────────────────────────────────────────────────────────────────────────────

brickApp :: App UiState e Name
brickApp =
    App
        { appDraw = drawUi,
          appChooseCursor = showFirstCursor,
          appHandleEvent = handleEvent,
          appStartEvent = pure (),
          appAttrMap = const theMap
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Rendering
-- ─────────────────────────────────────────────────────────────────────────────

drawUi :: UiState -> [Widget Name]
drawUi st =
    let nav = uiNavigation st
        breadcrumbs = getBreadcrumbs nav
        canGoBack = not (null (navScreenStack nav))
     in [ padAll 1 $
            vBox
                [ -- パンくずリスト
                  renderBreadcrumbs breadcrumbs,
                  -- タブバー
                  renderTabBar (navCurrentTab nav),
                  -- メインコンテンツ
                  if navShowNavigation nav
                    then renderWithNavigation st
                    else renderMainContent st,
                  -- ログパネル
                  renderLogPanel st,
                  -- 戻るボタン
                  renderBackButton canGoBack
                ]
        ]

-- ナビゲーションメニュー付きレイアウト
renderWithNavigation :: UiState -> Widget Name
renderWithNavigation st =
    hBox
        [ hLimit 40 $ renderNavigationMenu (navCurrentTab (uiNavigation st)),
          padLeft (Pad 1) $ renderMainContent st
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
        [ (attrName "hint", fg V.brightBlack),
          (attrName "title", fg V.brightCyan),
          (attrName "breadcrumbs", fg V.brightYellow),
          (attrName "tabActive", V.white `on` V.blue),
          (attrName "tabInactive", fg V.brightBlack),
          (attrName "navItem", fg V.brightWhite),
          (attrName "navDescription", fg V.brightBlack),
          (attrName "backButton", fg V.brightGreen),
          (attrName "backButtonDisabled", fg V.brightBlack)
        ]
