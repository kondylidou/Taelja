module Main where

import Control.Monad (when)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import qualified Data.Text.IO as TIO
import qualified Data.TPTP as T
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)

import ProofTree (buildProofTree)
import Translate (translate, phaseOne)
import Emitter (emit)
import Debug (dumpTSTP, dumpProofTree, dumpPhaseOne)

main :: IO ()
main = do
  args <- getArgs
  (debug, inputFile) <- case args of
    ["--debug", f] -> return (True,  f)
    [f]            -> return (False, f)
    _              -> hPutStrLn stderr "Usage: taelja [--debug] <proof-file>" >> exitFailure
  contents <- TIO.readFile inputFile
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err    -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
    Right tstp@(T.TSTP _ units) -> do
      when debug $ do
        putStrLn "-- TSTP parser output"
        dumpTSTP units

      case buildProofTree units of
        Nothing   -> hPutStrLn stderr "No refutation proof tree found" >> exitFailure
        Just tree -> do
          when debug $ do
            putStrLn "-- Proof tree"
            dumpProofTree tree
            putStrLn ""
            putStrLn "-- Phase 1"
            case phaseOne tree units of
              Nothing              -> putStrLn "No goal found (missing negated conjecture)"
              Just (us, nus, goal) -> dumpPhaseOne us nus goal
            putStrLn ""
          putStr (emit (translate False tstp))
