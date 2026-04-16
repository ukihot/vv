{-# LANGUAGE ImportQualifiedPost #-}

{- |
アーキテクチャ:
- Brick: TUIフレームワーク
- 明示的DI: ReaderT Env パターン
- Event Sourcing: ユーザ登録イベント
- GADT: 型安全な状態管理

操作:
- Tab/Shift+Tab: フィールド移動
- Enter: 登録実行
- Esc: 終了
-}
module Main (main) where

import Adapter.View.Brick.App (runTuiApp)

-- ─────────────────────────────────────────────────────────────────────────────
-- メインエントリーポイント（Brick TUI版）
-- ─────────────────────────────────────────────────────────────────────────────

main :: IO ()
main = do
    runTuiApp
