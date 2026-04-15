module Support.Text (fromStringText) where

import Data.Text (Text)
import Data.Text qualified as Text

fromStringText :: String -> Text
fromStringText = Text.pack
