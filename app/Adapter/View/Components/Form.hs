{-# LANGUAGE ImportQualifiedPost #-}

{- | フォームコンポーネント
入力フィールド、バリデーション表示、フォームレイアウト等の再利用可能なコンポーネント。
Brick固有の実装だが、将来的に他のUIフレームワークに移植可能な設計。
-}
module Adapter.View.Components.Form (
    -- * Input Fields
    renderTextInput,
    renderTextArea,
    renderPasswordInput,

    -- * Validation
    renderValidationError,
    renderValidationSuccess,

    -- * Form Layout
    renderFormField,
    renderFormGroup,
    renderFormActions,
)
where

import Brick (
    Padding (Pad),
    Widget,
    attrName,
    padBottom,
    padLeft,
    padTop,
    str,
    txt,
    vBox,
    withAttr,
 )
import Brick.Widgets.Edit (Editor, renderEditor)
import Data.Text (Text)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Input Fields
-- ─────────────────────────────────────────────────────────────────────────────

-- | テキスト入力フィールド
renderTextInput ::
    (Ord n, Show n) =>
    -- | ラベル
    Text ->
    -- | エディタ
    Editor Text n ->
    -- | フォーカス状態
    Bool ->
    Widget n
renderTextInput label editor focused =
    vBox
        [ txt label
        , renderEditor (txt . T.unlines) focused editor
        ]

-- | テキストエリア（複数行）
renderTextArea ::
    (Ord n, Show n) =>
    Text ->
    Editor Text n ->
    Bool ->
    Widget n
renderTextArea = renderTextInput -- 現状は同じ実装

-- | パスワード入力フィールド
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Validation
-- ─────────────────────────────────────────────────────────────────────────────

-- | バリデーションエラー表示
renderValidationError :: Text -> Widget n
renderValidationError msg =
    padLeft (Pad 2) $
        withAttr (attrName "validationError") $
            txt ("✗ " <> msg)

-- | バリデーション成功表示
renderValidationSuccess :: Text -> Widget n
renderValidationSuccess msg =
    padLeft (Pad 2) $
        withAttr (attrName "validationSuccess") $
            txt ("✓ " <> msg)

-- ─────────────────────────────────────────────────────────────────────────────
-- Form Layout
-- ─────────────────────────────────────────────────────────────────────────────

-- | フォームフィールド（ラベル + 入力 + バリデーション）
renderFormField ::
    -- | ラベル
    Text ->
    -- | 入力ウィジェット
    Widget n ->
    -- | バリデーションメッセージ（Nothing = バリデーション未実施）
    Maybe (Either Text Text) ->
    Widget n
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

-- | フォームグループ（複数フィールドをまとめる）
renderFormGroup ::
    -- | グループタイトル
    Text ->
    -- | フィールドリスト
    [Widget n] ->
    Widget n
renderFormGroup title fields =
    vBox
        [ withAttr (attrName "formGroupTitle") $ txt title
        , padLeft (Pad 2) $ vBox fields
        ]

-- | フォームアクション（送信ボタン等）
renderFormActions ::
    -- | アクションボタンリスト
    [Widget n] ->
    Widget n
renderFormActions actions =
    padTop (Pad 1) $
        vBox actions
