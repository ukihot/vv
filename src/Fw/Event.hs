module Fw.Event (
    AppEvent (..),
) where

data AppEvent
    = LogUpdated
    deriving stock (Eq, Show)
