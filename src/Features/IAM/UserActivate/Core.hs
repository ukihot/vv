{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserActivate.Core (
    UserActivateState (..),
    UserActivateCommand (..),
    UserActivateEffect (..),
    EditAction (..),
    Step (..),
    initialState,
    handleCommand,
) where

import Brick.Widgets.Edit (Editor, applyEdit, editorText, getEditContents)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Zipper qualified as Z

data UserActivateState n = UserActivateState
    { uasUserIdFieldName :: n
    , uasUserIdEditor :: Editor Text n
    }
    deriving stock (Show)

data EditAction
    = InsertChar Char
    | DeletePrevChar
    | DeleteChar
    | MoveLeft
    | MoveRight
    | MoveHome
    | MoveEnd
    deriving stock (Eq, Show)

data UserActivateCommand
    = Submit
    | EditUserId EditAction
    deriving stock (Eq, Show)

data UserActivateEffect
    = ActivateUser Text
    | ReportValidationError Text
    deriving stock (Eq, Show)

data Step s e = Step
    { stepState :: s
    , stepEffects :: [e]
    }
    deriving stock (Show)

initialState :: n -> UserActivateState n
initialState userIdField =
    UserActivateState
        { uasUserIdFieldName = userIdField
        , uasUserIdEditor = editorText userIdField (Just 1) ""
        }

handleCommand ::
    UserActivateCommand ->
    UserActivateState n ->
    Step (UserActivateState n) UserActivateEffect
handleCommand command state = case command of
    Submit -> submit state
    EditUserId action ->
        Step
            state {uasUserIdEditor = applyEdit (editOp action) (uasUserIdEditor state)}
            []

submit :: UserActivateState n -> Step (UserActivateState n) UserActivateEffect
submit state =
    let userId = T.strip $ T.unlines $ getEditContents (uasUserIdEditor state)
     in if T.null userId
            then Step state [ReportValidationError "User ID is required."]
            else
                Step
                    (initialState (uasUserIdFieldName state))
                    [ActivateUser userId]

editOp :: EditAction -> Z.TextZipper Text -> Z.TextZipper Text
editOp (InsertChar c) = Z.insertChar c
editOp DeletePrevChar = Z.deletePrevChar
editOp DeleteChar = Z.deleteChar
editOp MoveLeft = Z.moveLeft
editOp MoveRight = Z.moveRight
editOp MoveHome = Z.gotoBOL
editOp MoveEnd = Z.gotoEOL
