{-# LANGUAGE ImportQualifiedPost #-}

module Fw.Navigation (
    pushScreen,
    popScreen,
    switchTab,
    toggleNavigation,
    getBreadcrumbs,
) where

import Data.List (find)
import Data.Text (Text)
import Data.Text qualified as T
import Fw.AppState (
    DomainTab,
    NavigationState (..),
    Screen,
    ScreenInfo (..),
    screenRegistry,
 )

pushScreen :: Screen -> NavigationState -> NavigationState
pushScreen newScreen nav =
    nav
        { navCurrentScreen = newScreen
        , navScreenStack = navCurrentScreen nav : navScreenStack nav
        , navShowNavigation = False
        }

popScreen :: NavigationState -> NavigationState
popScreen nav = case navScreenStack nav of
    [] -> nav
    (prevScreen : rest) ->
        nav
            { navCurrentScreen = prevScreen
            , navScreenStack = rest
            }

switchTab :: DomainTab -> NavigationState -> NavigationState
switchTab newTab nav =
    nav {navCurrentTab = newTab}

toggleNavigation :: NavigationState -> NavigationState
toggleNavigation nav =
    nav {navShowNavigation = not (navShowNavigation nav)}

getBreadcrumbs :: NavigationState -> Text
getBreadcrumbs nav =
    let stack = reverse (navScreenStack nav) <> [navCurrentScreen nav]
        titles = map getScreenTitle stack
     in T.intercalate " > " titles

getScreenTitle :: Screen -> Text
getScreenTitle screen =
    case find (\s -> screenId s == screen) screenRegistry of
        Just info -> screenTitle info
        Nothing -> "Unknown"
