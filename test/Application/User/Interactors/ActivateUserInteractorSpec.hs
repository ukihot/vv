module Application.User.Interactors.ActivateUserInteractorSpec (spec) where

import Application.User.Boundary.Input.ActivateUserUseCase
import Application.User.Boundary.Output.ActivateUserPort
import Application.User.DTOs.Request.ActivateUserRequest
import Application.User.Interactors.ActivateUserInteractor ()
import Control.Monad.State
import qualified Data.Map as M
import Domain.User.Entities.Root
import Domain.User.Errors
import Domain.User.Repository
import Domain.User.Services.Factory (registerUser)
import Domain.User.ValueObjects.Email
import Domain.User.ValueObjects.UserId
import Domain.User.ValueObjects.UserName
import Test.Hspec
import Unsafe.Coerce (unsafeCoerce)

-- 1. MockState の定義
data MockState = MockState
  { users :: M.Map UserId (User 'Pending),
    saved :: [User 'Active],
    results :: [Either DomainError (User 'Active)],
    shouldFailSave :: Bool
  }

newtype MockApp a = MockApp {unMockApp :: State MockState a}
  deriving (Functor, Applicative, Monad, MonadState MockState)

-- 2. Repository の Mock 実装
instance UserRepository MockApp where
  loadUser uid = do
    st <- get
    case M.lookup uid (users st) of
      Nothing -> return $ Left InvalidUserId
      Just u -> return $ Right (unsafeCoerce u)

  saveUser user = do
    st <- get
    if shouldFailSave st
      then return $ Left (RepositoryError "Persistence failed")
      else do
        modify $ \s -> s {saved = unsafeCoerce user : saved s}
        return $ Right ()

-- 3. Output Port の Mock 実装
instance ActivateUserPort MockApp where
  presentSuccess u = modify $ \st -> st {results = Right u : results st}
  presentFailure e = modify $ \st -> st {results = Left e : results st}

-- --- テスト本体 ---
spec :: Spec
spec = describe "ActivateUserInteractor" $ do
  -- 共通のセットアップ（IO内で値を生成し、失敗時は expectationFailure を呼ぶ）
  let setup = do
        let eUid = mkUserId "user-123"
        let eName = mkUserName "CEO"
        let eEmail = mkEmail "ceo@example.com"
        case (eUid, eName, eEmail) of
          (Right uid, Right name, Right email) -> do
            let (pendingUser, _) = registerUser uid name email
            return (uid, pendingUser)
          _ -> do
            expectationFailure "Domain object creation failed in setup"
            undefined -- 型を合わせるためのダミー
  describe "正常系" $ do
    it "Pendingユーザーを有効化し、保存と成功通知を行う" $ do
      (uid, pendingUser) <- setup
      let initialState =
            MockState
              { users = M.singleton uid pendingUser,
                saved = [],
                results = [],
                shouldFailSave = False
              }

      let req = ActivateUserRequest "user-123"
      let finalState = execState (unMockApp $ execute req) initialState

      case saved finalState of
        [activeUser] -> do
          results finalState `shouldBe` [Right activeUser]
          getUserId activeUser `shouldBe` uid
        _ -> expectationFailure "Should have saved exactly one active user"

  describe "異常系" $ do
    it "UserId の形式が不正な場合、即座に presentFailure が呼ばれる" $ do
      (uid, pendingUser) <- setup
      let initialState =
            MockState
              { users = M.singleton uid pendingUser,
                saved = [],
                results = [],
                shouldFailSave = False
              }

      let req = ActivateUserRequest ""
      let finalState = execState (unMockApp $ execute req) initialState

      results finalState `shouldBe` [Left InvalidUserId]
      saved finalState `shouldBe` []
    it "ユーザーが存在しない場合、presentFailure が呼ばれる" $ do
      (uid, _) <- setup
      let initialState =
            MockState
              { users = M.empty,
                saved = [],
                results = [],
                shouldFailSave = False
              }

      let req = ActivateUserRequest "user-123"
      let finalState = execState (unMockApp $ execute req) initialState

      results finalState `shouldBe` [Left InvalidUserId]

    it "リポジトリの保存処理でエラーが発生した場合、presentFailure が呼ばれる" $ do
      (uid, pendingUser) <- setup
      let initialState =
            MockState
              { users = M.singleton uid pendingUser,
                saved = [],
                results = [],
                shouldFailSave = True
              }

      let req = ActivateUserRequest "user-123"
      let finalState = execState (unMockApp $ execute req) initialState

      results finalState `shouldBe` [Left (RepositoryError "Persistence failed")]
      saved finalState `shouldBe` []
