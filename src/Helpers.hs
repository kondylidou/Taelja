module Helpers where

import Control.Applicative ((<|>))
import Data.List (nub)
import Data.Maybe (fromMaybe)
import Types

-- Variable collection --------------------------------------------------------

termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

litVars :: Literal -> [String]
litVars = foldLiteralTerms termVars

-- Traversal ------------------------------------------------------------------

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

-- Substitution application ---------------------------------------------------

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

-- Matching -------------------------------------------------------------------

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

-- Rewriting (REWRITE) --------------------------------------------------------

-- REWRITE(s, l=r, dir): one-step rewrite of term t using equation (l,r) in
-- direction dir. Tries root first, then subterms left-to-right.
-- Returns Nothing if no position matches.
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

-- IS_EQ_CHAIN(pf): true if the proof block is an equational chain.
isEqChain :: ProofBlock -> Bool
isEqChain (EqChain {}) = True
isEqChain _            = False

-- Renaming -------------------------------------------------------------------

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

-- Variable collection from proof structures ----------------------------------

lineVars :: ProofLine -> [String]
lineVars (Have  lit _) = litVars lit
lineVars (And   lit _) = litVars lit
lineVars (Hence lit _) = litVars lit

blockVars :: ProofBlock -> [String]
blockVars (HaveHence ls)    = nub (concatMap lineVars ls)
blockVars (EqChain s steps) = nub (termVars s ++ concatMap stepVars steps)
  where stepVars (RwStep _ (l, r) _, cur) = termVars l ++ termVars r ++ termVars cur

-- Block construction ---------------------------------------------------------

appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"
