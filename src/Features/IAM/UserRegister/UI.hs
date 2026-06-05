{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserRegister.UI (
    draw,
) where

import Brick (Padding (Pad), Widget, attrName, padTop, txt, vBox, withAttr)
import Common.UI.Button (renderPrimaryButton)
import Common.UI.Form (renderTextInput)
import Common.UI.Layout (renderCard, renderSpacer)
import Features.IAM.UserRegister.Core (
    UserRegisterField (..),
    UserRegisterState (..),
 )

draw :: (Ord n, Show n) => UserRegisterState n -> Widget n
draw state =
    renderCard (Just "User Registration") $
        vBox
            [ renderTextInput "Name" (ursNameEditor state) (ursFocus state == RegisterName)
            , renderSpacer 1
            , renderTextInput "Email" (ursEmailEditor state) (ursFocus state == RegisterEmail)
            , renderSpacer 1
            , renderTextInput "Role" (ursRoleEditor state) (ursFocus state == RegisterRole)
            , padTop (Pad 2) $
                renderPrimaryButton "Register User" "Enter"
            , renderSpacer 1
            , withAttr (attrName "hint") $ txt "Tab/Shift+Tab: Navigate fields, Enter: Register"
            ]
