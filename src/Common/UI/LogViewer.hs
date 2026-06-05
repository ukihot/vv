{-# LANGUAGE ImportQualifiedPost #-}

module Common.UI.LogViewer (
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
    addLogEntry,
    updateTypewriterAnimation,
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
    { lvCompletedLogs :: [LogEntry]
    , lvCurrentLog :: Maybe LogEntry
    , lvCurrentCharCount :: Int
    , lvPendingLogs :: [LogEntry]
    , lvAnimationSpeed :: Int
    , lvMaxDisplayLogs :: Int
    }
    deriving stock (Eq, Show)

initialLogViewerState :: LogViewerState
initialLogViewerState =
    LogViewerState
        { lvCompletedLogs = []
        , lvCurrentLog = Nothing
        , lvCurrentCharCount = 0
        , lvPendingLogs = []
        , lvAnimationSpeed = 50
        , lvMaxDisplayLogs = 10
        }

addLogEntry :: LogEntry -> LogViewerState -> LogViewerState
addLogEntry entry state =
    state {lvPendingLogs = lvPendingLogs state <> [entry]}

updateTypewriterAnimation :: LogViewerState -> LogViewerState
updateTypewriterAnimation state = case lvCurrentLog state of
    Nothing -> case lvPendingLogs state of
        [] -> state
        (nextLog : remainingLogs) ->
            let charsToShow = calculateCharsToShow (length remainingLogs)
             in state
                    { lvCurrentLog = Just nextLog
                    , lvCurrentCharCount = charsToShow
                    , lvPendingLogs = remainingLogs
                    , lvAnimationSpeed = calculateSpeed (length remainingLogs)
                    }
    Just currentLog ->
        let messageLength = T.length (logMessage currentLog)
            currentCount = lvCurrentCharCount state
            charsToAdd = calculateCharsToShow (length (lvPendingLogs state))
         in if currentCount >= messageLength
                then
                    let completedLogs' = take (lvMaxDisplayLogs state - 1) (currentLog : lvCompletedLogs state)
                     in state
                            { lvCompletedLogs = completedLogs'
                            , lvCurrentLog = Nothing
                            , lvCurrentCharCount = 0
                            }
                else
                    state
                        { lvCurrentCharCount = min messageLength (currentCount + charsToAdd)
                        , lvAnimationSpeed = calculateSpeed (length (lvPendingLogs state))
                        }

calculateCharsToShow :: Int -> Int
calculateCharsToShow pendingCount
    | pendingCount == 0 = 1
    | pendingCount <= 2 = 2
    | pendingCount <= 5 = 5
    | otherwise = 10

calculateSpeed :: Int -> Int
calculateSpeed pendingCount
    | pendingCount == 0 = 50
    | pendingCount <= 2 = 30
    | pendingCount <= 5 = 20
    | otherwise = 10

renderLogViewer :: LogViewerState -> Widget n
renderLogViewer state =
    Border.borderWithLabel (txt " System Logs ") $
        vBox $
            map renderLogEntry (reverse (lvCompletedLogs state))
                <> maybe
                    []
                    (\currentLog -> [renderCurrentLog currentLog (lvCurrentCharCount state)])
                    (lvCurrentLog state)
                <> if null (lvPendingLogs state)
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
        cursor = if charCount < T.length (logMessage entry) then "|" else ""
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
