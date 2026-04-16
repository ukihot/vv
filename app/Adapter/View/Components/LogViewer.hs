{-# LANGUAGE ImportQualifiedPost #-}

{- | ログビューワーコンポーネント
リアルタイムログ表示とタイプライター風アニメーション。
キューに溜まったログを順次表示し、待機ログが多いほど高速化する。
-}
module Adapter.View.Components.LogViewer (
    -- * ログビューワー状態
    LogViewerState (
        LogViewerState,
        lvCompletedLogs,
        lvCurrentLog,
        lvCurrentCharCount,
        lvPendingLogs,
        lvAnimationSpeed,
        lvMaxDisplayLogs
    ),
    LogEntry (LogEntry, logLevel, logMessage, logTimestamp),
    LogLevel (..),
    initialLogViewerState,

    -- * 状態更新
    addLogEntry,
    updateTypewriterAnimation,

    -- * レンダリング
    renderLogViewer,
    renderLogEntry,
) where

import Brick (
    AttrName,
    Padding (Pad),
    Widget,
    attrName,
    hBox,
    padLeft,
    padRight,
    str,
    txt,
    vBox,
    withAttr,
 )
import Brick.Widgets.Border qualified as Border
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (UTCTime, defaultTimeLocale, formatTime)

-- ─────────────────────────────────────────────────────────────────────────────
-- ログビューワー状態
-- ─────────────────────────────────────────────────────────────────────────────

data LogLevel
    = LogInfo
    | LogSuccess
    | LogWarning
    | LogError
    | LogDebug
    deriving stock (Eq, Show)

data LogEntry = LogEntry
    { logLevel :: LogLevel
    , logMessage :: Text
    , logTimestamp :: UTCTime
    }
    deriving stock (Eq, Show)

data LogViewerState = LogViewerState
    { -- 表示済みログ（完全に表示されたもの）
      lvCompletedLogs :: [LogEntry]
    , -- 現在表示中のログ（タイプライター中）
      lvCurrentLog :: Maybe LogEntry
    , -- 現在表示中の文字数
      lvCurrentCharCount :: Int
    , -- 待機中のログキュー
      lvPendingLogs :: [LogEntry]
    , -- アニメーション速度（ミリ秒）
      lvAnimationSpeed :: Int
    , -- 最大表示ログ数
      lvMaxDisplayLogs :: Int
    }
    deriving stock (Eq, Show)

initialLogViewerState :: LogViewerState
initialLogViewerState =
    LogViewerState
        { lvCompletedLogs = []
        , lvCurrentLog = Nothing
        , lvCurrentCharCount = 0
        , lvPendingLogs = []
        , lvAnimationSpeed = 50 -- 50ms per character
        , lvMaxDisplayLogs = 10
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態更新
-- ─────────────────────────────────────────────────────────────────────────────

-- | 新しいログエントリを追加
addLogEntry :: LogEntry -> LogViewerState -> LogViewerState
addLogEntry entry state =
    state {lvPendingLogs = lvPendingLogs state <> [entry]}

-- | タイプライターアニメーションを更新
updateTypewriterAnimation :: LogViewerState -> LogViewerState
updateTypewriterAnimation state = case lvCurrentLog state of
    Nothing ->
        -- 現在表示中のログがない場合、待機ログから次を開始
        case lvPendingLogs state of
            [] -> state -- 待機ログもない
            (nextLog : remainingLogs) ->
                let charsToShow = calculateCharsToShow (length remainingLogs)
                 in state
                        { lvCurrentLog = Just nextLog
                        , lvCurrentCharCount = charsToShow -- 複数文字を一度に表示
                        , lvPendingLogs = remainingLogs
                        , lvAnimationSpeed = calculateSpeed (length remainingLogs)
                        }
    Just currentLog ->
        let messageLength = T.length (logMessage currentLog)
            currentCount = lvCurrentCharCount state
            charsToAdd = calculateCharsToShow (length (lvPendingLogs state))
         in if currentCount >= messageLength
                then
                    -- 現在のログ表示完了、完了リストに移動
                    let completedLogs' = take (lvMaxDisplayLogs state - 1) (currentLog : lvCompletedLogs state)
                     in state
                            { lvCompletedLogs = completedLogs'
                            , lvCurrentLog = Nothing
                            , lvCurrentCharCount = 0
                            }
                else
                    -- 次の文字を表示（複数文字を一度に）
                    state
                        { lvCurrentCharCount = min messageLength (currentCount + charsToAdd)
                        , lvAnimationSpeed = calculateSpeed (length (lvPendingLogs state))
                        }

-- | 待機ログ数に応じて一度に表示する文字数を計算
calculateCharsToShow :: Int -> Int
calculateCharsToShow pendingCount
    | pendingCount == 0 = 1 -- 通常速度（1文字ずつ）
    | pendingCount <= 2 = 2 -- 少し高速（2文字ずつ）
    | pendingCount <= 5 = 5 -- 高速（5文字ずつ）
    | otherwise = 10 -- 超高速（10文字ずつ）

-- | 待機ログ数に応じてアニメーション速度を計算
calculateSpeed :: Int -> Int
calculateSpeed pendingCount
    | pendingCount == 0 = 50 -- 通常速度
    | pendingCount <= 2 = 30 -- 少し高速
    | pendingCount <= 5 = 20 -- 高速
    | otherwise = 10 -- 超高速

-- ─────────────────────────────────────────────────────────────────────────────
-- レンダリング
-- ─────────────────────────────────────────────────────────────────────────────

renderLogViewer :: LogViewerState -> Widget n
renderLogViewer state =
    Border.borderWithLabel (txt " System Logs ") $
        vBox $
            -- 完了したログを表示（新しいものが上）
            map renderLogEntry (reverse (lvCompletedLogs state))
                <>
                -- 現在表示中のログ（タイプライター効果）
                maybe
                    []
                    (\currentLog -> [renderCurrentLog currentLog (lvCurrentCharCount state)])
                    (lvCurrentLog state)
                <>
                -- 待機ログ数の表示
                if null (lvPendingLogs state)
                    then []
                    else [renderPendingIndicator (length (lvPendingLogs state))]

renderLogEntry :: LogEntry -> Widget n
renderLogEntry entry =
    hBox
        [ withAttr (logLevelAttr (logLevel entry)) $
            padRight (Pad 1) $
                str (logLevelPrefix (logLevel entry))
        , withAttr (attrName "timestamp") $
            padRight (Pad 1) $
                str (formatTime defaultTimeLocale "%H:%M:%S" (logTimestamp entry))
        , txt (logMessage entry)
        ]

renderCurrentLog :: LogEntry -> Int -> Widget n
renderCurrentLog entry charCount =
    let displayText = T.take charCount (logMessage entry)
        cursor = if charCount < T.length (logMessage entry) then "▋" else ""
     in hBox
            [ withAttr (logLevelAttr (logLevel entry)) $
                padRight (Pad 1) $
                    str (logLevelPrefix (logLevel entry))
            , withAttr (attrName "timestamp") $
                padRight (Pad 1) $
                    str (formatTime defaultTimeLocale "%H:%M:%S" (logTimestamp entry))
            , txt displayText
            , withAttr (attrName "cursor") $ txt cursor
            ]

renderPendingIndicator :: Int -> Widget n
renderPendingIndicator count =
    withAttr (attrName "pending") $
        padLeft (Pad 2) $
            txt $
                "(" <> T.pack (show count) <> " more logs pending...)"

-- ─────────────────────────────────────────────────────────────────────────────
-- ヘルパー関数
-- ─────────────────────────────────────────────────────────────────────────────

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
