module Main (main) where

import Adapter.TUI.Brick.App (runBrickApp)
import Application.User.Interactors.ActivateUserInteractor ()
import System.IO (hSetEncoding, stdout, utf8)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  runBrickApp
