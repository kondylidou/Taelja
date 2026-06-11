module Helpers where

import Control.Applicative ((<|>))
import Data.List (find, nub)
import Data.Maybe (fromMaybe, listToMaybe)
import qualified Data.Set as Set
import Types

termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

litVars :: Literal -> [String]
litVars (Eq l r)    = termVars l ++ termVars r
litVars (NEq l r)   = termVars l ++ termVars r
litVars (Rel _ ts)  = concatMap termVars ts
litVars (NRel _ ts) = concatMap termVars ts

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

applySubst :: Subst -> Literal -> Literal
applySubst subst (Eq l r)    = Eq  (applySubstTerm subst l) (applySubstTerm subst r)
applySubst subst (NEq l r)   = NEq (applySubstTerm subst l) (applySubstTerm subst r)
applySubst subst (Rel n ts)  = Rel n  (map (applySubstTerm subst) ts)
applySubst subst (NRel n ts) = NRel n (map (applySubstTerm subst) ts)

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
renameLit r (Eq l ri)   = Eq  (renameTerm r l) (renameTerm r ri)
renameLit r (NEq l ri)  = NEq (renameTerm r l) (renameTerm r ri)
renameLit r (Rel n ts)  = Rel n  (map (renameTerm r) ts)
renameLit r (NRel n ts) = NRel n (map (renameTerm r) ts)

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
  Rel n ts  -> [ Rel  n (take i ts ++ [t'] ++ drop (i+1) ts)
               | (i, t) <- zip [0..] ts, t' <- rewritePos lhs rhs t ]
  NRel n ts -> [ NRel n (take i ts ++ [t'] ++ drop (i+1) ts)
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

-- Two-sided unification: both sides can bind variables.
-- Safe to skip occurs-check because body vars (c-prefixed) and unit vars
-- (uppercase-initial) are disjoint namespaces, so a binding can never loop.
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
  | f1 == f2 && length as1 == length as2 =
      foldl (\acc (a, b) -> acc >>= unifyTerm a b) (Just subst) (zip as1 as2)
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
groundSubtermsLit (Rel _ ts)  = concatMap groundSubterms ts
groundSubtermsLit (NRel _ ts) = concatMap groundSubterms ts
groundSubtermsLit (Eq l r)    = groundSubterms l ++ groundSubterms r
groundSubtermsLit (NEq l r)   = groundSubterms l ++ groundSubterms r

instantiations :: [String] -> [Term] -> [Subst]
instantiations freeVs terms =
  foldr (\v acc -> [(v, t) : s | t <- terms, s <- acc]) [[]] (nub freeVs)

-- BFS size bound: sum of start/goal sizes plus the largest equation lhs.
-- Keeps the search finite while still finding all reachable rewrites.
rwBound :: [(String, Term, Term)] -> Int -> Int -> Int
rwBound eqs a b = a + b + maximum (0 : [termSize l | (_, l, _) <- eqs])

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
    -- RL rewrites are only allowed when all rhs vars also appear on the lhs,
    -- otherwise applying RL would introduce new ungroundable variables.
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

-- Only named equations can appear here — unnamed ones can't be cited in proofs.
-- Call ensureNamed before using an equation in a BFS that needs to be recorded.
eqUnits :: [UnitEntry] -> [(String, Term, Term)]
eqUnits = concatMap toEq
  where
    toEq ue = case (ueName ue, ueUnit ue) of
      (Just nm, Eq l r) ->
        let extra = filter (`notElem` termVars l) (termVars r)
        in if null extra
           then [(nm, l, r)]
           else error ("eqUnits: " ++ nm ++ " has rhs variables not in lhs: " ++ show extra)
      _ -> []

findUnitByLit :: Literal -> [UnitEntry] -> Maybe UnitEntry
findUnitByLit lit = find (\ue -> ueUnit ue == lit)

tryMatchLit :: Literal -> Literal -> [UnitEntry] -> Maybe (Subst, [(RwStep, Literal)])
tryMatchLit lit goal units =
  bfsRewrite rewritePosLit litSize eqs (`matchLit` goal) lit bound
  where
    eqs   = eqUnits units
    bound = rwBound eqs (litSize lit) (litSize goal)

findMatchingUnit :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, [(RwStep, Literal)])
findMatchingUnit goal units = listToMaybe
  [ (ue, subst, rws)
  | ue <- units
  , Just (subst, rws) <- [tryMatchLit (ueUnit ue) goal units]
  ]

-- Body vars are "c"-prefixed (from freshenClause); unit vars are uppercase-initial
-- (TPTP convention). The namespaces are disjoint so splitting the combined
-- substitution by whether the variable starts with "c" correctly separates
-- σClause from σUnit.
tryMatchBodyLit :: Literal -> Literal -> [UnitEntry] -> Maybe (Subst, Subst, [(RwStep, Literal)])
tryMatchBodyLit bodyLit unitLit allUnits =
  fmap split (bfsRewrite rewritePosLit litSize eqs (\cur -> unifyLit bodyLit cur []) unitLit bound)
  where
    split (combined, path) =
      let bodyVarSet = litVars bodyLit
          σClause    = [(v, t) | (v, t) <- combined, v `elem`    bodyVarSet]
          σUnit      = [(v, t) | (v, t) <- combined, v `notElem` bodyVarSet]
      in (σClause, σUnit, path)
    eqs   = eqUnits allUnits
    bound = rwBound eqs (litSize bodyLit) (litSize unitLit)

findBodyLitMatch :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)])
findBodyLitMatch bodyLit units = listToMaybe
  [ (ue, σUnit, σClause, rws)
  | ue <- units
  , Just (σClause, σUnit, rws) <- [tryMatchBodyLit bodyLit (ueUnit ue) units]
  ]

-- Try one-sided matching first (cheaper); fall back to two-sided unification
-- for body literals that still have uninstantiated clause variables.
bodyLitMatch :: Literal -> [UnitEntry] -> Maybe BodyMatch
bodyLitMatch target units =
  ((\(ue, σUnit, rws)          -> BodyMatch ue σUnit rws [])       <$> findMatchingUnit  target units)
  <|>
  ((\(ue, σUnit, σClause, rws) -> BodyMatch ue σUnit rws σClause)  <$> findBodyLitMatch target units)

-- Unlike eqUnits, this includes unnamed equations (with a blank placeholder
-- name) so BFS can use them as stepping stones even if they can't be cited yet.
tryRwPath :: Literal -> Literal -> [UnitEntry] -> Maybe ([(RwStep, Literal)], Subst)
tryRwPath lit goal units =
  case bfsRewrite rewritePosLit litSize eqs (`matchLit` goal) lit bound of
    Just (σ, path) | not (null path) -> Just (path, σ)
    _                                -> Nothing
  where
    eqs   = [ (fromMaybe "" (ueName ue), l, r)
            | ue     <- units
            , Eq l r <- [ueUnit ue]
            , not (any (`notElem` termVars l) (termVars r)) ]
    bound = rwBound eqs (litSize lit) (litSize goal)

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

-- Returns True if any step in the derivation came from the named clause,
-- used to avoid promoting units that would create a circular reference.
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
