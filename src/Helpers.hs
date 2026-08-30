module Helpers where

import Control.Applicative ((<|>))
import Data.List (intercalate, isPrefixOf, isSuffixOf, nub)
import Data.Maybe (fromMaybe)
import Types

termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

litVars :: Literal -> [String]
litVars = foldLiteralTerms termVars

termConsts :: Term -> [String]
termConsts (Const c)  = [c]
termConsts (Var _)    = []
termConsts (App _ ts) = concatMap termConsts ts

litConsts :: Literal -> [String]
litConsts = foldLiteralTerms termConsts

foldLiteralTerms :: (Term -> [a]) -> Literal -> [a]
foldLiteralTerms f (Eq l r)    = f l ++ f r
foldLiteralTerms f (NEq l r)   = f l ++ f r
foldLiteralTerms f (Rel _ ts)  = concatMap f ts
foldLiteralTerms f (NRel _ ts) = concatMap f ts

mapLiteralTerms :: (Term -> Term) -> Literal -> Literal
mapLiteralTerms f (Eq l r)    = Eq  (f l) (f r)
mapLiteralTerms f (NEq l r)   = NEq (f l) (f r)
mapLiteralTerms f (Rel n ts)  = Rel n  (map f ts)
mapLiteralTerms f (NRel n ts) = NRel n (map f ts)

applySubstTerm :: Subst -> Term -> Term
applySubstTerm subst (Var x)    = fromMaybe (Var x) (lookup x subst)
applySubstTerm _     (Const c)  = Const c
applySubstTerm subst (App f ts) = App f (map (applySubstTerm subst) ts)

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

-- Replace constants (not variables) in a term; used to undo Skolemization.
applyConstSubstTerm :: [(String, Term)] -> Term -> Term
applyConstSubstTerm s (Const c)   = fromMaybe (Const c) (lookup c s)
applyConstSubstTerm s (App f ts)  = App f (map (applyConstSubstTerm s) ts)
applyConstSubstTerm _ t           = t

applyConstSubstLit :: [(String, Term)] -> Literal -> Literal
applyConstSubstLit s = mapLiteralTerms (applyConstSubstTerm s)

applyConstSubstBlock :: [(String, Term)] -> ProofBlock -> ProofBlock
applyConstSubstBlock s (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm)  = Have  (applyConstSubstLit s lit) nm
    go (And  lit nm)  = And   (applyConstSubstLit s lit) nm
    go (Hence lit j)  = Hence (applyConstSubstLit s lit) j
applyConstSubstBlock s (EqChain start steps) =
  EqChain (applyConstSubstTerm s start)
          [(rw, applyConstSubstTerm s cur) | (rw, cur) <- steps]

-- fails if any shared variable has conflicting bindings
extendSubst :: Subst -> Subst -> Maybe Subst
extendSubst base []           = Just base
extendSubst base ((x,t):rest) =
  case lookup x base of
    Nothing -> extendSubst ((x,t):base) rest
    Just t' -> if t == t' then extendSubst base rest else Nothing

-- threads an existing substitution so multiple patterns can share bindings
matchTerm :: Term -> Term -> Subst -> Maybe Subst
matchTerm (Var x)    t     s = case lookup x s of
  Nothing -> Just ((x, t) : s)
  Just t' -> if t == t' then Just s else Nothing
matchTerm (Const c)  (Const d)  s | c == d               = Just s
matchTerm (App f ts) (App g us) s | f == g, length ts == length us =
  foldl (\ms (p, u) -> ms >>= matchTerm p u) (Just s) (zip ts us)
matchTerm _          _          _ = Nothing

matchTerms :: Term -> Term -> Maybe Subst
matchTerms pat tgt = matchTerm pat tgt []

matchLit :: Literal -> Literal -> Maybe Subst
matchLit pat tgt = matchLitWith pat tgt []

-- matchLit threading an existing substitution
matchLitWith :: Literal -> Literal -> Subst -> Maybe Subst
matchLitWith (Eq  l1 r1) (Eq  l2 r2) s
  = matchTerm l1 l2 s >>= matchTerm r1 r2
matchLitWith (Rel n1 ts1) (Rel n2 ts2) s
  | n1 == n2, length ts1 == length ts2
  = foldl (\ms (p, u) -> ms >>= matchTerm p u) (Just s) (zip ts1 ts2)
matchLitWith _ _ _ = Nothing

-- Every subterm of a literal together with a function that rebuilds the
-- literal with that subterm replaced.
litSubtermCtxs :: Literal -> [(Term, Term -> Literal)]
litSubtermCtxs lit = case lit of
  Eq  l r   -> [ (u, \x -> Eq  (c x) r) | (u, c) <- termCtxs l ]
            ++ [ (u, \x -> Eq  l (c x)) | (u, c) <- termCtxs r ]
  NEq l r   -> [ (u, \x -> NEq (c x) r) | (u, c) <- termCtxs l ]
            ++ [ (u, \x -> NEq l (c x)) | (u, c) <- termCtxs r ]
  Rel  n ts -> [ (u, \x -> Rel  n (c x)) | (u, c) <- argCtxs ts ]
  NRel n ts -> [ (u, \x -> NRel n (c x)) | (u, c) <- argCtxs ts ]
  where
    argCtxs ts = [ (u, \x -> take i ts ++ [c x] ++ drop (i + 1) ts)
                 | (i, t) <- zip [0 ..] ts, (u, c) <- termCtxs t ]

termCtxs :: Term -> [(Term, Term -> Term)]
termCtxs t = (t, id) : case t of
  App f ts -> [ (u, \x -> App f (take i ts ++ [c x] ++ drop (i + 1) ts))
              | (i, ti) <- zip [0 ..] ts, (u, c) <- termCtxs ti ]
  _        -> []

-- Apply σ until fixed point; resolves chained bindings (e.g. X→f(Y), Y→c becomes X→f(c)).
deepApplySubstTerm :: Subst -> Term -> Term
deepApplySubstTerm s t =
  let t' = applySubstTerm s t
  in if t' == t then t else deepApplySubstTerm s t'

-- Rename all variables in a literal by appending a suffix; used to
-- avoid name clashes when unifying a unit with a goal literal.
suffixVarsLit :: String -> Literal -> Literal
suffixVarsLit suf = mapLiteralTerms go
  where
    go (Var x)    = Var (x ++ suf)
    go (Const c)  = Const c
    go (App f ts) = App f (map go ts)

-- bidirectional: body-side vars bind σ0, electron-side vars bind ρi
matchBothLit :: Literal -> Literal -> Subst -> Subst -> Maybe (Subst, Subst)
matchBothLit (Rel n1 ts1) (Rel n2 ts2) σ0 ρi
  | n1 == n2, length ts1 == length ts2 =
      foldl step (Just (σ0, ρi)) (zip ts1 ts2)
  where step ms (t, s) = ms >>= uncurry (matchBothTerm t s)
matchBothLit (Eq l1 r1) (Eq l2 r2) σ0 ρi =
  matchBothTerm l1 l2 σ0 ρi >>= uncurry (matchBothTerm r1 r2)
matchBothLit _ _ _ _ = Nothing

matchBothTerm :: Term -> Term -> Subst -> Subst -> Maybe (Subst, Subst)
matchBothTerm (Var x) (Var y) σ0 ρi | x == y = Just (σ0, ρi)
matchBothTerm (Var x) k σ0 ρi =
  let k' = applySubstTerm ρi k
  in case lookup x σ0 of
    Nothing -> Just ((x, k') : σ0, ρi)
    -- x already bound to t; propagate by matching t against k'.
    -- If t is an electron var (suffix "_e"), further constrain it on the
    -- electron side (ρi) — not σ0 — so repeated body vars like m0(X,X,Y)
    -- correctly ground the electron var on both occurrences.
    Just t  -> if t == k' then Just (σ0, ρi)
               else case t of
                 Var y | "_e" `isSuffixOf` y ->
                   case lookup y ρi of
                     Nothing -> Just (σ0, (y, k') : ρi)
                     Just t' -> if t' == k' then Just (σ0, ρi) else Nothing
                 _ -> matchBothTerm t k' σ0 ρi
matchBothTerm l (Var y) σ0 ρi =
  let l' = applySubstTerm σ0 l
  in case lookup y ρi of
    Nothing -> Just (σ0, (y, l') : ρi)
    -- Apply σ0 to the stored binding: it may contain σ0-variables bound later.
    Just t  -> if applySubstTerm σ0 t == l' then Just (σ0, ρi) else Nothing
matchBothTerm (Const c) (Const d) σ0 ρi =
  if c == d then Just (σ0, ρi) else Nothing
matchBothTerm (App f ts) (App g us) σ0 ρi
  | f == g, length ts == length us =
      foldl step (Just (σ0, ρi)) (zip ts us)
  where step ms (t, u) = ms >>= uncurry (matchBothTerm t u)
matchBothTerm _ _ _ _ = Nothing

rewriteTerm :: Term -> (Term, Term) -> Dir -> Maybe Term
rewriteTerm t (l, r) dir = tryRoot <|> trySubs
  where
    (lhs, rhs) = if dir == LR then (l, r) else (r, l)
    tryRoot    = applySubstTerm <$> matchTerms lhs t <*> pure rhs
    trySubs    = case t of
      App f ts -> App f <$> rewriteFirst ts
      _        -> Nothing
    rewriteFirst []     = Nothing
    rewriteFirst (u:us) = case rewriteTerm u (l, r) dir of
      Just u' -> Just (u' : us)
      Nothing -> (u :) <$> rewriteFirst us

-- all matching positions, not just leftmost
rewriteTermAll :: Term -> (Term, Term) -> Dir -> [Term]
rewriteTermAll t (l, r) dir = rootResult ++ subResults
  where
    (lhs, rhs) = if dir == LR then (l, r) else (r, l)
    rootResult = case matchTerms lhs t of
      Just σ  -> [applySubstTerm σ rhs]
      Nothing -> []
    subResults = case t of
      App f ts -> [ App f (take i ts ++ [u'] ++ drop (i+1) ts)
                  | (i, u) <- zip [0..] ts
                  , u' <- rewriteTermAll u (l, r) dir
                  ]
      _ -> []

rewriteLit :: Literal -> (Term, Term) -> Dir -> Maybe Literal
rewriteLit lit eq dir = case lit of
  Eq  l r   -> ((`Eq`  r) <$> rewriteTerm l eq dir)
           <|> (Eq  l   <$> rewriteTerm r eq dir)
  NEq l r   -> ((`NEq` r) <$> rewriteTerm l eq dir)
           <|> (NEq l   <$> rewriteTerm r eq dir)
  Rel  n ts -> Rel  n <$> rewriteFirst ts
  NRel n ts -> NRel n <$> rewriteFirst ts
  where
    rewriteFirst []     = Nothing
    rewriteFirst (u:us) = case rewriteTerm u eq dir of
      Just u' -> Just (u' : us)
      Nothing -> (u :) <$> rewriteFirst us

-- all single-step rewriting positions (not just leftmost)
rewriteLitAll :: Literal -> (Term, Term) -> Dir -> [Literal]
rewriteLitAll lit eq dir = case lit of
  Eq  l r -> [Eq  l' r  | l' <- rewriteTermAll l eq dir]
          ++ [Eq  l  r' | r' <- rewriteTermAll r eq dir]
  NEq l r -> [NEq l' r  | l' <- rewriteTermAll l eq dir]
          ++ [NEq l  r' | r' <- rewriteTermAll r eq dir]
  Rel  n ts -> map (Rel  n) (rewriteListAll ts)
  NRel n ts -> map (NRel n) (rewriteListAll ts)
  where
    rewriteListAll []     = []
    rewriteListAll (t:ts) = [t' : ts | t' <- rewriteTermAll t eq dir]
                         ++ [t : ts' | ts' <- rewriteListAll ts]

isEqChain :: ProofBlock -> Bool
isEqChain (EqChain {}) = True
isEqChain _            = False

-- Eq is symmetric; used when trying both orientations during matching.
flipLit :: Literal -> Literal
flipLit (Eq l r) = Eq r l
flipLit x        = x

renameTerm :: [(String, String)] -> Term -> Term
renameTerm r (Var x)    = maybe (Var x) Var (lookup x r)
renameTerm _ (Const c)  = Const c
renameTerm r (App f ts) = App f (map (renameTerm r) ts)

renameLit :: [(String, String)] -> Literal -> Literal
renameLit r = mapLiteralTerms (renameTerm r)

renameProofLine :: [(String, String)] -> ProofLine -> ProofLine
renameProofLine r (Have  lit nm) = Have  (renameLit r lit) nm
renameProofLine r (And   lit nm) = And   (renameLit r lit) nm
renameProofLine r (Hence lit j)  = Hence (renameLit r lit) j

renameBlock :: [(String, String)] -> ProofBlock -> ProofBlock
renameBlock r (HaveHence ls)    = HaveHence (map (renameProofLine r) ls)
renameBlock r (EqChain s steps) = EqChain (renameTerm r s) (map renameStep steps)
  where renameStep (RwStep nm (l, ri) d, cur) =
          (RwStep nm (renameTerm r l, renameTerm r ri) d, renameTerm r cur)

lineVars :: ProofLine -> [String]
lineVars (Have  lit _) = litVars lit
lineVars (And   lit _) = litVars lit
lineVars (Hence lit _) = litVars lit

blockVars :: ProofBlock -> [String]
blockVars (HaveHence ls)    = nub (concatMap lineVars ls)
blockVars (EqChain s steps) = nub (termVars s ++ concatMap stepVars steps)
  where stepVars (RwStep _ (l, r) _, cur) = termVars l ++ termVars r ++ termVars cur

-- node count; smaller = simpler rw candidate
termSize :: Term -> Int
termSize (Var _)    = 1
termSize (Const _)  = 1
termSize (App _ ts) = 1 + sum (map termSize ts)

litSize :: Literal -> Int
litSize = sum . foldLiteralTerms (\t -> [termSize t])

-- Names (axioms, lemmas, "assumption", ...) cited anywhere in a block.
blockRefNames :: ProofBlock -> [String]
blockRefNames (HaveHence ls)    = concatMap lineRef ls
  where
    lineRef (Have _ nm)            = [nm]
    lineRef (And _ nm)             = [nm]
    lineRef (Hence _ (ByAxiom nm)) = [nm]
    lineRef (Hence _ (ByRw nm _))  = [nm]
blockRefNames (EqChain _ steps) = [ rwName rw | (rw, _) <- steps ]

-- Rename cited names throughout a block.
renameRefsBlock :: (String -> String) -> ProofBlock -> ProofBlock
renameRefsBlock ren (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm)            = Have lit (ren nm)
    go (And lit nm)             = And lit (ren nm)
    go (Hence lit (ByAxiom nm)) = Hence lit (ByAxiom (ren nm))
    go (Hence lit (ByRw nm d))  = Hence lit (ByRw (ren nm) d)
renameRefsBlock ren (EqChain s steps) =
  EqChain s [ (rw { rwName = ren (rwName rw) }, t) | (rw, t) <- steps ]

appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"

ppTerm :: Term -> String
ppTerm (Var x)    = x
ppTerm (Const c)  = c
ppTerm (App f ts) = f ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

-- True for Twee-internal units that should not appear in human-readable proof steps:
-- prem_N (Skolemized body premises) and ifeq_axiom (encoding sentinel).
-- Unnamed units (no display name) are also internal.
isInternalUnit :: UnitEntry -> Bool
isInternalUnit ue = case ueName ue of
  Just nm -> isPrefixOf "prem_" nm || nm == "ifeq_axiom"
  Nothing -> True
