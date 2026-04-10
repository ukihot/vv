module Main (main) where

import Control.Monad.State
import qualified Data.Map as M
import System.IO (hSetEncoding, stdout, utf8)
import Unsafe.Coerce (unsafeCoerce)

-- アプリケーション層
import Application.User.Boundary.Input.ActivateUserUseCase
import Application.User.Boundary.Output.ActivateUserPort
import Application.User.DTOs.Request.ActivateUserRequest
import Application.User.Interactors.ActivateUserInteractor ()

-- ドメイン層
import Domain.User.Entities.Root (User, UserState (..), getUserId)
import Domain.User.Errors (DomainError (..))
import Domain.User.Repository
import Domain.User.Services.Factory (registerUser)
import Domain.User.ValueObjects.UserId (mkUserId)
import Domain.User.ValueObjects.UserName (mkUserName)
import Domain.User.ValueObjects.Email (mkEmail)

--------------------------------------------------------------------------------
-- 実行用 Mock 実装
--------------------------------------------------------------------------------

data AppState = AppState
  { users :: M.Map String (User 'Pending) 
  , logs  :: [String]
  }

newtype App a = App { unApp :: StateT AppState IO a }
  deriving (Functor, Applicative, Monad, MonadState AppState, MonadIO)

-- Repository 実装
instance UserRepository App where
  loadUser uid = do
    st <- get
    case M.lookup (show uid) (users st) of
      Nothing -> return $ Left (RepositoryError "User not found in Mock DB")
      Just u  -> return $ Right (unsafeCoerce u)
  saveUser _ = return $ Right ()

-- Port 実装
instance ActivateUserPort App where
  presentSuccess u = liftIO $ putStrLn $ "[OK] Activated -> ID: " ++ show (getUserId u)
  presentFailure e = liftIO $ putStrLn $ "[!] Failure   -> " ++ show e

--------------------------------------------------------------------------------
-- メイン処理
--------------------------------------------------------------------------------

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "=== VV System: User Activation Tool ==="

  -- 初期データの生成
  let setup = (,,) <$> mkUserId "user-777" <*> mkUserName "Gemini CEO" <*> mkEmail "ceo@example.com"
  
  case setup of
    Left err -> 
      putStrLn $ "[CRITICAL] Domain Setup Error: " ++ show err
    
    Right (uid, name, email) -> do
      let (user, _) = registerUser uid name email
      let initialState = AppState
            { users = M.fromList [(show uid, user)], logs = [] }

      putStrLn "\n[Task 1] Attempting to activate user-777..."
      _ <- evalStateT (unApp $ execute (ActivateUserRequest "user-777")) initialState

      putStrLn "\n[Task 2] Attempting to activate unknown-user..."
      -- 最後の文を式として評価（代入を外す）
      evalStateT (unApp $ execute (ActivateUserRequest "unknown")) initialState

  putStrLn "\n=== Process Completed ==="