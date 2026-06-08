module Main where

import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import Test.Tasty
import Test.Tasty.Golden

import Translator (translate)
import Emitter (emit)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Handcrafted"
  [ golden "test_rl_safety"
  , golden "test_eq_symmetry"
  ]

golden :: String -> TestTree
golden name = goldenVsString name
  ("test/expected/" ++ name ++ ".txt")
  (run ("test/" ++ name ++ ".tstp"))

run :: FilePath -> IO LBS.ByteString
run path = do
  contents <- TIO.readFile path
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err   -> fail ("Parse error in " ++ path ++ ": " ++ err)
    Right tstp -> return (LBS.pack (emit (translate tstp)))
