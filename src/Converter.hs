module Converter where

import qualified Data.TPTP as T
import Data.List (nub)
import Data.List.NonEmpty (toList)
import Data.Maybe (catMaybes)
import qualified Data.Text as Text

import Types
import Helpers

-- Splits the TSTP unit list into four buckets: axiom entries for output,
-- unit axioms pre-loaded into the working set, non-unit clauses for proof search,
-- and goal literals from the negated conjecture.
-- Handles both E (split_conjunct / CNF) and Vampire (negated_conjecture / FOF).
classifyAxioms :: [T.Unit]
               -> ([Axiom], [UnitEntry], [(String, Clause)], [Literal])
classifyAxioms units =
  let fofAxioms = [ (unitNameToString n, f)
                  | T.Unit n (T.Formula (T.Standard T.Axiom) (T.FOF f)) _ <- units ]
      negConjE  = [ cl
                  | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.CNF cl))
                              (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                  , rule == Text.pack "split_conjunct"
                  , not (isFalsum cl) ]
      negConjV  = [ f
                  | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.FOF f))
                              (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                  , rule == Text.pack "negated_conjecture" ]
      goalLits  = case (negConjE, negConjV) of
                    ([cl], []) -> [negateGoal cl]
                    ([], [f])  -> negateGoalFOF f
                    _          -> error "classifyAxioms: expected exactly one negated conjecture"
      classify (i, (_, f))
        | isPositiveUnitFOF f =
            let lit = extractUnitFOF f
                nm  = "axiom " ++ show i
            in (AUnit nm lit, Just (UnitEntry (Just nm) lit Nothing), Nothing)
        | otherwise =
            let nm = "axiom " ++ show i
                cl = fofToClause f
            in (ANonUnit nm cl, Nothing, Just (nm, freshenClause cl))
      classified             = zipWith (curry classify) [(1::Int)..] fofAxioms
      (axEntries, mUs, mNUs) = unzip3 classified
  in (axEntries, catMaybes mUs, catMaybes mNUs, goalLits)

isPositiveUnitFOF :: T.UnsortedFirstOrder -> Bool
isPositiveUnitFOF (T.Atomic _)                   = True
isPositiveUnitFOF (T.Quantified T.Forall _ body) = isPositiveUnitFOF body
isPositiveUnitFOF _                              = False

extractUnitFOF :: T.UnsortedFirstOrder -> Literal
extractUnitFOF (T.Atomic lit)                 = convertLit lit
extractUnitFOF (T.Quantified T.Forall _ body) = extractUnitFOF body
extractUnitFOF _                              = error "extractUnitFOF: not a positive unit"

fofToClause :: T.UnsortedFirstOrder -> Clause
fofToClause = go
  where
    go (T.Quantified T.Forall _ body)        = go body
    go (T.Connected ante T.Implication cons) =
      Clause { body = collectLits ante, hd = Just (convertLit (atomLit cons)) }
    go _                                     = error "fofToClause: unexpected formula shape"

    collectLits (T.Connected l T.Conjunction r) = collectLits l ++ collectLits r
    collectLits (T.Atomic lit)                  = [convertLit lit]
    collectLits _                               = error "fofToClause: unexpected body shape"

    atomLit (T.Atomic lit) = lit
    atomLit _              = error "fofToClause: head is not atomic"

isFalsum :: T.Clause -> Bool
isFalsum (T.Clause lits) = case toList lits of
  [(_, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])] -> True
  _ -> False

-- The negated conjecture is the negation of the goal, so we negate it back.
negateGoal :: T.Clause -> Literal
negateGoal (T.Clause lits) = case toList lits of
  [(T.Negative, lit)]                       -> convertLit lit
  [(T.Positive, T.Equality l T.Negative r)] -> Eq (convertTerm l) (convertTerm r)
  _ -> error "negateGoal: unexpected negated conjecture shape"

negateGoalFOF :: T.UnsortedFirstOrder -> [Literal]
negateGoalFOF (T.Negated f) = collectConjuncts f
  where
    collectConjuncts (T.Connected l T.Conjunction r) =
      collectConjuncts l ++ collectConjuncts r
    collectConjuncts (T.Atomic lit) = [convertLit lit]
    collectConjuncts _ = error "negateGoalFOF: unexpected conjunct shape"
negateGoalFOF _ = error "negateGoalFOF: unexpected negated conjecture shape"

convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit _                                         = error "convertLit: unsupported literal form"

convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = case args of
  [] -> Const (Text.unpack f)
  _  -> App   (Text.unpack f) (map convertTerm args)
convertTerm _ = error "convertTerm: unsupported term form"

unitNameToString :: T.UnitName -> String
unitNameToString (Left (T.Atom t)) = Text.unpack t
unitNameToString (Right n)         = show n

-- Prefixes every clause variable with "c" so it can never collide with unit
-- variables, which are uppercase-initial per the TPTP standard.
-- tryMatchBodyLit relies on this invariant to split the combined substitution.
freshenClause :: Clause -> Clause
freshenClause (Clause bs mh) =
  let allVs = nub (concatMap litVars bs ++ maybe [] litVars mh)
      sub   = [(v, Var ("c" ++ v)) | v <- allVs]
  in Clause (map (applySubst sub) bs) (fmap (applySubst sub) mh)
