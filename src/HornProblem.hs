-- Loads a TPTP problem and decides whether it is Horn as written. Each axiom
-- must state one Horn clause, and the conjecture one whose goal is a possibly
-- existential conjunction of atoms or its negation.
module HornProblem (nonHornReason, loadProblem) where

import Control.Monad (filterM)
import qualified Data.TPTP as T
import qualified Data.Text as Text
import qualified Data.Text.IO as TIO
import Data.List.NonEmpty (toList)
import Data.Either (isRight)
import Data.Maybe (isJust, listToMaybe, maybeToList)
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import System.Directory (doesFileExist)
import System.Environment (lookupEnv)
import System.FilePath (takeDirectory, (</>))

import Conjecture (readConjecture)
import TptpConvert (convertFOFToClause, eraseSorts, isConjectureDecl, isHornLiterals, parseTptp, usesDistinctObjects)

-- The units of a problem file, sorts erased and includes spliced in. An
-- include is looked up under the TPTP root, the directory above Problems,
-- and then under $TPTP.
loadProblem :: FilePath -> IO (Either String [T.Unit])
loadProblem file = do
  env <- lookupEnv "TPTP"
  go (takeDirectory (takeDirectory (takeDirectory file)) : maybeToList env) file
  where
    go dirs f = do
      raw <- TIO.readFile f
      case parseTptp raw of
        Left err -> return (Left ("parse error in " ++ f ++ ": " ++ err))
        Right tstp -> do
          let T.TSTP _ units = eraseSorts tstp
          rs <- mapM (expand dirs) units
          return (concat <$> sequence rs)
    expand dirs (T.Include (T.Atom path) only) = do
      let p = Text.unpack path
      found <- filterM doesFileExist [ d </> p | d <- dirs ]
      case found of
        (c : _) -> fmap (filter (wanted only)) <$> go dirs c
        []      -> return (Left ("include not found: " ++ p))
    expand _ u = return (Right [u])
    wanted (Just names) (T.Unit n _ _) = n `elem` toList names
    wanted _ _ = True

-- Nothing when the problem is Horn as written, else the offending unit and
-- why. Distinct objects are rejected too, since their inequality is a theory
-- fact that the calculus does not derive.
nonHornReason :: [T.Unit] -> Maybe String
nonHornReason units = listToMaybe
  [ render n ++ ": " ++ r | T.Unit n d _ <- units, Just r <- [theory d, offending d] ]
  where
    theory d
      | usesDistinctObjects d = Just "uses distinct objects, a theory fact outside the calculus"
      | otherwise = Nothing
    hasConjecture = or [ isConjectureDecl d | T.Unit _ d _ <- units ]
    offending (T.Formula (T.Standard T.Conjecture) form) = case form of
      T.FOF f | isRight (readConjecture f) -> Nothing
              | otherwise -> Just ("conjecture " ++ render f ++ " is not a Horn clause")
      T.CNF c | clauseOk c -> Nothing
              | otherwise  -> Just "conjecture clause is not Horn"
      _ -> Just "conjecture in an unsupported form"
    -- A problem with a conjecture is judged by it. Otherwise the negated
    -- conjecture comes as clauses, which a proof may print as fof units.
    offending (T.Formula (T.Standard T.NegatedConjecture) form)
      | hasConjecture = Nothing
      | otherwise = case form of
          T.CNF c | clauseOk c -> Nothing
          T.FOF g | isJust (convertFOFToClause g) -> Nothing
          _ -> Just "a negated conjecture that is no Horn clause"
    offending (T.Formula _ form) = case form of
      T.FOF f | isJust (convertFOFToClause f) -> Nothing
              | otherwise -> Just (render f ++ " is not a Horn clause")
      T.CNF c | clauseOk c -> Nothing
              | otherwise  -> Just "clause is not Horn"
      _ -> Just "formula in an unsupported form"
    offending _ = Nothing
    render x = show (pretty x)
    clauseOk (T.Clause lits) = isHornLiterals (toList lits)
