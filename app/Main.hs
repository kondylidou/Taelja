-- The taelja command. It reads a TSTP proof and prints the structured proof
-- as text, TPTP or Lean, or reports whether a problem is in the Horn fragment.
module Main where

import Control.Monad (forM_, when)
import Control.DeepSeq (force)
import Control.Exception (SomeException, evaluate, try)
import System.Environment (getArgs)
import System.Exit (die, exitSuccess)
import System.IO (IOMode (WriteMode), hPutStr, hPutStrLn, hSetEncoding, stderr, stdout, utf8, withFile)

import qualified Data.Text.IO as TIO
import qualified Data.TPTP as T

import ProofTree (buildProofInfo)
import Translate (translate)
import TweeInterface (disableFallback)
import Emitter (emitText)
import TptpEmitter (emitTptp)
import LeanEmitter (emitLean)
import Data.List (isPrefixOf, partition, stripPrefix)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Text as Text
import TptpConvert (parseProof)
import Debug (dumpProofTree, dumpInferenceRules)
import HornProblem (nonHornReason, loadProblem)

-- Checks the flags, then either runs the Horn check or translates the proof
-- and prints it in the chosen format.
main :: IO ()
main = do
  -- Lean output is not ASCII, so write UTF-8 whatever the locale
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  let (flags, files) = partition ("--" `isPrefixOf`) args
      debug = "--debug" `elem` flags
      value key = listToMaybe (mapMaybe (stripPrefix key) flags)
      -- Lean files imported together need distinct namespaces
      lean = emitLean (fromMaybe "" (value "--namespace="))
      render | "--tptp" `elem` flags = emitTptp
             | "--lean" `elem` flags = lean
             | otherwise             = emitText
      -- also write the Lean file here, from the same run
      leanOut = value "--lean-out="
      known f = f `elem` ["--debug", "--tptp", "--lean", "--no-fallback", "--horn-problem"]
                || any (`isPrefixOf` f) ["--namespace=", "--lean-out="]
  inputFile <- case files of
    [f] | all known flags, not (all (`elem` flags) ["--tptp", "--lean"]) -> return f
    _ -> die "Usage: taelja [--debug] [--tptp | --lean] [--namespace=NAME] [--lean-out=FILE] [--no-fallback] <proof-file> | taelja --horn-problem <problem-file>"
  -- --horn-problem only checks whether the problem is Horn as written and
  -- prints "horn" or why the first offending unit is not.
  when ("--horn-problem" `elem` flags) $ do
    units <- loadProblem inputFile >>= either die return
    putStrLn (maybe "horn" ("not horn: " ++) (nonHornReason units))
    exitSuccess
  when ("--no-fallback" `elem` flags) disableFallback
  raw <- TIO.readFile inputFile
  tstp@(T.TSTP _ units) <- either (die . ("Parse error: " ++)) return (parseProof (Text.unpack raw))
  when debug $ case buildProofInfo units of
    Left reason -> hPutStrLn stderr ("No proof tree, " ++ reason)
    Right info  -> do
      hPutStrLn stderr "-- Proof tree"
      dumpProofTree info
      hPutStrLn stderr ""
      hPutStrLn stderr "-- Inference rules"
      dumpInferenceRules units
      hPutStrLn stderr ""
  sp <- translate debug tstp >>= either (die . ("translate: " ++)) return
  -- Force the whole output before printing any of it. Rendering can fail
  -- lazily outside the Horn fragment, and printing as we go could leave a
  -- truncated proof that looks complete.
  r <- try (evaluate (force (render sp, (, lean sp) <$> leanOut)))
  (out, leanFile) <- either (\e -> die ("translate: " ++ show (e :: SomeException))) return r
  forM_ leanFile $ \(path, text) -> withFile path WriteMode (\h -> hSetEncoding h utf8 >> hPutStr h text)
  putStr out
