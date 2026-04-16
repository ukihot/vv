module App.UseCase.IAM.Login (executeLogin) where

import App.DTO.Request.IAM (LoginRequest (..))
import App.UseCase.IAM.Internal (IAMEnv (..))

-- | ログインユースケース（認証基盤は別途実装予定）
executeLogin ::
    IAMEnv m ->
    LoginRequest ->
    m ()
executeLogin env _req =
    -- TODO: 認証ドメイン実装後に差し替える
    envPresentFailure env "Login not implemented"
