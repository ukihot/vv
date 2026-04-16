{- | ユーザーイベント定義
#12, #27, #28: イベントをバージョン別に分け、スキーマ進化を可能にする。
#23: イベントは業務の事実に対応させる。
-}
module Domain.IAM.User.Events (
    -- * バージョン別ペイロード
    UserEventPayloadV1 (..),
    UserEventPayloadV2 (..),

    -- * 統合ペイロード
    UserEventPayload (..),
)
where

import Data.Text (Text)
import Domain.IAM.Role.ValueObjects.RoleId (RoleId)
import Domain.IAM.User.ValueObjects.Email (Email)
import Domain.IAM.User.ValueObjects.UserId (UserId)
import Domain.IAM.User.ValueObjects.UserName (UserName)

-- | V1: 初期スキーマ（登録・有効化）
data UserEventPayloadV1
    = UserRegistered UserId UserName Email
    | UserActivated UserId
    deriving stock (Show, Eq)

-- | V2: 拡張スキーマ（凍結・解除・無効化・訂正・ロール操作）
data UserEventPayloadV2
    = UserSuspended UserId
    | UserUnsuspended UserId
    | UserDeactivated UserId Text -- #40: reason を監査証跡として記録
    | UserEmailCorrected UserId Email
    | UserNameCorrected UserId UserName
    | UserRoleAssigned UserId RoleId -- #8: User 集約内でロール関連付けを記録
    | UserRoleRevoked UserId RoleId -- #8: User 集約内でロール剥奪を記録
    deriving stock (Show, Eq)

-- | バージョンタグ付き統合ペイロード (#27)
data UserEventPayload
    = V1 UserEventPayloadV1
    | V2 UserEventPayloadV2
    deriving stock (Show, Eq)
