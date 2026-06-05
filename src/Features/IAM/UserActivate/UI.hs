{-# LANGUAGE ImportQualifiedPost #-}

module Features.IAM.UserActivate.UI (
    draw,
) where

import Brick (Padding (Pad), Widget, padTop, vBox)
import Common.UI.Button (renderPrimaryButton)
import Common.UI.Form (renderTextInput)
import Common.UI.Layout (renderCard)
import Features.IAM.UserActivate.Core (UserActivateState (..))

draw :: (Ord n, Show n) => UserActivateState n -> Widget n
draw state =
    renderCard (Just "User Activation") $
        vBox
            [ renderTextInput "User ID" (uasUserIdEditor state) True
            , padTop (Pad 1) $
                renderPrimaryButton "Activate" "Enter"
            ]
