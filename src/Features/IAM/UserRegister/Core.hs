{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserRegister.Core (
    UserRegisterState (..),
    UserRegisterField (..),
    UserRegisterCommand (..),
    UserRegisterEffect (..),
    EditAction (..),
    Step (..),
    initialState,
    handleCommand,
) where

import Brick.Widgets.Edit (Editor, applyEdit, editorText, getEditContents)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Zipper qualified as Z

data UserRegisterField
    = RegisterName
    | RegisterEmail
    | RegisterRole
    deriving stock (Eq, Ord, Show)

data UserRegisterState n = UserRegisterState
    { ursNameFieldName :: n
    , ursEmailFieldName :: n
    , ursRoleFieldName :: n
    , ursNameEditor :: Editor Text n
    , ursEmailEditor :: Editor Text n
    , ursRoleEditor :: Editor Text n
    , ursFocus :: UserRegisterField
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

data UserRegisterCommand
    = Submit
    | FocusNext
    | FocusPrev
    | EditFocused EditAction
    deriving stock (Eq, Show)

data UserRegisterEffect
    = RegisterUser Text Text Text
    | ReportValidationError Text
    deriving stock (Eq, Show)

data Step s e = Step
    { stepState :: s
    , stepEffects :: [e]
    }
    deriving stock (Show)

initialState :: n -> n -> n -> UserRegisterState n
initialState nameField emailField roleField =
    UserRegisterState
        { ursNameFieldName = nameField
        , ursEmailFieldName = emailField
        , ursRoleFieldName = roleField
        , ursNameEditor = editorText nameField (Just 1) ""
        , ursEmailEditor = editorText emailField (Just 1) ""
        , ursRoleEditor = editorText roleField (Just 1) ""
        , ursFocus = RegisterName
        }

handleCommand ::
    UserRegisterCommand ->
    UserRegisterState n ->
    Step (UserRegisterState n) UserRegisterEffect
handleCommand command state = case command of
    Submit -> submit state
    FocusNext -> noEffect state {ursFocus = nextFocus (ursFocus state)}
    FocusPrev -> noEffect state {ursFocus = prevFocus (ursFocus state)}
    EditFocused action -> noEffect (applyToFocusedEditor action state)

submit :: UserRegisterState n -> Step (UserRegisterState n) UserRegisterEffect
submit state =
    let name = editorValue (ursNameEditor state)
        email = editorValue (ursEmailEditor state)
        role = editorValue (ursRoleEditor state)
     in if T.null name || T.null email || T.null role
            then Step state [ReportValidationError "All fields are required."]
            else
                Step
                    (initialStateFrom state)
                    [RegisterUser name email role]

initialStateFrom :: UserRegisterState n -> UserRegisterState n
initialStateFrom state =
    initialState
        (ursNameFieldName state)
        (ursEmailFieldName state)
        (ursRoleFieldName state)

editorValue :: Editor Text n -> Text
editorValue =
    T.strip . T.unlines . getEditContents

nextFocus :: UserRegisterField -> UserRegisterField
nextFocus RegisterName = RegisterEmail
nextFocus RegisterEmail = RegisterRole
nextFocus RegisterRole = RegisterName

prevFocus :: UserRegisterField -> UserRegisterField
prevFocus RegisterName = RegisterRole
prevFocus RegisterEmail = RegisterName
prevFocus RegisterRole = RegisterEmail

applyToFocusedEditor :: EditAction -> UserRegisterState n -> UserRegisterState n
applyToFocusedEditor action state = case ursFocus state of
    RegisterName -> state {ursNameEditor = applyEdit (editOp action) (ursNameEditor state)}
    RegisterEmail -> state {ursEmailEditor = applyEdit (editOp action) (ursEmailEditor state)}
    RegisterRole -> state {ursRoleEditor = applyEdit (editOp action) (ursRoleEditor state)}

editOp :: EditAction -> Z.TextZipper Text -> Z.TextZipper Text
editOp (InsertChar c) = Z.insertChar c
editOp DeletePrevChar = Z.deletePrevChar
editOp DeleteChar = Z.deleteChar
editOp MoveLeft = Z.moveLeft
editOp MoveRight = Z.moveRight
editOp MoveHome = Z.gotoBOL
editOp MoveEnd = Z.gotoEOL

noEffect :: s -> Step s e
noEffect state = Step state []
