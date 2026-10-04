-- Reads the conjecture as the problem states it, the one formula Taelja does
-- not take from the prover's clausifier. It must be a Horn clause whose goal
-- is a conjunction of atoms or its negation. The module also reads goal atoms
-- and puts back a negated conjecture that E simplified away.
module Conjecture
  ( Conjecture (..)
  , readConjecture
  , expandSimplifiedConjecture
  , conjectureHypotheses
  , conjectureFormulas
  , clauseFormula
  , extractGoalLits
  , unfoldDefinition
  , extractConjectureGoals
  , concludesNegation
  ) where

import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe, listToMaybe)
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)

import Types
import TptpConvert (clauseToDecl, collectDisjuncts, convertLit, resolutionSource, stripForall, tptpLitVars, unitNameOf, unitNameStr)

-- A Horn conjecture as the unit clauses a proof may assume and the goal atoms.
data Conjecture = Conjecture
  { cjHyps    :: [Clause]      -- the hypotheses, as unit clauses
  , cjNegated :: [Clause]      -- the atoms of a negated conclusion, also assumed
  , cjGoals   :: [T.Literal] } -- the goal atoms, empty for a negated conclusion

-- The goal of a Horn conjecture, atoms to derive or, for a conclusion
-- ~(A1 & ... & An), atoms to assume and refute.
data HornGoal = Derive [T.Literal] | Refute [T.Literal]

-- A conjecture that is a Horn clause as written, split into hypothesis atoms
-- and goal. After the universal prefix it is H => C, C alone, or a disjunction
-- with at most one positive literal. H is a conjunction of atoms, and C is one
-- too, possibly quantified, or its negation.
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
      -- a disequality s != t is the negated atom ~(s = t)
      T.Atomic (T.Equality l T.Negative r) -> Just (Refute [T.Equality l T.Positive r])
      _                  -> Derive <$> atoms g
    atoms g = case g of
      T.Connected l T.Conjunction r -> (++) <$> atoms l <*> atoms r
      T.Atomic l@(T.Equality _ T.Positive _) -> Just [l]
      T.Atomic l@(T.Predicate (T.Defined _) _) -> Just [l]
      _ -> Nothing

-- Reads a conjecture formula, its bound variables renamed apart, or says why it
-- is not a Horn clause.
readConjecture :: T.UnsortedFirstOrder -> Either String Conjecture
readConjecture f0 = case hornConjecture f of
  Nothing               -> Left ("unsupported conjecture, " ++ show (pretty f0) ++ " is not a Horn clause")
  Just (hs, Derive gs)  -> Right (Conjecture (map unit hs) [] gs)
  Just (hs, Refute as)  -> Right (Conjecture (map unit hs) (map unit as) [])
  where
    f = renameBoundApart f0
    unit l = Clause [] (Just (convertLit l))

-- E simplifies a negated conjecture whose conclusion is among its hypotheses,
-- as ~(p(z) => p(z)) on SYN973+1, straight to ~$true, leaving no inference to
-- read. This puts back the clausified negation and resolves each goal atom
-- with its hypothesis, deriving $false under the simplified unit's name.
expandSimplifiedConjecture :: [T.Unit] -> [T.Unit]
expandSimplifiedConjecture units = go Set.empty units
  where
    conjecture = listToMaybe
      [ (n, f) | T.Unit n (T.Formula (T.Standard T.Conjecture) (T.FOF f)) _ <- units ]
    go _ [] = []
    go rewritten (u@(T.Unit n d (Just (src, _))) : rest)
      | T.Inference (T.Atom rule) _ _ <- src
      , rule == Text.pack "fof_simplification"
      , isNegatedTruth d
      , Just (cn, f) <- conjecture
      , Right c <- readConjecture f
      , gs@(_ : _) <- map convertLit (cjGoals c)
      , all (\g -> Clause [] (Just g) `elem` cjHyps c) gs
      = expansion n cn gs ++ go (Set.insert (unitNameStr n) rewritten) rest
      -- units that only copy the simplified one, like E's fof_nnf and cn
      -- steps, are dropped, since the resolutions already derive $false
      | isTruthConstant d
      , T.Inference _ _ ps <- src
      , names@(_ : _) <- [ unitNameStr pn | T.Parent (T.UnitSource pn) _ <- ps ]
      , all (`Set.member` rewritten) names
      = go (Set.insert (unitNameStr n) rewritten) rest
      | otherwise = u : go rewritten rest
    go rewritten (u : rest) = u : go rewritten rest
    expansion n cn gs =
      [ assumed (hypName i) (Clause [] (Just g)) | (i, g) <- zip [1 :: Int ..] gs ]
      ++ [ assumed goalName (Clause gs Nothing) ]
      ++ [ T.Unit (if i == length gs then n else unitNameOf (resName i)) (clauseToDecl (Clause (drop i gs) Nothing))
                  (Just (resolutionSource [T.Status (T.Standard T.THM)]
                           (if i == 1 then goalName else resName (i - 1)) (hypName i), Nothing))
         | i <- [1 .. length gs] ]
      where
        base = unitNameStr n
        hypName i = base ++ "_h" ++ show i
        resName i = base ++ "_r" ++ show i
        goalName  = base ++ "_g"
        -- a clause of the negated conjecture, assumed from the conjecture
        assumed nm c = T.Unit (unitNameOf nm) (negConj (clauseToDecl c)) (Just (negation, Nothing))
        negation  = T.Inference (T.Atom (Text.pack "assume_negation"))
                                [T.Status (T.Standard T.CTH)] [T.Parent (T.UnitSource cn) []]
        negConj (T.Formula _ e) = T.Formula (T.Standard T.NegatedConjecture) e
        negConj e               = e
    isNegatedTruth (T.Formula _ (T.FOF (T.Negated (T.Atomic (T.Predicate (T.Reserved (T.Standard T.Tautology)) []))))) = True
    isNegatedTruth _ = False
    isTruthConstant d = isNegatedTruth d || case d of
      T.Formula _ (T.CNF (T.Clause lits)) ->
        toList lits == [(T.Positive, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])]
      T.Formula _ (T.FOF (T.Atomic (T.Predicate (T.Reserved (T.Standard T.Falsum)) []))) -> True
      _ -> False

-- Renames each quantified variable that shadows an outer one, as ! [X1]
-- inside ? [X1] on LCL684+1.001, so the two stay apart once the quantifiers
-- are stripped.
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
      let v' = head (filter (`Set.notMember` used) [ T.Var (t <> Text.pack ('_' : show i)) | i <- [1 :: Int ..] ])
      in (Set.insert v' used, Map.insert v v' ren)
    -- every variable the formula names, bound or free
    allNames f = case f of
      T.Quantified _ vs b -> Set.union (Set.fromList (map fst (toList vs))) (allNames b)
      T.Negated g         -> allNames g
      T.Connected l _ r   -> Set.union (allNames l) (allNames r)
      T.Atomic l          -> Set.fromList (tptpLitVars l)

-- Renames free occurrences only. An inner quantifier of the same name keeps
-- its own variable.
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

-- The conjecture formulas of the proof. Twee writes a clausal conjecture as a
-- cnf unit, read here as the disjunction of its literals.
conjectureFormulas :: [T.Unit] -> [T.UnsortedFirstOrder]
conjectureFormulas units = concat
  [ case decl of
      T.Formula (T.Standard T.Conjecture) (T.FOF f)                -> [f]
      T.Formula (T.Standard T.Conjecture) (T.CNF (T.Clause lits)) -> [clauseFormula (toList lits)]
      _                                                            -> []
  | T.Unit _ decl _ <- units ]

-- A clause's signed literals as their disjunction.
clauseFormula :: [(T.Sign, T.Literal)] -> T.UnsortedFirstOrder
clauseFormula ls = foldr1 (`T.Connected` T.Disjunction)
  [ if s == T.Positive then T.Atomic l else T.Negated (T.Atomic l) | (s, l) <- ls ]

-- The clauses the conjecture lets a proof assume, its hypotheses and the atoms
-- of a negated conclusion, since ~G is proved by assuming G. Nothing when no
-- conjecture can be read.
conjectureHypotheses :: [T.Unit] -> Maybe ([Clause], [Clause])
conjectureHypotheses units = listToMaybe
  [ (cjHyps c, cjNegated c) | Right c <- map readConjecture (conjectureFormulas units) ]

-- The goal atoms a clause or formula states. A goal clause is all negative,
-- where a disequality counts as a negative equation, so s != t | ~p(s) states
-- the goals s = t and p(s).
extractGoalLits :: T.Declaration -> Maybe [T.Literal]
extractGoalLits (T.Formula _ (T.CNF (T.Clause lits))) = mapM goalOf (toList lits)
  where
    goalOf (T.Negative, lit)                       = Just lit
    goalOf (T.Positive, T.Equality l T.Negative r) = Just (T.Equality l T.Positive r)
    goalOf _                                       = Nothing
extractGoalLits (T.Formula _ (T.FOF f)) = extractFOF f
  where
    extractFOF (T.Quantified T.Forall _ body) = extractFOF body
    extractFOF (T.Negated body)               = conjuncts body
    -- Only an all-negative disjunction states goals. One with a positive
    -- literal is a hypothesis, even when Vampire labels it negated_conjecture.
    -- posLitsOfDisjFOF is not used, as it counts a disequality as positive.
    extractFOF g = case disjuncts g of
      ls@(_ : _) | not (any fst ls) -> Just (map snd ls)
      _                             -> Nothing
    -- the literals of a disjunction, each with whether it is positive
    disjuncts (T.Atomic (T.Equality l T.Negative r)) = [(False, T.Equality l T.Positive r)]
    disjuncts (T.Atomic lit)                         = [(True, lit)]
    disjuncts (T.Negated (T.Atomic lit))             = [(False, lit)]
    disjuncts (T.Connected l T.Disjunction r)        = disjuncts l ++ disjuncts r
    disjuncts _                                      = []
    conjuncts (T.Atomic lit)                  = Just [lit]
    conjuncts (T.Connected l T.Conjunction r) = (++) <$> conjuncts l <*> conjuncts r
    conjuncts _                               = Nothing
extractGoalLits _ = Nothing

-- A nullary goal atom the prover introduced, like epred in E's
-- "~epred <=> ! [X] ~E(f(X),0)", stands for the atoms it abbreviates. Other
-- atoms, and those not defined by a conjunction of atoms, are kept as they are.
unfoldDefinition :: Map.Map String T.Unit -> T.Literal -> [T.Literal]
unfoldDefinition unitMap lit@(T.Predicate (T.Defined (T.Atom pname)) []) = fromMaybe [lit] $ listToMaybe
  [ body | T.Unit _ (T.Formula _ (T.FOF f)) (Just (T.Introduced _ _, _)) <- Map.elems unitMap
         , Just body <- [definitionBody f] ]
  where
    isAtom (T.Atomic (T.Predicate (T.Defined (T.Atom n)) [])) = n == pname
    isAtom _ = False
    -- the atoms of phi in "p <=> phi" or "~p <=> ~phi", quantifiers stripped
    definitionBody (T.Connected l T.Equivalence r)
      | isAtom l = atomsOf r
      | isAtom r = atomsOf l
      | T.Negated l' <- l, isAtom l' = atomsOf (negatedOf r)
      | T.Negated r' <- r, isAtom r' = atomsOf (negatedOf l)
    definitionBody (T.Quantified _ _ body) = definitionBody body
    definitionBody _ = Nothing
    -- the negation pushed inward, so ~(~a | ~b) is the conjunction a & b
    negatedOf (T.Quantified q vs body)        = T.Quantified q vs (negatedOf body)
    negatedOf (T.Negated body)                = body
    negatedOf (T.Connected l T.Disjunction r) = T.Connected (negatedOf l) T.Conjunction (negatedOf r)
    negatedOf body                            = T.Negated body
    atomsOf (T.Quantified _ _ body)         = atomsOf body
    atomsOf (T.Atomic a)                    = Just [a]
    atomsOf (T.Connected l T.Conjunction r) = (++) <$> atomsOf l <*> atomsOf r
    atomsOf _                               = Nothing
unfoldDefinition _ lit = [lit]

-- The goal atoms of the conjecture unit, which is more reliable than its
-- negation, since E may split or simplify that. A negated conclusion has no
-- goal atoms, so buildProofInfo takes them from a clause of the proof.
extractConjectureGoals :: [T.Unit] -> Maybe [T.Literal]
extractConjectureGoals units = listToMaybe
  [ cjGoals c | Right c <- map readConjecture (conjectureFormulas units), not (null (cjGoals c)) ]

-- Whether the conjecture concludes a negation, which its proof refutes.
concludesNegation :: [T.Unit] -> Bool
concludesNegation units = maybe False (not . null . snd) (conjectureHypotheses units)
