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
import qualified Data.Text as Text
import Helpers (extractSzsBlock)
import Debug (dumpProofTree, dumpInferenceRules)

main :: IO ()
main = do
  args <- getArgs
  let flags = filter ((== "--") . take 2) args
      files = filter ((/= "--") . take 2) args
      debug = "--debug" `elem` flags
      mode  | "--strict-only" `elem` flags    = StrictOnly
            | "--heuristic-only" `elem` flags = HeuristicOnly
            | otherwise                       = BothStages
      known = ["--debug", "--strict-only", "--heuristic-only"]
  inputFile <- case files of
    [f] | all (`elem` known) flags -> return f
    _ -> hPutStrLn stderr "Usage: taelja [--debug] [--strict-only | --heuristic-only] <proof-file>" >> exitFailure
  raw <- TIO.readFile inputFile
  let contents = Text.pack (extractSzsBlock (Text.unpack raw))
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err    -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
    Right tstp@(T.TSTP _ units) -> do
      when debug $ do
        case buildProofInfo False units of
          Nothing   -> putStrLn "No refutation proof tree found"
          Just info -> do
            putStrLn "-- Proof tree"
            dumpProofTree info
            putStrLn ""
            putStrLn "-- Inference rules"
            dumpInferenceRules units
            putStrLn ""
      msp <- translateStages mode debug tstp
      case msp of
        Nothing -> exitFailure
        -- The emitted text is forced before any of it is written.  Clause
        -- conversion raises on constructs outside the Horn fragment (reserved
        -- functions, rationals, distinct objects), and those are lazy, so
        -- printing as we go would leave a truncated proof on stdout that a
        -- downstream check could mistake for a complete one.
        Just sp -> do
          r <- try (evaluate (force (emit sp)))
          case r of
            Left e -> do
              hPutStrLn stderr ("translate: " ++ show (e :: SomeException))
              exitFailure
            Right out -> putStr out
