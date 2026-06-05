module Main where

import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult)
import Data.TPTP.Parse.Text (parseTSTP)

import Translator (translate)
import Emitter (emit)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [inputFile] -> do
      contents <- TIO.readFile inputFile
      case eitherResult (parseTSTP contents) of
        Left err    -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
        Right tptp  -> putStrLn (emit (translate tptp))
    _ -> do
      hPutStrLn stderr "Usage: talja <proof-file>"
      exitFailure
