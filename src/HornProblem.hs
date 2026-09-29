-- Whether a problem is Horn as written, before any clausification.  Every
-- formula but the conjecture must be a Horn clause as stated: a universally
-- closed A1 & ... & An => B, an atom, a disjunction with at most one positive
-- literal, or a negated conjunction.  The conjecture must be a Horn clause
-- whose hypotheses are atoms and whose conclusion is an atom, a conjunction
-- of atoms, or one under an existential quantifier, which the algorithm
-- instantiates.  In the lenient reading a formula may also be a conjunction
-- of Horn clauses, and an implication may conclude a conjunction, one clause
-- per conjunct.
module HornProblem (HornGoal (..), hornConjecture, hornProblem, loadProblem) where

import qualified Data.TPTP as T
import qualified Data.Text as Text
import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.List.NonEmpty (toList)
import Data.Maybe (isJust)
import Data.TPTP.Parse.Text (parseTSTP)
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import System.Directory (doesFileExist)
import System.Environment (lookupEnv)
import System.FilePath (takeDirectory, (</>))

import TptpConvert (collectDisjuncts, convertFOFToClause, eraseSorts, isReservedTLit)

-- The units of a problem file with its includes spliced in.  An include is
-- relative to the TPTP root, the directory above Problems, or to $TPTP.
loadProblem :: FilePath -> IO (Either String [T.Unit])
loadProblem file = do
  env <- lookupEnv "TPTP"
  let root = takeDirectory (takeDirectory (takeDirectory file))
  go root env file
  where
    go root env f = do
      raw <- TIO.readFile f
      case eitherResult (feed (parseTSTP raw) mempty) of
        Left err -> return (Left ("parse error in " ++ f ++ ": " ++ err))
        Right (T.TSTP szs units) -> do
          let T.TSTP _ units' = eraseSorts (T.TSTP szs units)
          rs <- mapM (expand root env) units'
          return (concat <$> sequence rs)
    expand root env (T.Include (T.Atom path) only) = do
      let p = Text.unpack path
      candidates <- filterM' doesFileExist ([root </> p] ++ [ e </> p | Just e <- [env] ])
      case candidates of
        (c : _) -> do
          r <- go root env c
          return (fmap (filter (wanted only)) r)
        [] -> return (Left ("include not found: " ++ p))
    expand _ _ u = return (Right [u])
    wanted Nothing _ = True
    wanted (Just names) (T.Unit n _ _) = n `elem` toList names
    wanted _ _ = True
    filterM' _ [] = return []
    filterM' p (x : xs) = do
      ok <- p x
      rest <- filterM' p xs
      return (if ok then x : rest else rest)

-- Nothing when the problem is Horn as written, else the unit and the reason.
hornProblem :: Bool -> [T.Unit] -> Maybe String
hornProblem lenient units = case [ r | u <- units, Just r <- [offending u] ] of
  []      -> Nothing
  (r : _) -> Just r
  where
    hasConjecture = not (null [ () | T.Unit _ (T.Formula (T.Standard T.Conjecture) _) _ <- units ])
    offending (T.Unit n (T.Formula (T.Standard T.Conjecture) form) _) = case form of
      T.FOF f | conjectureOk f -> Nothing
              | otherwise      -> Just (name n ++ ": conjecture " ++ render f ++ " is not a Horn clause")
      T.CNF c | clauseOk c -> Nothing
              | otherwise  -> Just (name n ++ ": conjecture clause is not Horn")
      _ -> Just (name n ++ ": conjecture in an unsupported form")
    -- a problem with a conjecture formula is judged by it, and a CNF problem
    -- states its negated conjecture as clauses, which a proof may print as
    -- fof units
    offending (T.Unit n (T.Formula (T.Standard T.NegatedConjecture) form) _)
      | hasConjecture = Nothing
      | otherwise = case form of
          T.CNF c | clauseOk c -> Nothing
          T.FOF g | isJust (convertFOFToClause g) -> Nothing
          _ -> Just (name n ++ ": a negated conjecture that is no Horn clause")
    offending (T.Unit n (T.Formula _ form) _) = case form of
      T.FOF f | axiomOk f  -> Nothing
              | otherwise  -> Just (name n ++ ": " ++ render f ++ " is not a Horn clause")
      T.CNF c | clauseOk c -> Nothing
              | otherwise  -> Just (name n ++ ": clause is not Horn")
      _ -> Just (name n ++ ": formula in an unsupported form")
    offending _ = Nothing
    name = show . pretty
    render = show . pretty
    clauseOk (T.Clause lits) = length [ () | (T.Positive, l) <- toList lits, not (isReservedTLit l), not (negEq l) ] <= 1
    negEq (T.Equality _ T.Negative _) = True
    negEq _                           = False
    -- an axiom, read as one clause, or leniently as clauses
    axiomOk f
      | lenient   = clausesOk (stripForall f)
      | otherwise = isJust (convertFOFToClause f)
    clausesOk g = case g of
      T.Connected l T.Conjunction r -> clausesOk l && clausesOk r
      T.Connected body T.Implication hd
        | cs@(_ : _ : _) <- conjuncts (stripForall hd) -> all (\c -> isJust (convertFOFToClause (T.Connected body T.Implication c))) cs
      T.Quantified T.Forall _ b -> clausesOk b
      _ -> isJust (convertFOFToClause g)
    conjectureOk f = isJust (hornConjecture f)
    conjuncts g = case g of
      T.Connected l T.Conjunction r -> conjuncts l ++ conjuncts r
      _                             -> [g]

-- The goal of a Horn-clause conjecture: atoms to derive, or, for a
-- conclusion ~(A1 & ... & An), atoms to assume and refute.
data HornGoal = Derive [T.Literal] | Refute [T.Literal]

-- A conjecture that is a Horn clause as written, read as its hypotheses,
-- atoms, and its goal.  After the universal prefix it is H => C with H a
-- conjunction of atoms, or C alone, where C is a conjunction of atoms, one
-- under existential quantifiers, which the algorithm instantiates, or a
-- negated conjunction of atoms; or it is written as a disjunction with at
-- most one positive literal.  Nothing for any other shape.
hornConjecture :: T.UnsortedFirstOrder -> Maybe ([T.Literal], HornGoal)
hornConjecture f = case stripForall f of
  T.Connected h T.Implication c -> (,) <$> atoms h <*> conclusion c
  g@(T.Connected _ T.Disjunction _) -> do
    pairs <- collectDisjuncts g
    let hs = [ l | (T.Negative, l) <- pairs ]
    case [ l | (T.Positive, l) <- pairs ] of
      [l] -> Just (hs, Derive [l])
      []  -> Just ([], Refute hs)
      _   -> Nothing
  g -> (,) [] <$> conclusion g
  where
    conclusion g = case g of
      T.Quantified _ _ b -> conclusion b
      T.Negated b        -> Refute <$> atoms b
      _                  -> Derive <$> atoms g
    atoms g = case g of
      T.Connected l T.Conjunction r -> (++) <$> atoms l <*> atoms r
      T.Atomic l@(T.Equality _ T.Positive _) -> Just [l]
      T.Atomic l@(T.Predicate (T.Defined _) _) -> Just [l]
      _ -> Nothing

stripForall :: T.UnsortedFirstOrder -> T.UnsortedFirstOrder
stripForall (T.Quantified T.Forall _ b) = stripForall b
stripForall g                           = g
