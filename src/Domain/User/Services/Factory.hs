module Domain.User.Services.Factory
    ( registerUser -- createUser から意図の明確な名称へ変更
    ) where

import Domain.User.Entities.Internal.Profile (UserProfile (..))
import Domain.User.Entities.Root (User (UserP), UserState (..))
import Domain.User.Events (UserEventPayload (..))
import Domain.User.ValueObjects.Email (Email)
import Domain.User.ValueObjects.UserId (UserId)
import Domain.User.ValueObjects.UserName (UserName)
import Domain.User.ValueObjects.Version (initialVersion)

-- | ユーザー登録（Factory）
-- 新しい状態(User)と、発生した事実(Event)をペアで返す (#21, #22)
registerUser :: UserId -> UserName -> Email -> (User 'Pending, UserEventPayload)
registerUser uid name email =
    let
        profile = UserProfile name email
        -- Version 0 ではなく初期定義を使用し、知識を結合させない
        user    = UserP uid profile initialVersion
        -- 事実を記録
        event   = UserRegistered uid name email
    in
    (user, event)