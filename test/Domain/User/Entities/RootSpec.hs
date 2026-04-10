module Domain.User.Entities.RootSpec (spec) where

import Data.Either (isLeft)
import Domain.User.Entities.Root
import Domain.User.Events (UserEventPayload (..))
import Domain.User.Services.Factory (registerUser)
import Domain.User.ValueObjects.Email
import Domain.User.ValueObjects.UserId
import Domain.User.ValueObjects.UserName
import Domain.User.ValueObjects.Version
import Test.Hspec

spec :: Spec
spec = describe "User Domain Entity" $ do
  -- テスト用データの準備
  let (Right uid) = mkUserId "user-123"
  let (Right name) = mkUserName "CEO"
  let (Right email) = mkEmail "ceo@example.com"

  describe "registerUser" $ do
    it "新規登録時に Pending 状態で初期バージョン(0)であること" $ do
      let (user, _) = registerUser uid name email
      let (UserP _ _ v) = user
      (v :: Version) `shouldBe` initialVersion

    it "新規登録時に UserRegistered イベントが発行されること" $ do
      let (_, event) = registerUser uid name email
      case event of
        UserRegistered i n e -> do
          i `shouldBe` uid
          n `shouldBe` name
          e `shouldBe` email
        _ -> expectationFailure "Invalid event type"

  describe "activateUser" $ do
    it "Pending から Active に遷移し、バージョンがインクリメントされること" $ do
      let (pendingUser, _) = registerUser uid name email

      -- タプルで受け取る（Root.hs の新しい activateUser と一致させる）
      let (activeUser, event) = activateUser pendingUser

      -- パターンマッチ時に (v :: Version) と書くことで型推論を確定させる
      let (UserA _ _ (v :: Version)) = activeUser
      v `shouldBe` nextVersion initialVersion

      case event of
        UserActivated i -> i `shouldBe` uid
        _ -> expectationFailure "Should emit UserActivated event"

  describe "Validation" $ do
    it "不正なメールアドレスは作成できないこと" $ do
      mkEmail "invalid-email" `shouldSatisfy` isLeft