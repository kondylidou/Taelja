module Main where

import Control.Monad (when)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import qualified Data.TPTP as T

import Types (Axiom(..), Clause(..))
import Translator (translate)
import Converter (classifyAxioms)
import Emitter (emit, ppClause)
import qualified Emitter as E
import ProofTree (unitNameStr)

main :: IO ()
main = do
  args <- getArgs
  (debug, inputFile) <- case args of
    ["--debug", f] -> return (True,  f)
    [f]            -> return (False, f)
    _              -> hPutStrLn stderr "Usage: taelja [--debug] <proof-file>" >> exitFailure
  contents <- TIO.readFile inputFile
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err              -> hPutStrLn stderr ("Parse error: " ++ err) >> exitFailure
    Right tstp@(T.TSTP _ units) -> do
      when debug $ do
        putStrLn ("Parsed " ++ show (length units) ++ " units\n")
        mapM_ dumpUnit units
        let (axEntries, _initUnits, axNonUnits, goalLits) = classifyAxioms units
        putStrLn "Setup:"
        putStrLn ""
        putStrLn "axioms:"
        mapM_ (putStrLn . ("  " ++) . ppEntry) axEntries
        putStrLn ""
        putStrLn "non-units:"
        if null axNonUnits
          then putStrLn "  (none)"
          else mapM_ (putStrLn . ppNonUnit) axNonUnits
        putStrLn ""
        mapM_ (\g -> putStrLn ("goal: " ++ E.ppLiteral g)) goalLits
        putStrLn ""
      putStr (emit (translate debug tstp))

ppEntry :: Axiom -> String
ppEntry (AUnit n l)    = n ++ " : " ++ E.ppLiteral l
ppEntry (ANonUnit n c) = n ++ " : " ++ ppClause c

ppNonUnit :: (String, Clause) -> String
ppNonUnit (n, c) = "  " ++ n ++ " : " ++ ppClause c

dumpUnit :: T.Unit -> IO ()
dumpUnit (T.Unit name decl source) = do
  putStr   (unitNameStr name)
  putStr   (" [" ++ roleStr decl ++ "]")
  putStrLn (" <- " ++ annotationStr source)
  putStrLn ("  " ++ declStr decl)
  putStrLn ""
dumpUnit (T.Include path _) =
  putStrLn ("include(" ++ show path ++ ")")

roleStr :: T.Declaration -> String
roleStr (T.Formula (T.Standard r) _) = show r
roleStr _                            = "?"

annotationStr :: Maybe T.Annotation -> String
annotationStr Nothing             = "input"
annotationStr (Just (src, _info)) = show src

declStr :: T.Declaration -> String
declStr (T.Formula _ f) = show f
declStr d               = show d
