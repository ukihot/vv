{- | ユーザー集約
#3, #4, #15: GADT + DataKinds で不正状態を構造的に排除する。
#5: 遷移関数の型シグネチャが仕様書になる。
#8: User 集約がロール一覧を保持する。集約境界を明確にする。
#22: rehydrate でイベント列から状態を再構築する。
-}
module Domain.IAM.User (
    -- * 集約
    User (..),
    UserState (..),

    -- * ゲッター
    getUserId,
    getUserProfile,
    getUserState,
    getUserVersion,
    getUserRoles,

    -- * 状態遷移
    activateUser,
    suspendUser,
    unsuspendUser,
    deactivateUser,
    assignRole,
    revokeRole,

    -- * 存在型 (#20: 型消去は Application 層のみ)
    SomeUser (..),

    -- * Event Sourcing (#22)
    applyEvent,
    rehydrate,
)
where

import Control.Monad (foldM)
import Data.Text (Text)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
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
-- ロール一覧を各コンストラクタに持たせる (#8)
-- ─────────────────────────────────────────────────────────────────────────────

data User (s :: UserState) where
    UserP :: UserId -> UserProfile -> [RoleId] -> Version -> User 'Pending
    UserA :: UserId -> UserProfile -> [RoleId] -> Version -> User 'Active
    UserS :: UserId -> UserProfile -> [RoleId] -> Version -> User 'Suspended
    UserI :: UserId -> UserProfile -> [RoleId] -> Version -> User 'Inactive

deriving stock instance Show (User s)
deriving stock instance Eq (User s)

-- | 存在型: Application 層でのみ使用する (#20)
data SomeUser where
    SomeUser :: User s -> SomeUser

deriving stock instance Show SomeUser

-- ─────────────────────────────────────────────────────────────────────────────
-- ゲッター
-- ─────────────────────────────────────────────────────────────────────────────

getUserId :: User s -> UserId
getUserId (UserP i _ _ _) = i
getUserId (UserA i _ _ _) = i
getUserId (UserS i _ _ _) = i
getUserId (UserI i _ _ _) = i

getUserProfile :: User s -> UserProfile
getUserProfile (UserP _ p _ _) = p
getUserProfile (UserA _ p _ _) = p
getUserProfile (UserS _ p _ _) = p
getUserProfile (UserI _ p _ _) = p

getUserState :: User s -> UserState
getUserState (UserP {}) = Pending
getUserState (UserA {}) = Active
getUserState (UserS {}) = Suspended
getUserState (UserI {}) = Inactive

getUserRoles :: User s -> [RoleId]
getUserRoles (UserP _ _ rs _) = rs
getUserRoles (UserA _ _ rs _) = rs
getUserRoles (UserS _ _ rs _) = rs
getUserRoles (UserI _ _ rs _) = rs

getUserVersion :: User s -> Version
getUserVersion (UserP _ _ _ v) = v
getUserVersion (UserA _ _ _ v) = v
getUserVersion (UserS _ _ _ v) = v
getUserVersion (UserI _ _ _ v) = v

-- ─────────────────────────────────────────────────────────────────────────────
-- 状態遷移 (#5: 型シグネチャが仕様書)
-- ─────────────────────────────────────────────────────────────────────────────

-- | 承認: Pending → Active
activateUser :: User 'Pending -> (User 'Active, UserEventPayload)
activateUser (UserP uid profile roles v) =
    (UserA uid profile roles (nextVersion v), V1 (UserActivated uid))

-- | 凍結: Active → Suspended
suspendUser :: User 'Active -> (User 'Suspended, UserEventPayload)
suspendUser (UserA uid profile roles v) =
    (UserS uid profile roles (nextVersion v), V2 (UserSuspended uid))

-- | 凍結解除: Suspended → Active
unsuspendUser :: User 'Suspended -> (User 'Active, UserEventPayload)
unsuspendUser (UserS uid profile roles v) =
    (UserA uid profile roles (nextVersion v), V2 (UserUnsuspended uid))

{- | 無効化: Active または Suspended → Inactive (#4)
reason を必須にし、監査証跡として記録する (#40)
-}
deactivateUser :: Text -> User s -> Either DomainError (User 'Inactive, UserEventPayload)
deactivateUser reason user = case user of
    UserA uid profile roles v ->
        Right (UserI uid profile roles (nextVersion v), V2 (UserDeactivated uid reason))
    UserS uid profile roles v ->
        Right (UserI uid profile roles (nextVersion v), V2 (UserDeactivated uid reason))
    _ -> Left IllegalTransition

{- | ロール割り当て: Active のみ (#8)
Active 状態のユーザーにのみロールを割り当てられる。
-}
assignRole :: RoleId -> User 'Active -> (User 'Active, UserEventPayload)
assignRole roleId (UserA uid profile roles v) =
    let roles' = if roleId `elem` roles then roles else roles ++ [roleId]
     in (UserA uid profile roles' (nextVersion v), V2 (UserRoleAssigned uid roleId))

-- | ロール剥奪: Active のみ (#8)
revokeRole :: RoleId -> User 'Active -> (User 'Active, UserEventPayload)
revokeRole roleId (UserA uid profile roles v) =
    let roles' = filter (/= roleId) roles
     in (UserA uid profile roles' (nextVersion v), V2 (UserRoleRevoked uid roleId))

-- ─────────────────────────────────────────────────────────────────────────────
-- Event Sourcing (#22, #30)
-- ─────────────────────────────────────────────────────────────────────────────

applyEvent :: Maybe SomeUser -> UserEventPayload -> Either DomainError SomeUser
-- V1: 登録（初期状態なし → Pending）
applyEvent Nothing (V1 (UserRegistered uid name email)) =
    Right $ SomeUser $ UserP uid (UserProfile name email) [] (nextVersion initialVersion)
-- V1: 有効化（Pending → Active）
applyEvent (Just (SomeUser (UserP uid profile roles v))) (V1 (UserActivated _)) =
    Right $ SomeUser $ UserA uid profile roles (nextVersion v)
-- V2: 凍結（Active → Suspended）
applyEvent (Just (SomeUser (UserA uid profile roles v))) (V2 (UserSuspended _)) =
    Right $ SomeUser $ UserS uid profile roles (nextVersion v)
-- V2: 凍結解除（Suspended → Active）
applyEvent (Just (SomeUser (UserS uid profile roles v))) (V2 (UserUnsuspended _)) =
    Right $ SomeUser $ UserA uid profile roles (nextVersion v)
-- V2: 無効化（Active または Suspended → Inactive）
applyEvent (Just (SomeUser (UserA uid profile roles v))) (V2 (UserDeactivated _ _)) =
    Right $ SomeUser $ UserI uid profile roles (nextVersion v)
applyEvent (Just (SomeUser (UserS uid profile roles v))) (V2 (UserDeactivated _ _)) =
    Right $ SomeUser $ UserI uid profile roles (nextVersion v)
-- V2: メール訂正（Active または Pending）
applyEvent (Just (SomeUser (UserA uid (UserProfile name _) roles v))) (V2 (UserEmailCorrected _ email)) =
    Right $ SomeUser $ UserA uid (UserProfile name email) roles (nextVersion v)
applyEvent (Just (SomeUser (UserP uid (UserProfile name _) roles v))) (V2 (UserEmailCorrected _ email)) =
    Right $ SomeUser $ UserP uid (UserProfile name email) roles (nextVersion v)
-- V2: 名前訂正（Active のみ）
applyEvent (Just (SomeUser (UserA uid (UserProfile _ email) roles v))) (V2 (UserNameCorrected _ name)) =
    Right $ SomeUser $ UserA uid (UserProfile name email) roles (nextVersion v)
-- V2: ロール割り当て（Active のみ）
applyEvent (Just (SomeUser (UserA uid profile roles v))) (V2 (UserRoleAssigned _ roleId)) =
    let roles' = if roleId `elem` roles then roles else roles ++ [roleId]
     in Right $ SomeUser $ UserA uid profile roles' (nextVersion v)
-- V2: ロール剥奪（Active のみ）
applyEvent (Just (SomeUser (UserA uid profile roles v))) (V2 (UserRoleRevoked _ roleId)) =
    Right $ SomeUser $ UserA uid profile (filter (/= roleId) roles) (nextVersion v)
-- その他: 不正遷移
applyEvent _ _ = Left IllegalTransition

rehydrate :: [UserEventPayload] -> Either DomainError SomeUser
rehydrate [] = Left IllegalTransition
rehydrate (e : es) = do
    s0 <- applyEvent Nothing e
    foldM (\s ev -> applyEvent (Just s) ev) s0 es
