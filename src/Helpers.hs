module Helpers where

import Control.Applicative ((<|>))
import Data.Char (isAlphaNum)
import Data.List (inits, intercalate, isInfixOf, isPrefixOf, isSuffixOf, nub, permutations, tails)
import Data.Maybe (fromMaybe, isJust, listToMaybe)
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

-- Theorem 1's fresh constants.  θ grounds every variable the proof leaves
-- unbound to one of these, so a body atom is ground when its nucleus is
-- processed and no match can instantiate it.  When the derived head is stored
-- or a goal emitted they become variables again, and since they occur in no
-- axiom the fact holds for every value.
-- The prefix must not begin any symbol of a problem, or a real constant would
-- be turned into a variable when a derived fact is stored.  Benchmark names are
-- short or use the Isabelle prefixes c_, v_, t_ and tc_, so this one is safe.
rigidPrefix :: String
rigidPrefix = "taelja_rigid_"

isRigidConst :: String -> Bool
isRigidConst = (rigidPrefix `isPrefixOf`)

-- A groundness test counts both variables and fresh constants as open.
termFree :: Term -> [String]
termFree (Var x)    = [x]
termFree (Const c)  = [c | isRigidConst c]
termFree (App _ ts) = concatMap termFree ts

litFree :: Literal -> [String]
litFree = foldLiteralTerms termFree

unrigidTerm :: Term -> Term
unrigidTerm (Const c) | isRigidConst c = Var (drop (length rigidPrefix) c)
unrigidTerm (App f ts) = App f (map unrigidTerm ts)
unrigidTerm t = t

unrigidLit :: Literal -> Literal
unrigidLit = mapLiteralTerms unrigidTerm

unrigidBlock :: ProofBlock -> ProofBlock
unrigidBlock (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm) = Have  (unrigidLit lit) nm
    go (And  lit nm) = And   (unrigidLit lit) nm
    go (Hence lit j) = Hence (unrigidLit lit) j
unrigidBlock (EqChain start steps) =
  EqChain (unrigidTerm start)
          [ (RwStep nm (unrigidTerm l, unrigidTerm r) d, unrigidTerm cur)
          | (RwStep nm (l, r) d, cur) <- steps ]

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

-- Instantiate a stored proof block under the substitution matching its head
-- onto the requested literal.  Block variables absent from the head are local
-- to the block, and a plain substitution would capture any that share a name
-- with its range.  In SYN163-1 this turned p1(X2,X2_e,a) into the false
-- p1(X2_e,X2_e,a).  Clashing locals are renamed apart first.
instantiateBlock :: Literal -> Subst -> ProofBlock -> ProofBlock
instantiateBlock hd σ block =
  applySubstBlock σ (renameBlock renaming block)
  where
    headVars  = nub (litVars hd)
    locals    = filter (`notElem` headVars) (blockVars block)
    rangeVars = nub (concatMap (termVars . snd) σ)
    clashing  = filter (`elem` rangeVars) locals
    involved  = nub (blockVars block ++ rangeVars ++ map fst σ)
    suffix    = head [ sfx | n <- [1 :: Int ..], let sfx = concat (replicate n "_e")
                           , not (any (sfx `isSuffixOf`) involved) ]
    renaming  = [ (v, v ++ suffix) | v <- clashing ]

-- Replace constants in a term, leaving variables alone, to undo Skolemization.
applyConstSubstTerm :: [(String, Term)] -> Term -> Term
applyConstSubstTerm s (Const c)   = fromMaybe (Const c) (lookup c s)
applyConstSubstTerm s (App f ts)  = App f (map (applyConstSubstTerm s) ts)
applyConstSubstTerm _ t           = t

applyConstSubstLit :: [(String, Term)] -> Literal -> Literal
applyConstSubstLit s = mapLiteralTerms (applyConstSubstTerm s)

-- The function and constant symbols of a term, a literal and a block.
termSymbols :: Term -> [String]
termSymbols (Const c)  = [c]
termSymbols (Var _)    = []
termSymbols (App f ts) = f : concatMap termSymbols ts

litSymbols :: Literal -> [String]
litSymbols = foldLiteralTerms termSymbols

blockSymbols :: ProofBlock -> [String]
blockSymbols (HaveHence ls)    = nub (concatMap lineSyms ls)
  where
    lineSyms (Have  lit _) = litSymbols lit
    lineSyms (And   lit _) = litSymbols lit
    lineSyms (Hence lit _) = litSymbols lit
blockSymbols (EqChain s steps) = nub (termSymbols s ++ concatMap stepSyms steps)
  where stepSyms (RwStep _ (l, r) _, cur) = termSymbols l ++ termSymbols r ++ termSymbols cur

-- Replace every maximal subterm listed, outermost first.
applyTermSubstTerm :: [(Term, Term)] -> Term -> Term
applyTermSubstTerm s t = case lookup t s of
  Just t' -> t'
  Nothing -> case t of
    App f ts -> App f (map (applyTermSubstTerm s) ts)
    _        -> t

applyTermSubstLit :: [(Term, Term)] -> Literal -> Literal
applyTermSubstLit s = mapLiteralTerms (applyTermSubstTerm s)

applyTermSubstBlock :: [(Term, Term)] -> ProofBlock -> ProofBlock
applyTermSubstBlock s (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm)  = Have  (applyTermSubstLit s lit) nm
    go (And lit nm)   = And   (applyTermSubstLit s lit) nm
    go (Hence lit j)  = Hence (applyTermSubstLit s lit) j
applyTermSubstBlock s (EqChain start steps) =
  EqChain (applyTermSubstTerm s start)
          [ (RwStep nm (applyTermSubstTerm s l, applyTermSubstTerm s r) d, applyTermSubstTerm s cur)
          | (RwStep nm (l, r) d, cur) <- steps ]

applyConstSubstBlock :: [(String, Term)] -> ProofBlock -> ProofBlock
applyConstSubstBlock s (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm)  = Have  (applyConstSubstLit s lit) nm
    go (And  lit nm)  = And   (applyConstSubstLit s lit) nm
    go (Hence lit j)  = Hence (applyConstSubstLit s lit) j
applyConstSubstBlock s (EqChain start steps) =
  EqChain (applyConstSubstTerm s start)
          [ (RwStep nm (applyConstSubstTerm s l, applyConstSubstTerm s r) d, applyConstSubstTerm s cur)
          | (RwStep nm (l, r) d, cur) <- steps ]

-- Fails if a shared variable has conflicting bindings.
-- Extends a substitution and composes as it goes, applying each new binding
-- inside the existing ranges and those inside the new term, so one pass of
-- the result is complete.  Otherwise X ↦ X'_e then X'_e ↦ e left a dangling
-- X'_e and printed an instance as a general lemma, as in SYN179-1.
extendSubst :: Subst -> Subst -> Maybe Subst
extendSubst base []           = Just base
extendSubst base ((x,t):rest) =
  let t1 = applySubstTerm base t
  in case lookup x base of
    Nothing -> extendSubst ((x, t1) : [ (y, applySubstTerm [(x, t1)] u) | (y, u) <- base ]) rest
    Just t' -> if t1 == t' then extendSubst base rest else Nothing

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
  Eq  l r   -> [ (u, (`Eq` r) . c) | (u, c) <- termCtxs l ]
            ++ [ (u, Eq l . c)     | (u, c) <- termCtxs r ]
  NEq l r   -> [ (u, (`NEq` r) . c) | (u, c) <- termCtxs l ]
            ++ [ (u, NEq l . c)     | (u, c) <- termCtxs r ]
  Rel  n ts -> [ (u, Rel  n . c) | (u, c) <- argCtxs ts ]
  NRel n ts -> [ (u, NRel n . c) | (u, c) <- argCtxs ts ]
  where
    argCtxs ts = [ (u, \x -> take i ts ++ [c x] ++ drop (i + 1) ts)
                 | (i, t) <- zip [0 ..] ts, (u, c) <- termCtxs t ]

-- An equation whose right side has a variable its left side lacks, such as
-- zero = divide(zero,X), brings that variable into the line it rewrites, and
-- the next step then uses it at one value.  Read on its own the line would
-- hold for every value, which is more than the step gives, so the variable is
-- bound here to the value the next step takes and the chain states the
-- instance the proof uses.
tightenChainVars :: Term -> [(RwStep, Term)] -> (Term, [(RwStep, Term)])
tightenChainVars start steps =
  (apply start, [ (st, apply t) | (st, t) <- steps ])
  where
    terms    = start : map snd steps
    -- the chain states an equation between its first and last term, so the
    -- variables of both belong to the statement and stay as they are
    stmtVars = termVars start ++ termVars (last terms)
    local v  = v `notElem` stmtVars
    apply    = deepApplySubstTerm sigma
    -- only a chain that carries a variable of its own can need this
    sigma | all (`elem` stmtVars) (concatMap termVars terms) = []
          | otherwise = foldl bind [] [0 .. length steps - 1]

    -- A step rewrites one subterm, so the line and the next one differ there.
    -- When the cited equation does not take the one into the other as they
    -- stand, the variables the chain brought along are bound to the values
    -- the step takes them at.
    bind acc i =
      let prev = deepApplySubstTerm acc (terms !! i)
          cur  = deepApplySubstTerm acc (terms !! (i + 1))
          RwStep _ (l, r) dir = fst (steps !! i)
          (l0, r0) = if dir == LR then (l, r) else (r, l)
          -- the equation's variables are its own, so they are renamed apart
          -- from the line's, which may use the same names
          apart = [ (v, Var (v ++ "_ax")) | v <- nub (termVars l0 ++ termVars r0) ]
          (lhs, rhs) = (applySubstTerm apart l0, applySubstTerm apart r0)
      in case diffSubterm prev cur of
           Nothing -> acc
           Just (x, y)
             | not (any local (termVars x ++ termVars y)) -> acc
             | rewrites lhs rhs x y -> acc
             | otherwise -> case fixup lhs rhs x y of
                 (rho : _) -> acc ++ rho
                 []        -> acc

    -- The equation takes x to y as it stands.  Its own variables may be
    -- instantiated here, since it holds for every value of them, while a
    -- variable of the line is one the step is fixing and not free to move.
    rewrites lhs rhs x y = or
      [ True
      | Just s  <- [matchTerms lhs x]
      , Just s2 <- [matchTerms (applySubstTerm s rhs) y]
      , all (\(v, t) -> t == Var v || v `notElem` (termVars x ++ stmtVars)) s2 ]

    -- the equation applies once the chain's own variables take the values
    -- unifying it with the step demands
    fixup lhs rhs x y =
      [ rho
      | Just s1 <- [unifyTerms lhs x []]
      , Just s2 <- [unifyTerms (deepApplySubstTerm s1 rhs) (deepApplySubstTerm s1 y) s1]
      -- the value must be one the chain states, never a variable of the
      -- equation, which stands for nothing outside its own step
      -- resolve the unifier so a value stated through the equation's own
      -- variable comes out as the term the chain has there
      , let s2' = [ (v, deepApplySubstTerm s2 t) | (v, t) <- s2 ]
      , let rho = [ b | b@(v, t) <- orient s2'
                      , local v, t /= Var v, v `elem` (termVars x ++ termVars y)
                      , all (`elem` (termVars x ++ termVars y ++ stmtVars)) (termVars t) ]
      , not (null rho)
      , rewrites lhs rhs (deepApplySubstTerm rho x) (deepApplySubstTerm rho y) ]

    -- unification may bind the line's variable to the statement's or the
    -- other way round, and only the line's may be bound
    orient rho = [ case t of
                     Var w | not (local v), local w -> (w, Var v)
                     _                              -> (v, t)
                 | (v, t) <- rho ]

-- The smallest subterm pair holding every difference between two terms, and
-- nothing when they are equal.  A step rewrites one subterm, so this is the
-- redex and its replacement.
diffSubterm :: Term -> Term -> Maybe (Term, Term)
diffSubterm a b
  | a == b = Nothing
  | otherwise = case (a, b) of
      (App f as, App g bs)
        | f == g, length as == length bs
        , [(x, y)] <- [ p | p@(x, y) <- zip as bs, x /= y ] ->
            Just (fromMaybe (x, y) (diffSubterm x y))
      _ -> Just (a, b)

termCtxs :: Term -> [(Term, Term -> Term)]
termCtxs t = (t, id) : case t of
  App f ts -> [ (u, \x -> App f (take i ts ++ [c x] ++ drop (i + 1) ts))
              | (i, ti) <- zip [0 ..] ts, (u, c) <- termCtxs ti ]
  _        -> []

-- Apply σ to a fixed point, so X→f(Y) with Y→c resolves to X→f(c).
deepApplySubstTerm :: Subst -> Term -> Term
deepApplySubstTerm s t =
  let t' = applySubstTerm s t
  in if t' == t then t else deepApplySubstTerm s t'

-- Rename every variable of a literal by appending a suffix, so a unit and a
-- goal literal do not clash when unified.
suffixVarsLit :: String -> Literal -> Literal
suffixVarsLit suf = mapLiteralTerms go
  where
    go (Var x)    = Var (x ++ suf)
    go (Const c)  = Const c
    go (App f ts) = App f (map go ts)

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

-- A proof block with no steps (nothing established).
-- A positive atom as the term Twee rewrites (p(t) as a term, p as a constant).
atomTerm :: Literal -> Term
atomTerm (Rel n [])  = Const n
atomTerm (Rel n as)  = App n as
atomTerm l           = error ("atomTerm: not a positive atom: " ++ show l)

-- The equation a chain step rewrites with, either an equation or the P = true
-- encoding of a positive atom.
unitEquation :: Literal -> (Term, Term)
unitEquation (Eq a b) = (a, b)
unitEquation l        = (atomTerm l, Const "true")

-- Unification of two literals.  Equality is symmetric, so two equations unify
-- if either orientation does, and a goal c1 = c2 is not flagged against a
-- conjecture written c2 = c1.
unifyLits :: Literal -> Literal -> Subst -> Maybe Subst
unifyLits (Eq a b) (Eq c d) σ =
  (unifyTerms a c σ >>= unifyTerms b d) <|> (unifyTerms a d σ >>= unifyTerms b c)
unifyLits (Rel n as) (Rel m bs) σ | n == m, length as == length bs =
  foldr (\(a, b) acc -> acc >>= unifyTerms a b) (Just σ) (zip as bs)
unifyLits _ _ _ = Nothing

flipDir :: Dir -> Dir
flipDir LR = RL
flipDir RL = LR

-- The contradiction derived when the axioms alone are inconsistent, from which
-- every goal follows.
falsumLit :: Literal
falsumLit = Rel "$false" []

-- The fact a block ends on establishes the literal it is stored under, up to
-- orientation and instantiation.  A block whose last line states something
-- else proves nothing about that literal, as ALG210+2's candidate lemmas did
-- when their sub-proof only restated the assumption they rest on.
blockConcludes :: Literal -> ProofBlock -> Bool
blockConcludes lit blk = case blk of
  HaveHence ls -> case reverse ls of
    (l : _) -> ok (lineLit l)
    []      -> False
  EqChain start steps -> case reverse steps of
    ((_, t) : _) -> ok (Eq start t)
                    || (t == Const "true" && isRelLit lit && start == atomTerm lit)
    []           -> False
  where
    ok l = isJust (matchLit l lit) || isJust (matchLit (flipLit l) lit)
    isRelLit (Rel _ _) = True
    isRelLit _         = False
    lineLit (Have l _)  = l
    lineLit (And l _)   = l
    lineLit (Hence l _) = l

isEmptyBlock :: ProofBlock -> Bool
isEmptyBlock (HaveHence []) = True
isEmptyBlock (EqChain _ []) = True
isEmptyBlock _              = False

isEqChain :: ProofBlock -> Bool
isEqChain (EqChain {}) = True
isEqChain _            = False

-- A clause's text with its variables named by first occurrence and its body
-- in the order that gives the smallest text, so variants and reorderings get
-- the same key.  A body of more than six literals keeps its order.
clauseKey :: Clause -> String
clauseKey (Clause bs mh) = minimum (map keyOf orders)
  where
    orders | length bs <= 6 = permutations bs
           | otherwise      = [bs]
    keyOf body = show (Clause (map (ren body) body) (fmap (ren body) mh))
    ren body   = renameLit (zip (nub (concatMap litVars body ++ maybe [] litVars mh))
                                [ "v" ++ show i | i <- [0 :: Int ..] ])

-- The second clause is an instance of the first, the body literals matched
-- in any order.
clauseInstance :: Clause -> Clause -> Bool
clauseInstance c1 c2 = isJust (clauseInstanceSubst c1 c2)

-- The prefix of a variable standing for the witness of an existential
-- conclusion a hypothesis of the conjecture promises, as SYN359+1's
-- big_r(Y) => ? [Z] : big_q(Y,Z) does.  The conjecture grants the clause only
-- at a witness the prover named, so the substitution is checked at these
-- variables where the clause is granted.
witnessPrefix :: String
witnessPrefix = "Wit_"

isWitnessVar :: String -> Bool
isWitnessVar = (witnessPrefix `isPrefixOf`)

-- The matching substitution when the second clause is an instance of the
-- first, the body literals matched in any order.
clauseInstanceSubst :: Clause -> Clause -> Maybe Subst
clauseInstanceSubst (Clause bs1 h1) (Clause bs2 h2) =
  if length bs1 /= length bs2 then Nothing else (do
    σ <- case (h1, h2) of
      (Just a, Just b)   -> matchEither a b []
      (Nothing, Nothing) -> Just []
      _                  -> Nothing
    bodies bs1 bs2 σ)
  where
    bodies [] [] σ = Just σ
    bodies (a : as) bs σ = listToMaybe
      [ σ'' | (b, rest) <- picks bs, Just σ' <- [matchEither a b σ], Just σ'' <- [bodies as rest σ'] ]
    bodies _ _ _ = Nothing
    picks xs = [ (x, before ++ after) | (before, x : after) <- zip (inits xs) (tails xs) ]
    -- an equation is the same literal either way round
    matchEither a b σ = matchLitWith a b σ <|> matchLitWith (flipLit a) b σ

-- Flip an equation, used to try both orientations while matching.
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

-- The variables a block prints, in order.  A chain step's cited equation is
-- printed by name only, so its variables are not among them and should not
-- take a display name before those that are.
blockShownVars :: ProofBlock -> [String]
blockShownVars (HaveHence ls)    = nub (concatMap lineVars ls)
blockShownVars (EqChain s steps) = nub (termVars s ++ concatMap (termVars . snd) steps)

-- Node count, where smaller means a simpler rewrite candidate.
termSize :: Term -> Int
termSize (Var _)    = 1
termSize (Const _)  = 1
termSize (App _ ts) = 1 + sum (map termSize ts)

-- Names (axioms, lemmas, "assumption", ...) cited anywhere in a block.
blockRefNames :: ProofBlock -> [String]
blockRefNames (HaveHence ls)    = concatMap lineRef ls
  where
    lineRef (Have _ nm)            = [nm]
    lineRef (And _ nm)             = [nm]
    lineRef (Hence _ (ByAxiom nm)) = [nm]
    lineRef (Hence _ (ByRw nm _))  = [nm]
    lineRef (Hence _ ByContradiction) = []
blockRefNames (EqChain _ steps) = [ rwName rw | (rw, _) <- steps ]

-- Rename cited names throughout a block.
renameRefsBlock :: (String -> String) -> ProofBlock -> ProofBlock
renameRefsBlock ren (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm)            = Have lit (ren nm)
    go (And lit nm)             = And lit (ren nm)
    go (Hence lit (ByAxiom nm)) = Hence lit (ByAxiom (ren nm))
    go (Hence lit (ByRw nm d))  = Hence lit (ByRw (ren nm) d)
    go l@(Hence _ ByContradiction) = l
renameRefsBlock ren (EqChain s steps) =
  EqChain s [ (rw { rwName = ren (rwName rw) }, t) | (rw, t) <- steps ]

appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"

ppTerm :: Term -> String
ppTerm (Var x)    = x
ppTerm (Const c)  = ppSymbol c
ppTerm (App f ts) = ppSymbol f ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

-- A symbol as printed.  A word or an operator name, as LCL's ==>, reads back
-- unquoted.  Anything else, as LCL897-10's ' = =>' or CSR117+1's 55.67631,
-- is quoted as in TPTP.  A defined symbol such as $false stays as it is.
ppSymbol :: String -> String
ppSymbol f
  | all (\c -> isAlphaNum c || c == '_') f || all (`elem` "+*/^<>=-%&|~") f = f
  | ('$' : rest) <- f, all (\c -> isAlphaNum c || c == '_') rest = f
  | otherwise = "'" ++ concatMap esc f ++ "'"
  where
    esc '\'' = "\\'"
    esc '\\' = "\\\\"
    esc c    = [c]

-- True for units internal to the Twee encoding that must not appear in a proof,
-- namely the Skolemized premises prem_N, the ifeq_axiom sentinel and any unit
-- without a display name.
isInternalUnit :: UnitEntry -> Bool
isInternalUnit ue = case ueName ue of
  Just nm -> isPrefixOf "prem_" nm || nm == "ifeq_axiom"
  Nothing -> True

-- | Restrict prover output to its SZS output block when there is one.  Twee
-- 2.7 with --formal-proof wraps the block in a readable preamble and trailer
-- that are not TSTP and make the file unparseable.  Without markers the text
-- is returned unchanged.
extractSzsBlock :: String -> String
extractSzsBlock txt = dropIntroducedParents $ typedClausesAsFormulas $ dropDistinctTypings $
  case break isStart (lines txt) of
    (_, [])        -> txt
    (_, startLine : rest) ->
      let (body, restEnd) = break isEnd rest
          endLine = take 1 restEnd
      in if any isUnit body
           then unlines (startLine : body ++ endLine)
           -- A TPTP solution file lists the proof as clean units at the top
           -- and repeats the raw output below as comments.  Its only SZS
           -- marker is in that commented copy, so cutting to it would keep no
           -- unit at all.  The clean units are the proof.
           else txt
  where
    isStart l = "SZS output start" `isInfixOf` l
    isEnd   l = "SZS output end"   `isInfixOf` l
    isUnit  l = any (`isPrefixOf` dropWhile (== ' ') l) ["cnf(", "fof(", "tff(", "tcf("]

-- E declares a distinct object with a type, tff(d, type, "Apple": $i), which
-- is not TPTP and which the parser rejects, and a distinct object needs no
-- declaration, so those lines are dropped.
dropDistinctTypings :: String -> String
dropDistinctTypings = unlines . filter (not . distinctTyping) . lines
  where
    distinctTyping l = "tff(" `isPrefixOf` l && ", type, \"" `isInfixOf` l

-- E writes typed clauses as tcf units, which the parser does not know, and a
-- tcf is a tff whose formula is a clause, so they are read as tff.
typedClausesAsFormulas :: String -> String
typedClausesAsFormulas = unlines . map fix . lines
  where
    fix l | "tcf(" `isPrefixOf` l = "tff(" ++ drop 4 l
          | otherwise             = l

-- The parser reads introduced(kind, [info]) only, while Vampire and current
-- TPTP also write a third list of parents, so that list is dropped.
dropIntroducedParents :: String -> String
dropIntroducedParents = go
  where
    key = "introduced("
    go [] = []
    go s@(c : cs)
      | key `isPrefixOf` s =
          let (inner, rest) = balanced (drop (length key) s)
          in key ++ intercalate "," (take 2 (topLevelArgs inner)) ++ ")" ++ go rest
      | otherwise = c : go cs
    -- the text up to the parenthesis closing an open one, and what follows it
    balanced = walk (0 :: Int)
      where
        walk _ [] = ([], [])
        walk d (x : xs)
          | x == ')' && d == 0 = ([], xs)
          | x `elem` "([" = first (x :) (walk (d + 1) xs)
          | x `elem` ")]" = first (x :) (walk (d - 1) xs)
          | otherwise     = first (x :) (walk d xs)
        first f (a, b) = (f a, b)

-- The arguments of a term's text, split at the commas outside brackets.
topLevelArgs :: String -> [String]
topLevelArgs = walk (0 :: Int) []
  where
    walk _ acc [] = [reverse acc]
    walk d acc (x : xs)
      | x == ',' && d == 0 = reverse acc : walk d [] xs
      | x `elem` "([" = walk (d + 1) (x : acc) xs
      | x `elem` ")]" = walk (d - 1) (x : acc) xs
      | otherwise     = walk d (x : acc) xs

-- | Syntactic unification with occurs check.  Both terms share one variable
-- space (used for the two sides of a goal equation, whose variables stem from
-- an existential conjecture and may therefore be instantiated).
unifyTerms :: Term -> Term -> Subst -> Maybe Subst
unifyTerms s0 t0 = go [(s0, t0)]
  where
    go [] θ = Just θ
    go ((s, t) : rest) θ =
      let s' = deepApplySubstTerm θ s
          t' = deepApplySubstTerm θ t
      in if s' == t' then go rest θ else case (s', t') of
        (Var x, _) -> bind x t' rest θ
        (_, Var y) -> bind y s' rest θ
        (App f as, App g bs) | f == g, length as == length bs -> go (zip as bs ++ rest) θ
        _ -> Nothing
    bind x t rest θ
      | x `elem` termVars t = Nothing
      | otherwise           = go rest ((x, t) : θ)

isEqLit :: Literal -> Bool
isEqLit (Eq _ _) = True
isEqLit _        = False

dirFlag :: Dir -> Maybe Dir
dirFlag LR = Nothing
dirFlag RL = Just RL

findEqByName :: String -> [UnitEntry] -> Maybe (Term, Term)
findEqByName nm units = listToMaybe
  [ (l, r) | ue <- units, ueName ue == Just nm, Eq l r <- [ueUnit ue] ]

applyRwLine :: ProofBlock -> (RwStep, Literal) -> ProofBlock
applyRwLine b (rw, c) = appendLine b (Hence c (ByRw (rwName rw) (dirFlag (rwDir rw))))

-- Length of common prefix of two strings.
commonPrefixLen :: String -> String -> Int
commonPrefixLen s1 s2 = length $ takeWhile id $ zipWith (==) s1 s2

-- Replay a demodulation chain, given outermost first and replayed innermost
-- first.  Every step must name a known equation and apply, or the replay
-- does not reproduce the prover's rewriting and the result is Nothing.
rwChain :: (String -> Maybe (Term, Term)) -> Literal -> [(String, Dir)] -> Maybe (Literal, [(RwStep, Literal)])
rwChain eqOf start chain = go start [] (reverse chain)
  where
    go cur acc [] = Just (cur, reverse acc)
    go cur acc ((nm, dir) : rest) = do
      (l, r) <- eqOf nm
      cur'   <- rewriteLit cur (l, r) dir
      go cur' ((RwStep nm (l, r) dir, cur') : acc) rest
