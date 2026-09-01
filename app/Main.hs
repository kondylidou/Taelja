module Main where

import Control.Monad (when)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import qualified Data.Text.IO as TIO
import qualified Data.TPTP as T
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)

import ProofTree (buildProofInfo)
import Translate (translate)
import Emitter (emit)
import qualified Data.Text as Text
import Helpers (extractSzsBlock)
import Debug (dumpProofTree, dumpInferenceRules)

main :: IO ()
main = do
  args <- getArgs
  (debug, inputFile) <- case args of
    ["--debug", f] -> return (True,  f)
    [f]            -> return (False, f)
    _              -> hPutStrLn stderr "Usage: taelja [--debug] <proof-file>" >> exitFailure
  raw <- TIO.readFile inputFile
  let contents = Text.pack (extractSzsBlock (Text.unpack raw))
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err    -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
    Right tstp@(T.TSTP _ units) -> do
      when debug $ do
        case buildProofInfo units of
          Nothing   -> putStrLn "No refutation proof tree found"
          Just info -> do
            putStrLn "-- Proof tree"
            dumpProofTree info
            putStrLn ""
            putStrLn "-- Inference rules"
            dumpInferenceRules units
            putStrLn ""
      msp <- translate debug tstp
      case msp of
        Nothing -> exitFailure
        Just sp -> putStr (emit sp)
