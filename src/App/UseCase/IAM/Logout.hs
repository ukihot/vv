module App.UseCase.IAM.Logout (executeLogout) where

import App.UseCase.IAM.Internal (IAMEnv)

-- | ログアウトユースケース（セッション管理は別途実装予定）
executeLogout ::
    Monad m =>
    IAMEnv m ->
    () ->
    m ()
executeLogout _env _ =
    -- TODO: セッション管理実装後に差し替える
    pure ()
