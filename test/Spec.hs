module Main (main) where

import App.IAM.Spec qualified as AppIAM
import Domain.Accounting.Spec qualified as Accounting
import Domain.IAM.Spec qualified as IAM
import Domain.IFRS.Spec qualified as IFRS
import Domain.Shared.SharedSpec qualified as Shared
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import System.IO (hSetEncoding, stderr, stdout)
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main = do
    setLocaleEncoding utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    defaultMain $
        testGroup
            "vv"
            [ Shared.tests
            , IAM.tests
            , AppIAM.tests
            , Accounting.tests
            , IFRS.tests
            ]
