{- | IAMEnv のテスト用モック
Handle パターンの恩恵: モック関数を渡すだけでユースケースをテストできる。
IO も型クラスも不要。純粋な State モナドで副作用を模倣する。
-}
module Support.IAM.MockEnv (
    -- * モック状態
    MockState (..),
    emptyMockState,

    -- * モック IAMEnv 構築
    mockIamEnv,
    mockIamEnvWithUser,
    initialStateWithUser,
) where

import App.DTO.Response.IAM (UserResponse)
import App.UseCase.IAM.Internal (IAMEnv (..))
import Control.Monad.State (State, get, modify)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Domain.IAM.Permission.Errors qualified as PermError
import Domain.IAM.Role.Errors qualified as RoleError
import Domain.IAM.Role.Events (RoleEventPayload)
import Domain.IAM.User (SomeUser (..), rehydrate)
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Events (UserEventPayload)
import Domain.IAM.User.ValueObjects.UserId (UserId, mkUserId, unUserId)
import Unsafe.Coerce (unsafeCoerce)

-- ─────────────────────────────────────────────────────────────────────────────
-- モック状態
-- ─────────────────────────────────────────────────────────────────────────────

data MockState = MockState
    { msUserEvents :: Map Text [UserEventPayload]
    , msRoleEvents :: Map Text [RoleEventPayload]
    , msPresentedSuccess :: [UserResponse]
    , msPresentedFailure :: [Text]
    }

emptyMockState :: MockState
emptyMockState = MockState Map.empty Map.empty [] []

-- | ユーザーのイベント列を事前投入した初期状態
initialStateWithUser :: UserId -> [UserEventPayload] -> MockState
initialStateWithUser uid events =
    emptyMockState {msUserEvents = Map.singleton (unUserId uid) events}

-- ─────────────────────────────────────────────────────────────────────────────
-- モック IAMEnv 構築
-- ─────────────────────────────────────────────────────────────────────────────

{- | 空のストアから始まるモック環境
State の msUserEvents を参照するので、初期状態に投入すれば loadUser で取得できる
-}
mockIamEnv :: IAMEnv (State MockState)
mockIamEnv =
    IAMEnv
        { envLoadUser = \uid -> do
            st <- get
            let events = Map.findWithDefault [] (unUserId uid) (msUserEvents st)
            case events of
                [] -> pure $ Left (RepositoryError "User not found")
                _ -> case rehydrate events of
                    Left err -> pure $ Left err
                    Right (SomeUser user) -> pure $ Right (unsafeCoerce user)
        , envSaveUser = \_ -> pure $ Right ()
        , envAppendUserEvent = \uid payload -> do
            modify $ \st ->
                st
                    { msUserEvents = Map.insertWith (<>) (unUserId uid) [payload] (msUserEvents st)
                    }
            pure $ Right ()
        , envLoadRole = \_ ->
            pure $ Left (RoleError.RepositoryError "Role not found")
        , envSaveRole = \_ -> pure $ Right ()
        , envAppendRoleEvent = \_ _ -> pure $ Right ()
        , envLoadPermission = \_ ->
            pure $ Left (PermError.RepositoryError "Permission not found")
        , envCurrentActorId = case mkUserId "system" of
            Right uid -> uid
            Left _ -> error "invalid system actor id"
        , envPresentSuccess = \resp ->
            modify $ \st -> st {msPresentedSuccess = msPresentedSuccess st <> [resp]}
        , envPresentFailure = \msg ->
            modify $ \st -> st {msPresentedFailure = msPresentedFailure st <> [msg]}
        }

{- | 既存ユーザーのイベント列を事前投入したモック環境
使い方: execState (useCase mockEnv req) (initialStateWithUser uid events)
-}
mockIamEnvWithUser :: UserId -> [UserEventPayload] -> IAMEnv (State MockState)
mockIamEnvWithUser _ _ = mockIamEnv

-- NOTE: envLoadUser は msUserEvents を State から読むので、
-- initialStateWithUser で初期状態を作って execState に渡すだけでよい。
-- 環境側のオーバーライドは不要。
