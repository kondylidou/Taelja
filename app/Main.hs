module Main where

import Control.Monad (when)
import Data.List (intercalate)
import Data.Maybe (fromMaybe)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import qualified Data.Text as Text
import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import qualified Data.TPTP as T

import Types (Literal, Clause(..))
import Translator (translate, classifyAxioms)
import Emitter (emit)

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
        let (axUnits, axNonUnits, goalLit) = classifyAxioms units
        putStrLn "Setup:"
        putStrLn ""
        putStrLn "units:"
        mapM_ (\(n, l) -> putStrLn ("  " ++ n ++ " : " ++ ppLiteral l)) axUnits
        putStrLn ""
        putStrLn "non-units:"
        if null axNonUnits
          then putStrLn "  (none)"
          else mapM_ (putStrLn . ppNonUnit) axNonUnits
        putStrLn ""
        putStrLn ("goal: " ++ ppLiteral goalLit)
        putStrLn ""
      putStrLn (emit (translate tstp))

ppLiteral :: Literal -> String
ppLiteral = show

ppNonUnit :: (Maybe String, Clause, a) -> String
ppNonUnit (mn, Clause bs hd, _) =
  "  " ++ fromMaybe "?" mn ++ " : "
  ++ intercalate ", " (map ppLiteral bs) ++ " => " ++ maybe "⊥" ppLiteral hd

dumpUnit :: T.Unit -> IO ()
dumpUnit (T.Unit name decl source) = do
  putStr   (unitNameStr name)
  putStr   (" [" ++ roleStr decl ++ "]")
  putStrLn (" <- " ++ annotationStr source)
  putStrLn ("  " ++ declStr decl)
  putStrLn ""
dumpUnit (T.Include path _) =
  putStrLn ("include(" ++ show path ++ ")")

unitNameStr :: T.UnitName -> String
unitNameStr (Left (T.Atom t)) = Text.unpack t
unitNameStr (Right n)         = show n

roleStr :: T.Declaration -> String
roleStr (T.Formula (T.Standard r) _) = show r
roleStr _                            = "?"

annotationStr :: Maybe T.Annotation -> String
annotationStr Nothing             = "input"
annotationStr (Just (src, _info)) = show src

declStr :: T.Declaration -> String
declStr (T.Formula _ f) = show f
declStr d               = show d
