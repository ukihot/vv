{-# LANGUAGE ImportQualifiedPost #-}

module Common.UI.Form (
    renderTextInput,
    renderTextArea,
    renderPasswordInput,
    renderValidationError,
    renderValidationSuccess,
    renderFormField,
    renderFormGroup,
    renderFormActions,
) where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    padBottom,
    padLeft,
    padTop,
    txt,
    vBox,
    withAttr,
 )
import Brick.Widgets.Edit (Editor, renderEditor)
import Data.Text (Text)
import Data.Text qualified as T

renderTextInput ::
    (Ord n, Show n) =>
    Text ->
    Editor Text n ->
    Bool ->
    Widget n
renderTextInput label editor focused =
    vBox
        [ txt label
        , renderEditor (txt . T.unlines) focused editor
        ]

renderTextArea ::
    (Ord n, Show n) =>
    Text ->
    Editor Text n ->
    Bool ->
    Widget n
renderTextArea = renderTextInput

renderPasswordInput ::
    (Ord n, Show n) =>
    Text ->
    Editor Text n ->
    Bool ->
    Widget n
renderPasswordInput label editor focused =
    vBox
        [ txt label
        , renderEditor (const (txt "********")) focused editor
        ]

renderValidationError :: Text -> Widget n
renderValidationError msg =
    padLeft (Pad 2) $
        withAttr (attrName "validationError") $
            txt ("x " <> msg)

renderValidationSuccess :: Text -> Widget n
renderValidationSuccess msg =
    padLeft (Pad 2) $
        withAttr (attrName "validationSuccess") $
            txt ("ok " <> msg)

renderFormField :: Text -> Widget n -> Maybe (Either Text Text) -> Widget n
renderFormField label inputWidget validation =
    padBottom (Pad 1) $
        vBox
            [ txt label
            , inputWidget
            , case validation of
                Nothing -> txt ""
                Just (Left err) -> renderValidationError err
                Just (Right msg) -> renderValidationSuccess msg
            ]

renderFormGroup :: Text -> [Widget n] -> Widget n
renderFormGroup title fields =
    vBox
        [ withAttr (attrName "formGroupTitle") $ txt title
        , padLeft (Pad 2) $ vBox fields
        ]

renderFormActions :: [Widget n] -> Widget n
renderFormActions actions =
    padTop (Pad 1) $
        vBox actions
