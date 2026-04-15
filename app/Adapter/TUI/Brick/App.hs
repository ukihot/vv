{-# OPTIONS_GHC -Wno-incomplete-patterns #-}

module Adapter.TUI.Brick.App (runBrickApp) where

import Adapter.TUI.Brick.Runtime
    ( BackendState (..)
    , bootstrapState
    , logs
    , runActivateUser
    )
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
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State (get, put)
import Data.Text qualified as T
import Graphics.Vty qualified as V

data Name = UserIdField
    deriving stock (Eq, Ord, Show)

data UiState = UiState
    { backend :: BackendState,
      editor :: Editor T.Text Name
    }

runBrickApp :: IO ()
runBrickApp = do
    initialBackend <- either (fail . show) pure bootstrapState
    let initialState =
            UiState
                { backend = initialBackend,
                  editor = emptyEditor
                }
    _ <- defaultMain brickApp initialState
    pure ()

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
    let userId = T.strip (T.unlines (getEditContents (editor st)))
    nextBackend <-
        if T.null userId
            then
                pure $
                    (backend st)
                        { logs = logs (backend st) <> ["[ERROR] User ID is required."]
                        }
            else liftIO $ runActivateUser (backend st) userId
    put st {backend = nextBackend, editor = emptyEditor}

brickApp :: App UiState e Name
brickApp =
    App
        { appDraw = drawUi,
          appChooseCursor = showFirstCursor,
          appHandleEvent = handleEvent,
          appStartEvent = pure (),
          appAttrMap = const theMap
        }

drawUi :: UiState -> [Widget Name]
drawUi st =
    [ padAll 1 $
        vBox
            [ Border.borderWithLabel (str "VV User Activation") $
                padAll 1 $
                    vBox
                        [ str "User ID",
                          renderEditor (txt . T.unlines) True (editor st),
                          padTop (Pad 1) $
                            withAttr (attrName "hint") $
                                str "Enter: activate  q: quit"
                        ],
              padTop (Pad 1) $
                Border.borderWithLabel (str "Log") $
                    padAll 1 $
                        vBox (map (padBottom (Pad 1) . txt) (takeLast 8 (logs (backend st))))
            ]
    ]

emptyEditor :: Editor T.Text Name
emptyEditor = editorText UserIdField (Just 1) ""

takeLast :: Int -> [a] -> [a]
takeLast n xs = drop (length xs - min n (length xs)) xs

theMap :: AttrMap
theMap =
    attrMap
        V.defAttr
        [ (attrName "hint", V.withStyle V.defAttr V.italic)
        ]
