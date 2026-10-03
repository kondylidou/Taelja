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
import Data.Maybe (isJust)
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import System.Directory (doesFileExist)
import System.Environment (lookupEnv)
import System.FilePath (takeDirectory, (</>))

import Conjecture (readConjecture)
import TptpConvert (convertFOFToClause, eraseSorts, isHornLiterals, parseTptp, usesDistinctObjects)

-- The units of a problem file, sorts erased and includes spliced in. An
-- include is looked up under the TPTP root, the directory above Problems,
-- and then under $TPTP.
loadProblem :: FilePath -> IO (Either String [T.Unit])
loadProblem file = do
  env <- lookupEnv "TPTP"
  let root = takeDirectory (takeDirectory (takeDirectory file))
  go root env file
  where
    go root env f = do
      raw <- TIO.readFile f
      case parseTptp raw of
        Left err -> return (Left ("parse error in " ++ f ++ ": " ++ err))
        Right (T.TSTP szs units) -> do
          let T.TSTP _ units' = eraseSorts (T.TSTP szs units)
          rs <- mapM (expand root env) units'
          return (concat <$> sequence rs)
    expand root env (T.Include (T.Atom path) only) = do
      let p = Text.unpack path
      candidates <- filterM doesFileExist ((root </> p) : [ e </> p | Just e <- [env] ])
      case candidates of
        (c : _) -> do
          r <- go root env c
          return (fmap (filter (wanted only)) r)
        [] -> return (Left ("include not found: " ++ p))
    expand _ _ u = return (Right [u])
    wanted Nothing _ = True
    wanted (Just names) (T.Unit n _ _) = n `elem` toList names
    wanted _ _ = True

-- Nothing when the problem is Horn as written, else the offending unit and
-- why. Distinct objects are rejected too, since their inequality is a theory
-- fact that the calculus does not derive.
nonHornReason :: [T.Unit] -> Maybe String
nonHornReason units = case [ r | u <- units, Just r <- [theory u, offending u] ] of
  []      -> Nothing
  (r : _) -> Just r
  where
    theory (T.Unit n d _)
      | usesDistinctObjects d = Just (name n ++ ": uses distinct objects, a theory fact outside the calculus")
    theory _ = Nothing
    hasConjecture = not (null [ () | T.Unit _ (T.Formula (T.Standard T.Conjecture) _) _ <- units ])
    offending (T.Unit n (T.Formula (T.Standard T.Conjecture) form) _) = case form of
      T.FOF f | isRight (readConjecture f) -> Nothing
              | otherwise      -> Just (name n ++ ": conjecture " ++ render f ++ " is not a Horn clause")
      T.CNF c | clauseOk c -> Nothing
              | otherwise  -> Just (name n ++ ": conjecture clause is not Horn")
      _ -> Just (name n ++ ": conjecture in an unsupported form")
    -- A problem with a conjecture is judged by it. Otherwise the negated
    -- conjecture comes as clauses, which a proof may print as fof units.
    offending (T.Unit n (T.Formula (T.Standard T.NegatedConjecture) form) _)
      | hasConjecture = Nothing
      | otherwise = case form of
          T.CNF c | clauseOk c -> Nothing
          T.FOF g | isJust (convertFOFToClause g) -> Nothing
          _ -> Just (name n ++ ": a negated conjecture that is no Horn clause")
    offending (T.Unit n (T.Formula _ form) _) = case form of
      T.FOF f | isJust (convertFOFToClause f) -> Nothing
              | otherwise  -> Just (name n ++ ": " ++ render f ++ " is not a Horn clause")
      T.CNF c | clauseOk c -> Nothing
              | otherwise  -> Just (name n ++ ": clause is not Horn")
      _ -> Just (name n ++ ": formula in an unsupported form")
    offending _ = Nothing
    name = show . pretty
    render = show . pretty
    clauseOk (T.Clause lits) = isHornLiterals (toList lits)
