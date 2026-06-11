module Helpers where

import Control.Applicative ((<|>))
import Data.List (find, nub)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Set as Set
import Types

termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

litVars :: Literal -> [String]
litVars = foldLiteralTerms termVars

termSize :: Term -> Int
termSize (Var _)    = 1
termSize (Const _)  = 1
termSize (App _ ts) = 1 + sum (map termSize ts)

litSize :: Literal -> Int
litSize (Eq l r)    = termSize l + termSize r
litSize (NEq l r)   = termSize l + termSize r
litSize (Rel _ ts)  = sum (map termSize ts)
litSize (NRel _ ts) = sum (map termSize ts)

applySubstTerm :: Subst -> Term -> Term
applySubstTerm subst (Var x)    = fromMaybe (Var x) (lookup x subst)
applySubstTerm _     (Const c)  = Const c
applySubstTerm subst (App f ts) = App f (map (applySubstTerm subst) ts)

-- Applies a function to every term position in a literal.
mapLiteralTerms :: (Term -> Term) -> Literal -> Literal
mapLiteralTerms f (Eq l r)    = Eq  (f l) (f r)
mapLiteralTerms f (NEq l r)   = NEq (f l) (f r)
mapLiteralTerms f (Rel n ts)  = Rel n  (map f ts)
mapLiteralTerms f (NRel n ts) = NRel n (map f ts)

-- Collects results from every term position in a literal.
foldLiteralTerms :: (Term -> [a]) -> Literal -> [a]
foldLiteralTerms f (Eq l r)    = f l ++ f r
foldLiteralTerms f (NEq l r)   = f l ++ f r
foldLiteralTerms f (Rel _ ts)  = concatMap f ts
foldLiteralTerms f (NRel _ ts) = concatMap f ts

applySubst :: Subst -> Literal -> Literal
applySubst subst = mapLiteralTerms (applySubstTerm subst)

applySubstLine :: Subst -> ProofLine -> ProofLine
applySubstLine subst (Have  lit nm) = Have  (applySubst subst lit) nm
applySubstLine subst (And   lit nm) = And   (applySubst subst lit) nm
applySubstLine subst (Hence lit j)  = Hence (applySubst subst lit) j

applySubstBlock :: Subst -> ProofBlock -> ProofBlock
applySubstBlock subst (HaveHence ls)    = HaveHence (map (applySubstLine subst) ls)
applySubstBlock subst (EqChain s steps) =
  EqChain (applySubstTerm subst s) (map applyStep steps)
  where
    applyStep (RwStep nm (l, r) d, cur) =
      (RwStep nm (applySubstTerm subst l, applySubstTerm subst r) d, applySubstTerm subst cur)

renameTerm :: [(String, String)] -> Term -> Term
renameTerm r (Var x)    = maybe (Var x) Var (lookup x r)
renameTerm _ (Const c)  = Const c
renameTerm r (App f ts) = App f (map (renameTerm r) ts)

renameLit :: [(String, String)] -> Literal -> Literal
renameLit r = mapLiteralTerms (renameTerm r)

-- Rewrites lhs to rhs at every position in t and returns all possible results.
rewritePos :: Term -> Term -> Term -> [Term]
rewritePos lhs rhs t =
  [ applySubstTerm subst rhs | Just subst <- [matchTerm lhs t []] ]
  ++ case t of
       App f args ->
         [ App f (take i args ++ [t'] ++ drop (i+1) args)
         | (i, arg) <- zip [0..] args
         , t' <- rewritePos lhs rhs arg
         ]
       _ -> []

rewritePosLit :: Term -> Term -> Literal -> [Literal]
rewritePosLit lhs rhs lit = case lit of
  Eq  l r   -> [Eq  l' r | l' <- rewritePos lhs rhs l]
            ++ [Eq  l r' | r' <- rewritePos lhs rhs r]
  NEq l r   -> [NEq l' r | l' <- rewritePos lhs rhs l]
            ++ [NEq l r' | r' <- rewritePos lhs rhs r]
  Rel  n ts -> rwArgs (Rel  n) ts
  NRel n ts -> rwArgs (NRel n) ts
  where
    rwArgs con ts = [ con (take i ts ++ [t'] ++ drop (i+1) ts)
                    | (i, t) <- zip [0..] ts, t' <- rewritePos lhs rhs t ]

matchTerm :: Term -> Term -> Subst -> Maybe Subst
matchTerm (Var x) t subst =
  case lookup x subst of
    Nothing -> Just ((x, t) : subst)
    Just t' -> if t' == t then Just subst else Nothing
matchTerm (Const c) (Const c') subst
  | c == c'   = Just subst
  | otherwise = Nothing
matchTerm (App f1 as1) (App f2 as2) subst
  | f1 == f2 && length as1 == length as2 = matchAll (zip as1 as2) subst
  | otherwise = Nothing
matchTerm _ _ _ = Nothing

matchLit :: Literal -> Literal -> Maybe Subst
matchLit (Rel n1 ts1) (Rel n2 ts2)
  | n1 == n2 && length ts1 == length ts2 = matchAll (zip ts1 ts2) []
  | otherwise = Nothing
matchLit (NRel n1 ts1) (NRel n2 ts2)
  | n1 == n2 && length ts1 == length ts2 = matchAll (zip ts1 ts2) []
  | otherwise = Nothing
matchLit (Eq  l1 r1) (Eq  l2 r2) = matchAll [(l1, l2), (r1, r2)] []
                                <|> matchAll [(l1, r2), (r1, l2)] []
matchLit (NEq l1 r1) (NEq l2 r2) = matchAll [(l1, l2), (r1, r2)] []
                                <|> matchAll [(l1, r2), (r1, l2)] []
matchLit _ _ = Nothing

matchAll :: [(Term, Term)] -> Subst -> Maybe Subst
matchAll = pairFold matchTerm

pairFold :: (a -> b -> c -> Maybe c) -> [(a, b)] -> c -> Maybe c
pairFold f pairs s = foldl (\acc (a, b) -> acc >>= f a b) (Just s) pairs

-- Two-sided unification. The occurs-check is skipped because body vars (c-prefixed)
-- and unit vars (uppercase-initial) are disjoint, so a variable can never
-- appear on both sides of a binding.
unifyTerm :: Term -> Term -> Subst -> Maybe Subst
unifyTerm (Var x) t subst
  | Var x == t = Just subst
  | otherwise  = case lookup x subst of
      Nothing -> Just ((x, t) : subst)
      Just t' -> if t' == t then Just subst else Nothing
unifyTerm t (Var y) subst = unifyTerm (Var y) t subst
unifyTerm (Const c1) (Const c2) subst
  | c1 == c2  = Just subst
  | otherwise = Nothing
unifyTerm (App f1 as1) (App f2 as2) subst
  | f1 == f2 && length as1 == length as2 = unifyAll (zip as1 as2) subst
  | otherwise = Nothing
unifyTerm _ _ _ = Nothing

unifyAll :: [(Term, Term)] -> Subst -> Maybe Subst
unifyAll = pairFold unifyTerm

unifyLit :: Literal -> Literal -> Subst -> Maybe Subst
unifyLit (Rel n1 ts1) (Rel n2 ts2) subst
  | n1 == n2 && length ts1 == length ts2 = unifyAll (zip ts1 ts2) subst
  | otherwise = Nothing
unifyLit (NRel n1 ts1) (NRel n2 ts2) subst
  | n1 == n2 && length ts1 == length ts2 = unifyAll (zip ts1 ts2) subst
  | otherwise = Nothing
unifyLit (Eq l1 r1) (Eq l2 r2) subst =
  unifyAll [(l1, l2), (r1, r2)] subst
  <|> unifyAll [(l1, r2), (r1, l2)] subst
unifyLit (NEq l1 r1) (NEq l2 r2) subst =
  unifyAll [(l1, l2), (r1, r2)] subst
  <|> unifyAll [(l1, r2), (r1, l2)] subst
unifyLit _ _ _ = Nothing

groundSubterms :: Term -> [Term]
groundSubterms t@(Const _)  = [t]
groundSubterms t@(App _ ts)
  | null (termVars t) = t : concatMap groundSubterms ts
  | otherwise         = concatMap groundSubterms ts
groundSubterms (Var _) = []

groundSubtermsLit :: Literal -> [Term]
groundSubtermsLit = foldLiteralTerms groundSubterms

-- All ways to assign each free variable to one of the given ground terms.
instantiations :: [String] -> [Term] -> [Subst]
instantiations freeVs terms =
  foldr (\v acc -> [(v, t) : s | t <- terms, s <- acc]) [[]] (nub freeVs)

-- The bound is generous enough to reach any term reachable in one equation
-- application from either side, so no useful path gets pruned.
rwBound :: [(String, Term, Term)] -> Int -> Int -> Int
rwBound eqs a b = a + b + maximum (0 : [termSize l | (_, l, _) <- eqs])

-- Generic BFS engine over rewrite sequences.
-- rwFn applies one equation step. The check fires when the goal is reached.
-- The path accumulates in reverse and gets flipped on success.
bfsRewrite :: Ord a
           => (Term -> Term -> a -> [a])
           -> (a -> Int)
           -> [(String, Term, Term)]
           -> (a -> Maybe r)
           -> a
           -> Int
           -> Maybe (r, [(RwStep, a)])
bfsRewrite rwFn sizeFn eqs check start bound =
    bfs [(start, [])] (Set.singleton start)
  where
    bfs [] _ = Nothing
    bfs frontier visited =
      case [hit | (cur, path) <- frontier, Just r <- [check cur]
                , let hit = (r, reverse path)] of
        hit : _ -> Just hit
        []      ->
          let candidates = concatMap (step visited) frontier
              frontier'  = dedupFst candidates
              visited'   = Set.union visited (Set.fromList (map fst frontier'))
          in bfs frontier' visited'
    dedupFst xs = go xs Set.empty
      where
        go []              _    = []
        go ((k, v) : rest) seen
          | Set.member k seen = go rest seen
          | otherwise         = (k, v) : go rest (Set.insert k seen)
    -- RL is only safe when lhs vars are a subset of rhs vars. Otherwise
    -- applying the equation right-to-left would introduce unbound variables.
    step visited (cur, path) =
      [ (cur', (RwStep nm (origL, origR) dir, cur') : path)
      | (nm, origL, origR) <- eqs
      , (lhs, rhs, dir)    <- (origL, origR, LR)
                            : [(origR, origL, RL) | all (`elem` termVars origR) (termVars origL)]
      , cur'               <- rwFn lhs rhs cur
      , cur' /= cur
      , sizeFn cur' <= bound
      , Set.notMember cur' visited
      ]

-- Only named equations make it here. Unnamed ones cannot be cited in a proof.
-- Equations where rhs has variables not in lhs are skipped: they cannot be
-- applied as rewrite rules without introducing unbound variables.
eqUnits :: [UnitEntry] -> [(String, Term, Term)]
eqUnits = concatMap toEq
  where
    toEq ue = case (ueName ue, ueUnit ue) of
      (Just nm, Eq l r)
        | all (`elem` termVars l) (termVars r) -> [(nm, l, r)]
      _ -> []

findUnitByLit :: Literal -> [UnitEntry] -> Maybe UnitEntry
findUnitByLit lit = find (\ue -> ueUnit ue == lit)

-- BFS from lit, trying to reach goal using one-sided matching. Unit vars can bind.
tryMatchLit :: Literal -> Literal -> [UnitEntry] -> Maybe (Subst, [(RwStep, Literal)])
tryMatchLit lit goal units =
  bfsRewrite rewritePosLit litSize eqs (`matchLit` goal) lit bound
  where
    eqs   = eqUnits units
    bound = rwBound eqs (litSize lit) (litSize goal)

-- Scans units in order and returns the first one that can be rewritten to match goal.
findMatchingUnit :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, [(RwStep, Literal)])
findMatchingUnit goal units = listToMaybe
  [ (ue, subst, rws)
  | ue <- units
  , Just (subst, rws) <- [tryMatchLit (ueUnit ue) goal units]
  ]

-- BFS from unitLit using two-sided unification against bodyLit.
-- Split the combined unifier by membership in the target's (bodyLit's) variable
-- set: bindings for target vars update the running clause substitution (σClause),
-- bindings for unit vars are applied to the stored proof block (σUnit).
-- This handles both axiom units (uppercase vars) and derived units (c-prefixed
-- vars from a prior clause computation) without relying on a naming convention.
tryMatchBodyLit :: Literal -> Literal -> [UnitEntry] -> Maybe (Subst, Subst, [(RwStep, Literal)])
tryMatchBodyLit bodyLit unitLit allUnits =
  fmap split (bfsRewrite rewritePosLit litSize eqs (\cur -> unifyLit bodyLit cur []) unitLit bound)
  where
    split (combined, path) =
      let targetVarSet = litVars bodyLit
          σClause = [(v, t) | (v, t) <- combined, v `elem`    targetVarSet]
          σUnit   = [(v, t) | (v, t) <- combined, v `notElem` targetVarSet]
      in (σClause, σUnit, path)
    eqs   = eqUnits allUnits
    bound = rwBound eqs (litSize bodyLit) (litSize unitLit)

findBodyLitMatch :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)])
findBodyLitMatch bodyLit units = listToMaybe
  [ (ue, σUnit, σClause, rws)
  | ue <- units
  , Just (σClause, σUnit, rws) <- [tryMatchBodyLit bodyLit (ueUnit ue) units]
  ]

-- Tries matching first since it's cheaper. Falls back to unification only
-- when the target has free clause variables that matching cannot bind.
bodyLitMatch :: Literal -> [UnitEntry] -> Maybe BodyMatch
bodyLitMatch target units =
  ((\(ue, σUnit, rws)          -> BodyMatch ue σUnit rws [])       <$> findMatchingUnit  target units)
  <|>
  ((\(ue, σUnit, σClause, rws) -> BodyMatch ue σUnit rws σClause)  <$> findBodyLitMatch target units)

-- All equation units usable as BFS rewrite steps, including unnamed ones.
-- Unnamed equations get an empty placeholder name; any caller that needs to cite
-- an equation in a proof must call ensureNamed to obtain the real name.
allEqUnitsForRw :: [UnitEntry] -> [(String, Term, Term)]
allEqUnitsForRw = mapMaybe toEq
  where
    toEq ue = case ueUnit ue of
      Eq l r | all (`elem` termVars l) (termVars r) ->
        Just (fromMaybe "" (ueName ue), l, r)
      _ -> Nothing

-- Like tryMatchLit but includes unnamed equations as stepping stones.
-- BFS can route through them even when they cannot yet be cited in the proof.
-- Requires a non-empty path. Trivial matches go through findMatchingUnit instead.
tryRwPath :: Literal -> Literal -> [UnitEntry] -> Maybe ([(RwStep, Literal)], Subst)
tryRwPath lit goal units =
  case bfsRewrite rewritePosLit litSize eqs (`matchLit` goal) lit bound of
    Just (σ, path) | not (null path) -> Just (path, σ)
    _                                -> Nothing
  where
    eqs   = allEqUnitsForRw units
    bound = rwBound eqs (litSize lit) (litSize goal)

-- Term-level BFS for building equational chains in EqChain goals and lemmas.
findPath :: [UnitEntry] -> Term -> Term -> Maybe [(RwStep, Term)]
findPath units s t =
  fmap snd (bfsRewrite rewritePos termSize eqs check s bound)
  where
    eqs   = eqUnits units
    bound = maximum (0 : [termSize l | (_, l, _) <- eqs]) + max (termSize s) (termSize t)
    check cur = if cur == t then Just () else Nothing

appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"

-- Checks whether a unit's derivation cites the named clause anywhere.
-- Used to avoid prelemmatizing something that would create a circular reference.
derivedByClause :: String -> UnitEntry -> Bool
derivedByClause name ue = case ueDeriv ue of
  Just (HaveHence ls) -> any isFromClause ls
  _                   -> False
  where
    isFromClause (Hence _ (ByAxiom n)) = n == name
    isFromClause _                     = False

blockVars :: ProofBlock -> [String]
blockVars (HaveHence ls)    = nub (concatMap lineVars ls)
blockVars (EqChain s steps) = nub (termVars s ++ concatMap stepVars steps)
  where stepVars (RwStep _ (l, r) _, cur) = termVars l ++ termVars r ++ termVars cur

lineVars :: ProofLine -> [String]
lineVars (Have  lit _) = litVars lit
lineVars (And   lit _) = litVars lit
lineVars (Hence lit _) = litVars lit

renameBlock :: [(String, String)] -> ProofBlock -> ProofBlock
renameBlock r (HaveHence ls)    = HaveHence (map (renameProofLine r) ls)
renameBlock r (EqChain s steps) = EqChain (renameTerm r s) (map renameStep steps)
  where renameStep (RwStep nm (l, ri) d, cur) =
          (RwStep nm (renameTerm r l, renameTerm r ri) d, renameTerm r cur)

renameProofLine :: [(String, String)] -> ProofLine -> ProofLine
renameProofLine r (Have  lit nm) = Have  (renameLit r lit) nm
renameProofLine r (And   lit nm) = And   (renameLit r lit) nm
renameProofLine r (Hence lit j)  = Hence (renameLit r lit) j
