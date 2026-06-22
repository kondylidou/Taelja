module Helpers where

import Control.Applicative ((<|>))
import Data.List (nub)
import Data.Maybe (fromMaybe)
import Types

-- Variable collection

termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

litVars :: Literal -> [String]
litVars = foldLiteralTerms termVars

-- Traversal

-- Collect [a] by applying f to every term in a literal.
foldLiteralTerms :: (Term -> [a]) -> Literal -> [a]
foldLiteralTerms f (Eq l r)    = f l ++ f r
foldLiteralTerms f (NEq l r)   = f l ++ f r
foldLiteralTerms f (Rel _ ts)  = concatMap f ts
foldLiteralTerms f (NRel _ ts) = concatMap f ts

-- Transform every term in a literal by applying f.
mapLiteralTerms :: (Term -> Term) -> Literal -> Literal
mapLiteralTerms f (Eq l r)    = Eq  (f l) (f r)
mapLiteralTerms f (NEq l r)   = NEq (f l) (f r)
mapLiteralTerms f (Rel n ts)  = Rel n  (map f ts)
mapLiteralTerms f (NRel n ts) = NRel n (map f ts)

-- Substitution

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

-- Merge two substitutions, checking that shared variables agree.
extendSubst :: Subst -> Subst -> Maybe Subst
extendSubst base []           = Just base
extendSubst base ((x,t):rest) =
  case lookup x base of
    Nothing -> extendSubst ((x,t):base) rest
    Just t' -> if t == t' then extendSubst base rest else Nothing

-- Matching

-- One-way term matching: find σ s.t. applySubstTerm σ pat = tgt.
-- pat may have Vars (bindable); Vars in tgt are treated as ground atoms.
-- Threads an existing substitution s for consistency checking across multiple pairs.
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

-- Match a pattern literal against a target literal (structural, one-way).
matchLit :: Literal -> Literal -> Maybe Subst
matchLit (Eq  l1 r1) (Eq  l2 r2)
  = matchTerm l1 l2 [] >>= matchTerm r1 r2
matchLit (Rel n1 ts1) (Rel n2 ts2)
  | n1 == n2, length ts1 == length ts2
  = foldl (\ms (p, u) -> ms >>= matchTerm p u) (Just []) (zip ts1 ts2)
matchLit _ _ = Nothing

-- Bidirectional separate matching: nucleus-side Vars (in l) bind into σ0;
-- electron-side Vars (in r) bind into σi.  Consts must agree.
-- Used when both the body literal and the electron have free variables in
-- complementary positions so neither one-way direction suffices.
matchBothLit :: Literal -> Literal -> Subst -> Subst -> Maybe (Subst, Subst)
matchBothLit (Rel n1 ts1) (Rel n2 ts2) σ0 σi
  | n1 == n2, length ts1 == length ts2 =
      foldl step (Just (σ0, σi)) (zip ts1 ts2)
  where step ms (t, s) = ms >>= uncurry (matchBothTerm t s)
matchBothLit (Eq l1 r1) (Eq l2 r2) σ0 σi =
  matchBothTerm l1 l2 σ0 σi >>= uncurry (matchBothTerm r1 r2)
matchBothLit _ _ _ _ = Nothing

matchBothTerm :: Term -> Term -> Subst -> Subst -> Maybe (Subst, Subst)
matchBothTerm (Var x) k σ0 σi =
  let k' = applySubstTerm σi k
  in case lookup x σ0 of
    Nothing -> Just ((x, k') : σ0, σi)
    Just t  -> if t == k' then Just (σ0, σi) else Nothing
matchBothTerm l (Var y) σ0 σi =
  let l' = applySubstTerm σ0 l
  in case lookup y σi of
    Nothing -> Just (σ0, (y, l') : σi)
    Just t  -> if t == l' then Just (σ0, σi) else Nothing
matchBothTerm (Const c) (Const d) σ0 σi =
  if c == d then Just (σ0, σi) else Nothing
matchBothTerm (App f ts) (App g us) σ0 σi
  | f == g, length ts == length us =
      foldl step (Just (σ0, σi)) (zip ts us)
  where step ms (t, u) = ms >>= uncurry (matchBothTerm t u)
matchBothTerm _ _ _ _ = Nothing

-- Rewriting

-- One-step rewrite using equation (l,r) in direction dir.
-- Tries root first, then subterms left-to-right.
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

-- All one-step rewrites of term t using equation (l,r) in direction dir.
-- Unlike rewriteTerm, generates every applicable position (root + each subterm).
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

-- Lift rewriteTerm to a literal: rewrite the leftmost applicable subterm.
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

isEqChain :: ProofBlock -> Bool
isEqChain (EqChain {}) = True
isEqChain _            = False

-- Equality is symmetric: flip swaps sides of an Eq literal.
flipLit :: Literal -> Literal
flipLit (Eq l r) = Eq r l
flipLit x        = x

-- Renaming

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

-- Variable collectionfrom proof structures

lineVars :: ProofLine -> [String]
lineVars (Have  lit _) = litVars lit
lineVars (And   lit _) = litVars lit
lineVars (Hence lit _) = litVars lit

blockVars :: ProofBlock -> [String]
blockVars (HaveHence ls)    = nub (concatMap lineVars ls)
blockVars (EqChain s steps) = nub (termVars s ++ concatMap stepVars steps)
  where stepVars (RwStep _ (l, r) _, cur) = termVars l ++ termVars r ++ termVars cur

-- Term size (number of nodes in the term tree).
-- Used to prefer simpler rewrite candidates and avoid non-terminating chains.
termSize :: Term -> Int
termSize (Var _)    = 1
termSize (Const _)  = 1
termSize (App _ ts) = 1 + sum (map termSize ts)

litSize :: Literal -> Int
litSize = sum . foldLiteralTerms (\t -> [termSize t])

-- Block construction

appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"
