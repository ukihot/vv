{-# LANGUAGE ImportQualifiedPost #-}
{-# OPTIONS_GHC -Wno-incomplete-patterns #-}

{- | Brick View
Presenterの状態変更を非同期/リアクティブに検知してUIに反映する。
Controllerに生データを渡す。
-}
module Adapter.View.Brick.App (runBrickApp) where

import Adapter.Controller.IAM (handleActivateUser)
import Adapter.Env (Env, mkEnv, runAppM)
import Brick
    ( App (..)
    , AttrMap
    , BrickEvent (VtyEvent)
    , EventM
    , Padding (Pad)
    , Widget
    , attrMap
    , attrName
    , defaultMain
    , halt
    , padAll
    , padBottom
    , padTop
    , showFirstCursor
    )
import Brick.Widgets.Border qualified as Border
import Brick.Widgets.Core
    ( str
    , txt
    , vBox
    , withAttr
    )
import Brick.Widgets.Edit
    ( Editor
    , editorText
    , getEditContents
    , renderEditor
    )
import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO, readTVar, writeTVar)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State (get, put)
import Data.Text (Text)
import Data.Text qualified as T
import Graphics.Vty qualified as V
import System.IO.Unsafe (unsafePerformIO)

-- ─────────────────────────────────────────────────────────────────────────────
-- UI State
-- ─────────────────────────────────────────────────────────────────────────────

data Name = UserIdField
    deriving stock (Eq, Ord, Show)

data UiState = UiState
    { -- 依存環境（Controller/Presenterへのアクセス）
      uiEnv :: Env,
      -- ログ（Presenterが更新）
      uiLogs :: TVar [Text],
      -- エディタ
      uiEditor :: Editor Text Name
    }

-- ─────────────────────────────────────────────────────────────────────────────
-- Entry Point
-- ─────────────────────────────────────────────────────────────────────────────

runBrickApp :: IO ()
runBrickApp = do
    -- 共有状態（ログ）を初期化
    logsVar <- newTVarIO ["Ready. Enter a user id and press Enter."]

    -- 依存環境を構築
    env <- mkEnv logsVar

    let initialState =
            UiState
                { uiEnv = env,
                  uiLogs = logsVar,
                  uiEditor = emptyEditor
                }

    _ <- defaultMain brickApp initialState
    pure ()

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Handling
-- ─────────────────────────────────────────────────────────────────────────────

handleEvent :: BrickEvent Name e -> EventM Name UiState ()
handleEvent ev =
    case ev of
        VtyEvent vtyEv ->
            case vtyEv of
                V.EvKey (V.KChar 'q') [] -> halt
                V.EvKey V.KEnter [] -> submitUserId
                _ -> return ()
        _ -> return ()

submitUserId :: EventM Name UiState ()
submitUserId = do
    st <- get
    let userId = T.strip (T.unlines (getEditContents (uiEditor st)))

    if T.null userId
        then do
            -- バリデーションエラー（UI層で処理）
            liftIO $ atomically $ modifyTVar' (uiLogs st) (<> ["[ERROR] User ID is required."])
        else do
            -- Controllerに生データを渡す
            liftIO $ runAppM (uiEnv st) (handleActivateUser userId)

    -- エディタをクリア
    put st {uiEditor = emptyEditor}

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
    [ padAll 1 $
        vBox
            [ Border.borderWithLabel (str "VV User Activation") $
                padAll 1 $
                    vBox
                        [ str "User ID",
                          renderEditor (txt . T.unlines) True (uiEditor st),
                          padTop (Pad 1) $
                            withAttr (attrName "hint") $
                                str "Enter: activate  q: quit"
                        ],
              padTop (Pad 1) $
                Border.borderWithLabel (str "Log") $
                    padAll 1 $
                        -- Presenterが更新したログを非同期に表示
                        vBox (map (padBottom (Pad 1) . txt) (takeLast 8 (readLogsSync st)))
            ]
    ]

-- Presenterの状態を同期的に読み取る（Brick描画時）
readLogsSync :: UiState -> [Text]
readLogsSync st = unsafePerformIO $ atomically $ readTVar (uiLogs st)

emptyEditor :: Editor Text Name
emptyEditor = editorText UserIdField (Just 1) ""

takeLast :: Int -> [a] -> [a]
takeLast n xs = drop (length xs - min n (length xs)) xs

theMap :: AttrMap
theMap =
    attrMap
        V.defAttr
        [ (attrName "hint", V.withStyle V.defAttr V.italic)
        ]
