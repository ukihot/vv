{-# LANGUAGE ScopedTypeVariables #-}

{- | ロールからの権限剥奪ユースケース
#45, #46: 型クラス DI を廃止。IAMEnv レコードで依存を注入。
-}
module App.UseCase.IAM.RevokePermission (executeRevokePermission) where

import App.DTO.Request.IAM (RevokePermissionRequest (..))
import App.UseCase.IAM.Internal (IAMEnv (..), RoleAppM, liftRoleDomain, runRoleAppM)
import Control.Monad.Except (liftEither)
import Control.Monad.Reader (ask)
import Domain.IAM.Permission.Errors qualified as PermError
import Domain.IAM.Permission.ValueObjects.PermissionId (mkPermissionId)
import Domain.IAM.Role (revokePermissionFromRole)
import Domain.IAM.Role.Errors (DomainError (..), domainErrorMessage)
import Domain.IAM.Role.ValueObjects.RoleId (mkRoleId)

executeRevokePermission ::
    forall m.
    Monad m =>
    IAMEnv m ->
    RevokePermissionRequest ->
    m ()
executeRevokePermission env (RevokePermissionRequest rawRoleId rawPermId) = do
    result <- runRoleAppM env pipeline
    case result of
        Left err -> envPresentFailure env (domainErrorMessage err)
        Right _ -> pure () -- TODO: 更新後のロール一覧を返す
    where
        pipeline :: RoleAppM m ()
        pipeline = do
            env' <- ask
            roleId <- liftEither $ mkRoleId rawRoleId
            permId <- liftEither $ mapPermError (mkPermissionId rawPermId)
            actorId <- pure $ envCurrentActorId env' -- #25: 認証コンテキストから取得
            -- 1. Active ロール読み込み
            activeRole <- liftRoleDomain $ envLoadRole env' roleId
            -- 2. ドメインロジック適用
            let (updatedRole, _event) = revokePermissionFromRole actorId permId activeRole
            -- 3. 保存
            liftRoleDomain $ envSaveRole env' updatedRole

        mapPermError :: Either PermError.DomainError a -> Either DomainError a
        mapPermError (Left _) = Left EmptyPermissionSet
        mapPermError (Right a) = Right a
