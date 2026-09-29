-- The conjecture as the format states it.  The fragment is decided on the
-- problem as written, so the conjecture must be a Horn clause: after the
-- universal prefix, hypotheses that are atoms implying a conclusion that is
-- a conjunction of atoms, possibly under existential quantifiers, which the
-- algorithm instantiates, or a negated conjunction of atoms, proved by
-- assuming them and deriving $false.  The hypotheses are unit clauses listed
-- with the axioms.  This is the one formula Tälja reads itself; the axioms
-- are taken as the clauses the prover's clausifier produced.
module Conjecture
  ( Conjecture (..)
  , readConjecture
  , conjectureHypotheses
  , fofConjectures
  , clauseFormula
  ) where
import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Data.List (nub)
import Data.List.NonEmpty (toList)
import Data.Maybe (listToMaybe)
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import Types
import Helpers (dropVarEquations)
import TptpConvert (convertLit)
import HornProblem (HornGoal (..), hornConjecture)
data Conjecture = Conjecture
  { cjHyps    :: [Clause]      -- the antecedent's clauses
  , cjNegated :: [Clause]      -- the clauses of a negated conclusion, assumed too
  , cjGoals   :: [T.Literal] } -- the goal atoms, none for a negated conclusion

readConjecture :: T.UnsortedFirstOrder -> Either String Conjecture
readConjecture f0 = case hornConjecture f of
  Nothing               -> Left ("unsupported conjecture, " ++ show (pretty f0) ++ " is not a Horn clause")
  Just (hs, Derive gs)  -> Right (Conjecture (map unit hs) [] gs)
  Just (hs, Refute as)  -> Right (Conjecture (map unit hs) (map unit as) [])
  where
    f = renameBoundApart f0
    unit l = Clause [] (Just (convertLit l))

freeVars :: T.FirstOrder s -> Set.Set T.Var
freeVars (T.Atomic l)          = Set.fromList (litV l)
  where
    litV (T.Predicate _ ts) = concatMap termV ts
    litV (T.Equality a _ b) = termV a ++ termV b
    termV (T.Variable v)    = [v]
    termV (T.Function _ ts) = concatMap termV ts
    termV _                 = []
freeVars (T.Negated g)         = freeVars g
freeVars (T.Connected l _ r)   = Set.union (freeVars l) (freeVars r)
freeVars (T.Quantified _ vs b) = freeVars b `Set.difference` Set.fromList (map fst (toList vs))

-- Each quantifier that rebinds a variable bound around it gets a fresh name,
-- as the ! [X1] inside LCL684+1.001's ? [X1] does, so the clauses read once
-- the quantifiers are stripped keep the two variables apart.
renameBoundApart :: T.UnsortedFirstOrder -> T.UnsortedFirstOrder
renameBoundApart f0 = snd (go Set.empty (allNames f0) f0)
  where
    go bound used f = case f of
      T.Quantified q vs b ->
        let (used', ren) = foldl fresh (used, Map.empty) [ v | (v, _) <- toList vs, Set.member v bound ]
            vs'          = fmap (\(v, s) -> (Map.findWithDefault v v ren, s)) vs
            (used'', b') = go (Set.union bound (Set.fromList (map fst (toList vs')))) used' (renameFreeVars ren b)
        in (used'', T.Quantified q vs' b')
      T.Negated g -> T.Negated <$> go bound used g
      T.Connected l c r ->
        let (u1, l') = go bound used l
            (u2, r') = go bound u1 r
        in (u2, T.Connected l' c r')
      _ -> (used, f)
    fresh (used, ren) v@(T.Var t) =
      let v' = head [ T.Var (t <> Text.pack ("_" ++ show i)) | i <- [1 :: Int ..]
                    , Set.notMember (T.Var (t <> Text.pack ("_" ++ show i))) used ]
      in (Set.insert v' used, Map.insert v v' ren)
    allNames f = case f of
      T.Quantified _ vs b -> Set.union (Set.fromList (map fst (toList vs))) (allNames b)
      T.Negated g         -> allNames g
      T.Connected l _ r   -> Set.union (allNames l) (allNames r)
      _                   -> freeVars f

-- The free occurrences of variables renamed, as an inner quantifier of the
-- same name binds its own.
renameFreeVars :: Map.Map T.Var T.Var -> T.UnsortedFirstOrder -> T.UnsortedFirstOrder
renameFreeVars ren f | Map.null ren = f
renameFreeVars ren f = case f of
  T.Atomic l -> T.Atomic (renameLit l)
  T.Negated g -> T.Negated (renameFreeVars ren g)
  T.Connected l c r -> T.Connected (renameFreeVars ren l) c (renameFreeVars ren r)
  T.Quantified q vs b ->
    T.Quantified q vs (renameFreeVars (foldr (Map.delete . fst) ren (toList vs)) b)
  where
    renameLit (T.Predicate p ts)  = T.Predicate p (map renameTerm ts)
    renameLit (T.Equality a sg b) = T.Equality (renameTerm a) sg (renameTerm b)
    renameTerm (T.Variable v)    = T.Variable (Map.findWithDefault v v ren)
    renameTerm (T.Function g ts) = T.Function g (map renameTerm ts)
    renameTerm t                 = t

-- The conjecture formulas of the proof.  Twee writes a clausal conjecture as
-- a cnf unit, which is read as the disjunction of its literals.
fofConjectures :: [T.Unit] -> [T.UnsortedFirstOrder]
fofConjectures units = concat
  [ case decl of
      T.Formula (T.Standard T.Conjecture) (T.FOF f)                -> [f]
      T.Formula (T.Standard T.Conjecture) (T.CNF (T.Clause lits)) -> [clauseFormula (toList lits)]
      _                                                            -> []
  | T.Unit _ decl _ <- units ]

clauseFormula :: [(T.Sign, T.Literal)] -> T.UnsortedFirstOrder
clauseFormula ls = foldr1 (\a b -> T.Connected a T.Disjunction b)
  [ if s == T.Positive then T.Atomic l else T.Negated (T.Atomic l) | (s, l) <- ls ]

-- The clauses a conjecture grants as hypotheses, those of the antecedent and
-- those of a negated conclusion, since ~G is proved by assuming G.  Nothing
-- when there is no FOF conjecture.
-- Each clause is granted also with its body equations on a variable dropped,
-- as the prover's clausifier may state it (see dropVarEquations).
conjectureHypotheses :: [T.Unit] -> Maybe ([Clause], [Clause])
conjectureHypotheses units = listToMaybe
  [ (withDropped (cjHyps c), withDropped (cjNegated c)) | Right c <- map readConjecture (fofConjectures units) ]
  where withDropped cs = nub (cs ++ map dropVarEquations cs)
