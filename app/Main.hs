module Main where

import Control.Monad (when)
import Control.DeepSeq (force)
import Control.Exception (SomeException, evaluate, try)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import qualified Data.Text.IO as TIO
import qualified Data.TPTP as T
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)

import ProofTree (buildProofInfo)
import Translate (translateStages, StageMode (..))
import Emitter (emit)
import TptpEmitter (emitTptp)
import qualified Data.Text as Text
import Helpers (extractSzsBlock)
import Debug (dumpProofTree, dumpInferenceRules)

main :: IO ()
main = do
  args <- getArgs
  let flags = filter ((== "--") . take 2) args
      files = filter ((/= "--") . take 2) args
      debug = "--debug" `elem` flags
      render = if "--tptp" `elem` flags then emitTptp else emit
      mode  | "--strict-only" `elem` flags    = StrictOnly
            | "--heuristic-only" `elem` flags = HeuristicOnly
            | otherwise                       = BothStages
      known = ["--debug", "--tptp", "--strict-only", "--heuristic-only"]
  inputFile <- case files of
    [f] | all (`elem` known) flags -> return f
    _ -> hPutStrLn stderr "Usage: taelja [--debug] [--tptp] [--strict-only | --heuristic-only] <proof-file>" >> exitFailure
  raw <- TIO.readFile inputFile
  let contents = Text.pack (extractSzsBlock (Text.unpack raw))
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err    -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
    Right tstp@(T.TSTP _ units) -> do
      when debug $ do
        case buildProofInfo False units of
          Left reason -> putStrLn ("No proof tree, " ++ reason)
          Right info  -> do
            putStrLn "-- Proof tree"
            dumpProofTree info
            putStrLn ""
            putStrLn "-- Inference rules"
            dumpInferenceRules units
            putStrLn ""
      msp <- translateStages mode debug tstp
      case msp of
        Nothing -> exitFailure
        -- Force the whole output before printing any of it.  Clause conversion
        -- fails lazily on constructs outside the Horn fragment, so printing as
        -- we go could leave a truncated proof that looks complete.
        Just sp -> do
          r <- try (evaluate (force (render sp)))
          case r of
            Left e -> do
              hPutStrLn stderr ("translate: " ++ show (e :: SomeException))
              exitFailure
            Right out -> putStr out
