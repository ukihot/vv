{- | ユーザー集約
#3, #4, #15: GADT + DataKinds で不正状態を構造的に排除する。
#5: 遷移関数の型シグネチャが仕様書になる。
#22: rehydrate でイベント列から状態を再構築する。
-}
module Domain.IAM.User (
    -- * 集約
    User (..),
    UserState (..),

    -- * ゲッター
    getUserId,
    getUserProfile,
    getUserVersion,

    -- * 状態遷移
    activateUser,
    suspendUser,
    unsuspendUser,
    deactivateUser,

    -- * 存在型 (#20: 型消去は Application 層のみ)
    SomeUser (..),

    -- * Event Sourcing (#22)
    applyEvent,
    rehydrate,
)
where

import Control.Monad (foldM)
import Domain.IAM.User.Entities.Profile (UserProfile (..))
import Domain.IAM.User.Errors (DomainError (..))
import Domain.IAM.User.Events (
    UserEventPayload (..),
    UserEventPayloadV1 (..),
    UserEventPayloadV2 (..),
 )
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.IAM.User.ValueObjects.UserState (UserState (..))
import Domain.IAM.User.ValueObjects.Version (Version (..), initialVersion, nextVersion)

-- ─────────────────────────────────────────────────────────────────────────────
-- 集約 GADT (#3, #15)
-- ─────────────────────────────────────────────────────────────────────────────

data User (s :: UserState) where
    UserP :: UserId -> UserProfile -> Version -> User 'Pending
    UserA :: UserId -> UserProfile -> Version -> User 'Active
    UserS :: UserId -> UserProfile -> Version -> User 'Suspended
    UserI :: UserId -> UserProfile -> Version -> User 'Inactive

deriving instance Show (User s)

deriving instance Eq (User s)

-- | 存在型: Application 層でのみ使用する (#20)
data SomeUser where
    SomeUser :: User s -> SomeUser

deriving instance Show SomeUser

-- ─────────────────────────────────────────────────────────────────────────────
-- ゲッター
-- ─────────────────────────────────────────────────────────────────────────────

getUserId :: User s -> UserId
getUserId (UserP i _ _) = i
getUserId (UserA i _ _) = i
getUserId (UserS i _ _) = i
getUserId (UserI i _ _) = i

getUserProfile :: User s -> UserProfile
getUserProfile (UserP _ p _) = p
getUserProfile (UserA _ p _) = p
getUserProfile (UserS _ p _) = p
getUserProfile (UserI _ p _) = p

getUserVersion :: User s -> Version
getUserVersion (UserP _ _ v) = v
getUserVersion (UserA _ _ v) = v
getUserVersion (UserS _ _ v) = v
getUserVersion (UserI _ _ v) = v

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移 (#5: 型シグネチャが仕様書)
-- ─────────────────────────────────────────────────────────────────────────────

-- | 承認: Pending → Active
activateUser :: User 'Pending -> (User 'Active, UserEventPayload)
activateUser (UserP uid profile v) =
    (UserA uid profile (nextVersion v), V1 (UserActivated uid))

-- | 凍結: Active → Suspended
suspendUser :: User 'Active -> (User 'Suspended, UserEventPayload)
suspendUser (UserA uid profile v) =
    (UserS uid profile (nextVersion v), V2 (UserSuspended uid))

-- | 凍結解除: Suspended → Active
unsuspendUser :: User 'Suspended -> (User 'Active, UserEventPayload)
unsuspendUser (UserS uid profile v) =
    (UserA uid profile (nextVersion v), V2 (UserUnsuspended uid))

{- | 無効化: Active または Suspended → Inactive
Pending は「承認前」なので無効化ではなく却下として別定義する (#4)
-}
deactivateUser :: User s -> Either DomainError (User 'Inactive, UserEventPayload)
deactivateUser user = case user of
    UserA uid profile v -> Right (UserI uid profile (nextVersion v), V2 (UserDeactivated uid))
    UserS uid profile v -> Right (UserI uid profile (nextVersion v), V2 (UserDeactivated uid))
    _ -> Left IllegalTransition

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Sourcing (#22, #30)
-- ─────────────────────────────────────────────────────────────────────────────

{- | 単一イベントを現在状態に適用する。
中央ルーター: ディスパッチのみ。処理は各遷移関数に委譲 (#16, #17)。
-}
applyEvent :: Maybe SomeUser -> UserEventPayload -> Either DomainError SomeUser
-- V1: 登録（初期状態なし → Pending）
applyEvent Nothing (V1 (UserRegistered uid name email)) =
    Right $ SomeUser $ UserP uid (UserProfile name email) (nextVersion initialVersion)
-- V1: 有効化（Pending → Active）
applyEvent (Just (SomeUser (UserP uid profile v))) (V1 (UserActivated _)) =
    Right $ SomeUser $ UserA uid profile (nextVersion v)
-- V2: 凍結（Active → Suspended）
applyEvent (Just (SomeUser (UserA uid profile v))) (V2 (UserSuspended _)) =
    Right $ SomeUser $ UserS uid profile (nextVersion v)
-- V2: 凍結解除（Suspended → Active）
applyEvent (Just (SomeUser (UserS uid profile v))) (V2 (UserUnsuspended _)) =
    Right $ SomeUser $ UserA uid profile (nextVersion v)
-- V2: 無効化（Active または Suspended → Inactive）
applyEvent (Just (SomeUser (UserA uid profile v))) (V2 (UserDeactivated _)) =
    Right $ SomeUser $ UserI uid profile (nextVersion v)
applyEvent (Just (SomeUser (UserS uid profile v))) (V2 (UserDeactivated _)) =
    Right $ SomeUser $ UserI uid profile (nextVersion v)
-- V2: メール訂正（Active または Pending）
applyEvent (Just (SomeUser (UserA uid (UserProfile name _) v))) (V2 (UserEmailCorrected _ email)) =
    Right $ SomeUser $ UserA uid (UserProfile name email) (nextVersion v)
applyEvent (Just (SomeUser (UserP uid (UserProfile name _) v))) (V2 (UserEmailCorrected _ email)) =
    Right $ SomeUser $ UserP uid (UserProfile name email) (nextVersion v)
-- V2: 名前訂正（Active のみ）
applyEvent (Just (SomeUser (UserA uid (UserProfile _ email) v))) (V2 (UserNameCorrected _ name)) =
    Right $ SomeUser $ UserA uid (UserProfile name email) (nextVersion v)
-- その他: 不正遷移
applyEvent _ _ = Left IllegalTransition

{- | イベント列から状態を再構築する (#22)。
純粋関数なので同じイベント列からは常に同じ結果 (#30)。
-}
rehydrate :: [UserEventPayload] -> Either DomainError SomeUser
rehydrate [] = Left IllegalTransition
rehydrate (e : es) = do
    s0 <- applyEvent Nothing e
    foldM (\s ev -> applyEvent (Just s) ev) s0 es
