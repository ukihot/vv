{-# LANGUAGE ImportQualifiedPost #-}

{- | ナビゲーション機能
画面遷移、スタック管理、パンくずリスト生成を提供する。
-}
module Adapter.View.Brick.Navigation (
    -- * Navigation Operations
    pushScreen,
    popScreen,
    switchTab,
    toggleNavigation,
    getBreadcrumbs,

    -- * Initial State
    initialNavigation,
)
where

import Adapter.View.Brick.Types (
    DomainTab (..),
    NavigationState (..),
    Screen (..),
    ScreenInfo (..),
    screenRegistry,
 )
import Data.List (find)
import Data.Text (Text)
import Data.Text qualified as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Initial State
-- ─────────────────────────────────────────────────────────────────────────────

initialNavigation :: NavigationState
initialNavigation =
    NavigationState
        { navCurrentScreen = ScreenHome
        , navScreenStack = []
        , navCurrentTab = TabIAM
        , navShowNavigation = False
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- Navigation Operations
-- ─────────────────────────────────────────────────────────────────────────────

-- | 画面をスタックにプッシュして遷移
pushScreen :: Screen -> NavigationState -> NavigationState
pushScreen newScreen nav =
    nav
        { navCurrentScreen = newScreen
        , navScreenStack = navCurrentScreen nav : navScreenStack nav
        , navShowNavigation = False -- 遷移時はナビゲーションを閉じる
        }

-- | スタックから画面をポップして戻る
popScreen :: NavigationState -> NavigationState
popScreen nav = case navScreenStack nav of
    [] -> nav -- スタックが空なら何もしない
    (prevScreen : rest) ->
        nav
            { navCurrentScreen = prevScreen
            , navScreenStack = rest
            }

-- | タブを切り替え
switchTab :: DomainTab -> NavigationState -> NavigationState
switchTab newTab nav =
    nav
        { navCurrentTab = newTab
        }

-- | ナビゲーションメニューの表示/非表示を切り替え
toggleNavigation :: NavigationState -> NavigationState
toggleNavigation nav =
    nav
        { navShowNavigation = not (navShowNavigation nav)
        }

-- ─────────────────────────────────────────────────────────────────────────────
-- Breadcrumbs (パンくずリスト)
-- ─────────────────────────────────────────────────────────────────────────────

-- | パンくずリストを生成
getBreadcrumbs :: NavigationState -> Text
getBreadcrumbs nav =
    let stack = reverse (navScreenStack nav) <> [navCurrentScreen nav]
        titles = map getScreenTitle stack
     in T.intercalate " > " titles

-- 画面タイトルを取得
getScreenTitle :: Screen -> Text
getScreenTitle screen =
    case find (\s -> screenId s == screen) screenRegistry of
        Just info -> screenTitle info
        Nothing -> "Unknown"
