module Main (main) where

import Adapter.View.Brick.App (runBrickApp)
import System.IO (hSetEncoding, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    runBrickApp
