-- The taelja command. It reads a TSTP proof and prints the structured proof
-- as text, TPTP or Lean, or reports whether a problem is in the Horn fragment.
module Main where

import Control.Monad (when)
import Control.DeepSeq (force)
import Control.Exception (SomeException, evaluate, try)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.IO (IOMode (WriteMode), hPutStr, hPutStrLn, hSetEncoding, stderr, stdout, utf8, withFile)

import qualified Data.Text.IO as TIO
import qualified Data.TPTP as T

import ProofTree (buildProofInfo)
import Translate (translate)
import TweeInterface (disableFallback)
import Emitter (emitText)
import TptpEmitter (emitTptp)
import LeanEmitter (emitLean)
import Data.List (isPrefixOf, stripPrefix)
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
  let flags = filter ((== "--") . take 2) args
      files = filter ((/= "--") . take 2) args
      debug = "--debug" `elem` flags
      -- Lean files imported together need distinct namespaces
      namespace = fromMaybe "" (listToMaybe (mapMaybe (stripPrefix "--namespace=") flags))
      lean = emitLean namespace
      render | "--tptp" `elem` flags = emitTptp
             | "--lean" `elem` flags = lean
             | otherwise             = emitText
      -- also write the Lean file here, from the same run
      leanOut = listToMaybe (mapMaybe (stripPrefix "--lean-out=") flags)
      known = ["--debug", "--tptp", "--lean", "--no-fallback", "--horn-problem"]
      valued = ["--namespace=", "--lean-out="]
      knownFlag f = f `elem` known || any (`isPrefixOf` f) valued
  inputFile <- case files of
    [f] | all knownFlag flags, not (all (`elem` flags) ["--tptp", "--lean"]) -> return f
    _ -> hPutStrLn stderr "Usage: taelja [--debug] [--tptp | --lean] [--namespace=NAME] [--lean-out=FILE] [--no-fallback] <proof-file> | taelja --horn-problem <problem-file>" >> exitFailure
  -- --horn-problem only checks whether the problem is Horn as written and
  -- prints "horn" or why the first offending unit is not.
  when ("--horn-problem" `elem` flags) $ do
    r <- loadProblem inputFile
    case r of
      Left err -> hPutStrLn stderr err >> exitFailure
      Right units -> case nonHornReason units of
        Nothing     -> putStrLn "horn"
        Just reason -> putStrLn ("not horn: " ++ reason)
    exitSuccess
  when ("--no-fallback" `elem` flags) disableFallback
  raw <- TIO.readFile inputFile
  case parseProof (Text.unpack raw) of
    Left err    -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
    Right tstp@(T.TSTP _ units) -> do
      when debug $ do
        case buildProofInfo units of
          Left reason -> hPutStrLn stderr ("No proof tree, " ++ reason)
          Right info  -> do
            hPutStrLn stderr "-- Proof tree"
            dumpProofTree info
            hPutStrLn stderr ""
            hPutStrLn stderr "-- Inference rules"
            dumpInferenceRules units
            hPutStrLn stderr ""
      msp <- translate debug tstp
      case msp of
        Left reason -> do
          hPutStrLn stderr ("translate: " ++ reason)
          exitFailure
        -- Force the whole output before printing any of it. Rendering can
        -- fail lazily outside the Horn fragment, and printing as we go could
        -- leave a truncated proof that looks complete.
        Right sp -> do
          r <- try (evaluate (force (render sp, fmap (const (lean sp)) leanOut)))
          case r of
            Left e -> do
              hPutStrLn stderr ("translate: " ++ show (e :: SomeException))
              exitFailure
            Right (out, leanFile) -> do
              case (leanOut, leanFile) of
                (Just path, Just text) -> withFile path WriteMode (\h -> hSetEncoding h utf8 >> hPutStr h text)
                _                      -> return ()
              putStr out
