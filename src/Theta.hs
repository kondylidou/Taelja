-- Theorem 1's θ: the one grounding substitution under which the input proof
-- tree T is a ground proof tree Tθ, and the coherence check that validates an
-- assembled hyperresolution step before it is emitted.
--
-- Tθ is a proof tree only if every inference of T still applies after
-- instantiation, so θ has to agree with the unifier of every step.  It is
-- therefore computed as one unification problem over the whole tree: the
-- variables of every clause are renamed apart by position, each inference is
-- replayed from its premises (resolution, superposition or rewriting, a
-- literal dropped by equality resolution or as a duplicate) and its result is
-- unified with the clause the prover printed for it.  The most general
-- solution is θ up to the variables no step ever binds; those are the
-- theorem's fresh constants and stay as (rigid) variables, one per class of
-- identified variables.
module Theta
  ( ThetaCtx (..)
  , computeNucleusTheta
  , sharedNodeTheta
  , resolutionCoherent
  , derivedHead
  ) where

import Control.Monad (foldM)
import Data.List (nub, sortBy)
import Data.Maybe (isJust)
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T

import Types
import Helpers
import TptpConvert (convertDeclToClause)

data ThetaCtx = ThetaCtx
  { tcDeclAt  :: Map.Map String T.Declaration
  , tcSimpl   :: Map.Map String [(String, Dir)]  -- demodulation chain folded into the inference at a position
  , tcEqOf    :: String -> Maybe (Term, Term)    -- the chain's equations by name
  , tcShared  :: Map.Map String Subst  -- θ|p for every position (see sharedNodeTheta)
  }

-- θ restricted to one nucleus, in the variables of its abstract clause.
-- Theorem 1's θ'_k: a variable occurring in the head but in no body literal
-- stays free, so the derived electron is as general as the proof allows.
computeNucleusTheta :: ThetaCtx -> LeafEntry -> Subst
computeNucleusTheta ctx entry =
  let θ = Map.findWithDefault [] (lePos entry) (tcShared ctx)
      headOnly = case convertDeclToClause (leSrcDecl entry) of
        Just (Clause bs (Just h)) -> filter (`notElem` concatMap litVars bs) (litVars h)
        _                          -> []
  in filter (\(v, _) -> v `notElem` headOnly) θ

-- The clause a position stands for in the unification problem: a leaf
-- entry's abstract clause (the source axiom, whose variables the nucleus is
-- processed with), otherwise the clause printed at that position.
abstractDecl :: LeafEntry -> T.Declaration
abstractDecl e = if leRole e == OrigAxiom then leSrcDecl e else leDecl e

-- The global θ, computed once per run: θ|p for every position, in that
-- position's own variable names.  A variable no inference binds is left out
-- unless it was identified with another position's variable, in which case
-- both map to one shared rigid variable.
sharedNodeTheta :: Map.Map String T.Declaration -> [LeafEntry] -> Map.Map String Subst
sharedNodeTheta declAt entries = Map.mapWithKey thetaAt clauses
  where
    entryClauses = Map.fromList [ (lePos e, c) | e <- entries, Just c <- [convertDeclToClause (abstractDecl e)] ]
    clauses = Map.union entryClauses (Map.mapMaybe convertDeclToClause declAt)

    -- variables renamed apart by position: v@p
    at p v = v ++ "@" ++ p
    litsAt p = [ (b, mapLiteralTerms (apart p) l) | (b, l) <- polLits (clauses Map.! p) ]
    apart p (Var v)    = Var (at p v)
    apart _ (Const c)  = Const c
    apart p (App f ts) = App f (map (apart p) ts)

    -- inferences, root first: a node's children are p0/p1 (binary) or p1 (unary)
    nodes = sortBy (comparing (\(p, _) -> (length p, p)))
              [ (p, kids) | p <- Map.keys clauses
                          , let kids = filter (`Map.member` clauses) [p ++ "0", p ++ "1"]
                          , not (null kids) ]

    σ = solveAll [ (litsAt p, map litsAt kids) | (p, kids) <- nodes ]

    -- θ is grounding: a variable no inference binds becomes a fresh
    -- constant, one per class of identified variables (its representative
    -- names it).  Head-only variables are exempted by computeNucleusTheta.
    thetaAt p c =
      [ (v, ground (walkDeep σ (Var (at p v))))
      | v <- nub (concatMap (litVars . snd) (polLits c)) ]
    ground (Var x)    = Const (rigidPrefix ++ map (\ch -> if ch == '@' then '_' else ch) x)
    ground (Const c)  = Const c
    ground (App f ts) = App f (map ground ts)

polLits :: Clause -> [(Bool, Literal)]
polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]

-- Solve the inferences in order, backtracking over the ways each can be
-- explained, within a step budget; past the budget, or when no joint
-- solution exists, every inference keeps its first explanation that is
-- consistent with what was found so far.  An inference that has no
-- explanation even on its own (a synthetic node whose replay failed) is
-- left out up front rather than allowed to fail the whole search: its
-- variables then stay free and the step fails honestly downstream.
solveAll :: [([(Bool, Literal)], [[(Bool, Literal)]])] -> USubst
solveAll infs0 = case search infs Map.empty budget of
    (Just s, _) -> s
    (Nothing, _) -> foldl greedy Map.empty infs
  where
    infs = filter (not . null . (`explain` Map.empty)) infs0
    budget = 2000 :: Int
    search [] s b = (Just s, b)
    search (inf : rest) s b = try (explain inf s) b
      where
        try [] b' = (Nothing, b')
        try (s' : more) b'
          | b' <= 0   = (Nothing, 0)
          | otherwise = case search rest s' (b' - 1) of
              (Just r, b'')  -> (Just r, b'')
              (Nothing, b'') -> try more b''
    greedy s inf = case explain inf s of
      (s' : _) -> s'
      []       -> s

-- The solver's own substitution.  It holds one binding per variable of the
-- whole tree, so it must not be an association list applied to a fixed
-- point on every unification step: a variable is dereferenced by walking
-- the map instead (ALG006-1's nested terms otherwise make the solve
-- quadratic in the number of bindings).
type USubst = Map.Map String Term

-- follow variable-to-variable chains one level deep
walk :: USubst -> Term -> Term
walk s t@(Var x) = maybe t (walk s) (Map.lookup x s)
walk _ t         = t

-- fully instantiate a term
walkDeep :: USubst -> Term -> Term
walkDeep s t = case walk s t of
  App f ts -> App f (map (walkDeep s) ts)
  t'       -> t'

occursIn :: USubst -> String -> Term -> Bool
occursIn s x t = case walk s t of
  Var y    -> x == y
  App _ ts -> any (occursIn s x) ts
  _        -> False

unifyU :: Term -> Term -> USubst -> Maybe USubst
unifyU a b s = case (walk s a, walk s b) of
  (Var x, Var y) | x == y -> Just s
  (Var x, t)              -> bind x t
  (t, Var y)              -> bind y t
  (Const c, Const d) | c == d -> Just s
  (App f as, App g bs) | f == g, length as == length bs ->
    foldM (\acc (p, q) -> unifyU p q acc) s (zip as bs)
  _ -> Nothing
  where bind x t = if occursIn s x t then Nothing else Just (Map.insert x t s)

-- Every substitution extending s under which the inference holds: the
-- premises combine into a result clause, and that result is the printed
-- conclusion up to instantiation and the dropping of trivial or duplicate
-- literals.
explain :: ([(Bool, Literal)], [[(Bool, Literal)]]) -> USubst -> [USubst]
explain (parent, kids) s
  | not (null strict) = strict
  -- A prover may fold a rewriting into an inference and print one body
  -- literal in its un-normalized form (Twee on ANA023-2 prints
  -- c_plus(c_0,g,t_b) <= k where the step used g <= k).  Then no replay
  -- reproduces the clause literally.  Rather than leave every variable of
  -- the premise free, the remaining literals are allowed to determine them.
  | otherwise = concat [ coverLoose result parent s1
                       | (pairs, result) <- alternatives kids
                       , Just s1 <- [foldM (\acc (a, b) -> unifyU a b acc) s pairs] ]
  where
    strict = [ s2 | (pairs, result) <- alternatives kids
                  , Just s1 <- [foldM (\acc (a, b) -> unifyU a b acc) s pairs]
                  , s2 <- cover result parent s1 ]

-- The ways two premises (or one) combine, each as the term equations the
-- step needs and the literals of its result.
alternatives :: [[(Bool, Literal)]] -> [([(Term, Term)], [(Bool, Literal)])]
alternatives [a]    = [([], a)]
-- The last two are a fallback for a step that instantiates one premise and
-- then rewrites it by the other: the rewritten position is still a variable
-- before the conclusion is matched, so no superposition above reaches it.
-- Taking the conclusion as an instance of that premise, with the rewritten
-- literal left over for coverLoose, recovers the instantiation.
alternatives [a, b] = resolve a b ++ resolve b a ++ superpose a b ++ superpose b a
                      ++ [([], a), ([], b)]
alternatives _      = []

heads, bodies :: [(Bool, Literal)] -> [Literal]
heads x  = [ l | (True, l) <- x ]
bodies x = [ l | (False, l) <- x ]

-- x's head against a body literal of y
resolve :: [(Bool, Literal)] -> [(Bool, Literal)] -> [([(Term, Term)], [(Bool, Literal)])]
resolve x y =
  [ ([(litTerm h, litTerm b')], [ (False, l) | l <- bodies x ] ++ rest ++ [ (True, l) | l <- heads y ])
  | h <- heads x
  , ((False, b), rest) <- picks y
  , b' <- orientations b ]

-- x's equation head rewrites a non-variable subterm of a literal of y (that
-- one occurrence, or every occurrence of the subterm in the clause)
superpose :: [(Bool, Literal)] -> [(Bool, Literal)] -> [([(Term, Term)], [(Bool, Literal)])]
superpose x y = nub
  [ ([(l, u)], [ (False, m) | m <- bodies x ] ++ y')
  | Eq s t <- heads x
  , (l, r) <- [(s, t), (t, s)]
  , notVar l   -- a rewrite rule's left-hand side is never a bare variable
  , (i, (_, lit)) <- zip [0 :: Int ..] y
  , (u, ctx) <- litSubtermCtxs lit
  , notVar u
  , y' <- [ [ (sign, if j == i then ctx r else m) | (j, (sign, m)) <- zip [0 :: Int ..] y ]
          , [ (sign, mapLiteralTerms (replaceAll u r) m) | (sign, m) <- y ] ] ]
  where
    replaceAll u r t | t == u = r
    replaceAll u r (App f ts) = App f (map (replaceAll u r) ts)
    replaceAll _ _ t = t

-- The printed conclusion is the replayed result up to renaming and the
-- dropping of trivial or duplicate literals.  So every result literal is
-- matched onto a conclusion literal of the same polarity (equations in
-- either orientation), binding only the premises' variables, or is a body
-- equation s ≈ t dropped with s and t unified (equality resolution, trivial
-- inequality removal); every conclusion literal is hit at least once.
cover :: [(Bool, Literal)] -> [(Bool, Literal)] -> USubst -> [USubst]
cover result parent s0 = go result [] s0
  where
    idxParent = zip [0 :: Int ..] parent
    -- the conclusion's variables (as instantiated so far) are never bound here
    rigid = Set.fromList
              (concatMap (litVars . mapLiteralTerms (walkDeep s0) . snd) parent)
    go [] hit s
      | all ((`elem` hit) . fst) idxParent = [s]
      | otherwise = []
    go ((sign, l) : ls) hit s =
      [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
            , l' <- orientations l
            , Just s' <- [matchModulo rigid (litTerm l') (litTerm p) s]
            , s'' <- go ls (i : hit) s' ]
      ++ [ s'' | not sign, Eq a b <- [l], Just s' <- [unifyU a b s], s'' <- go ls hit s' ]

-- Matching under a substitution: variables of the pattern that are still
-- unbound and not rigid may be bound; the target is never instantiated.
matchModulo :: Set.Set String -> Term -> Term -> USubst -> Maybe USubst
matchModulo rigid = go
  where
    go pat tgt s = case (walk s pat, walk s tgt) of
      (Var x, Var y) | x == y -> Just s
      (Var x, t) | not (Set.member x rigid), not (occursIn s x t) -> Just (Map.insert x t s)
      (Const c, Const d) | c == d -> Just s
      (App f as, App g bs) | f == g, length as == length bs ->
        foldM (\acc (a, b) -> go a b acc) s (zip as bs)
      _ -> Nothing

-- cover, but one literal on each side may go unaccounted for: the one the
-- prover rewrote when it folded a simplification into the inference.  Twee
-- on ANA023-2 instantiates transitivity at c_plus(c_0,g,t_b) <= k and then
-- rewrites its conclusion to g <= f, and no replay reproduces that, because
-- the rewritten position is still a variable before the conclusion is
-- matched.  Leaving every variable of the premise free instead would lose
-- the whole step.  This only widens θ, which is an input to the search: the
-- assembled step is still checked by resolutionCoherent and by Lean, so a
-- premise that does not in fact follow fails honestly.
coverLoose :: [(Bool, Literal)] -> [(Bool, Literal)] -> USubst -> [USubst]
coverLoose result parent s0 = go result [] False s0
  where
    idxParent = zip [0 :: Int ..] parent
    rigid = Set.fromList
              (concatMap (litVars . mapLiteralTerms (walkDeep s0) . snd) parent)
    go [] hit _ s
      | length [ () | (i, _) <- idxParent, i `notElem` hit ] <= 1 = [s]
      | otherwise = []
    go ((sign, l) : ls) hit skipped s =
      [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
            , l' <- orientations l
            , Just s' <- [matchModulo rigid (litTerm l') (litTerm p) s]
            , s'' <- go ls (i : hit) skipped s' ]
      ++ [ s'' | not skipped, s'' <- go ls hit True s ]

orientations :: Literal -> [Literal]
orientations (Eq l r) = [Eq l r, Eq r l]
orientations l        = [l]

litTerm :: Literal -> Term
litTerm (Rel n as)  = App n as
litTerm (NRel n as) = App n as
litTerm (Eq l r)    = App "=" [l, r]
litTerm (NEq l r)   = App "=" [l, r]

notVar :: Term -> Bool
notVar (Var _) = False
notVar _       = True

picks :: [a] -> [(a, [a])]
picks xs = [ (x, take i xs ++ drop (i + 1) xs) | (i, x) <- zip [0 ..] xs ]

-- The conclusion the rule draws from exactly these premise instances, when
-- its body atoms unify with them.  This is what a reader (and the Lean
-- check) derives from the emitted block, so an equation is printed in this
-- orientation.
derivedHead :: [Literal] -> Literal -> [Literal] -> Maybe Literal
derivedHead bodyAbs headAbs targets
  | length bodyAbs /= length targets = Nothing
  | otherwise = case foldM stepU Map.empty (zip bodyAbs' targets) of
      Nothing -> Nothing
      Just s  -> Just (mapLitTerms (walkDeep s) headAbs')
  where
    ren = suffixVarsLit "_dh"
    bodyAbs' = map ren bodyAbs
    headAbs' = ren headAbs
    stepU s (b, t) = case (litTermM b, litTermM t) of
      (Just tb, Just tt) -> case unifyU tb tt s of
        Just s' -> Just s'
        Nothing -> case t of
          Eq l r -> litTermM (Eq r l) >>= \tt' -> unifyU tb tt' s
          _      -> Nothing
      _ -> Nothing
    litTermM (Rel n as) = Just (App n as)
    litTermM (Eq l r)   = Just (App "=" [l, r])
    litTermM _          = Nothing
    mapLitTerms f (Rel n as) = Rel n (map f as)
    mapLitTerms f (Eq l r)   = Eq (f l) (f r)
    mapLitTerms _ l          = l

-- Validates one assembled hyperresolution step: the rule's body atoms are
-- unified (shared rule variables, fresh-renamed) against the matched electron
-- targets; the step is coherent when the unifier exists and the head it
-- derives covers the head instance about to be stored.  This is the same
-- judgement the Lean check makes, applied before anything is emitted, so a
-- spurious premise match cannot justify a θ-derived head (LCL416-1).
resolutionCoherent :: [Literal] -> Literal -> [Literal] -> Literal -> Bool
resolutionCoherent bodyAbs headAbs targets headInst
  -- a step whose conclusion is one of its own premises is vacuous
  | headInst `elem` targets = False
  | otherwise =
  case foldM step [] (zip bodyAbs' targets) of
    Nothing -> False
    Just s  ->
      let derived = mapLitTerms (deepApplySubstTerm s) headAbs'
      in derived `notElem` targets
         && (derived == headInst || isJust (matchLit derived headInst)
         || (case (derived, headInst) of
               (Eq l r, _) -> let d' = Eq r l
                              in d' == headInst || isJust (matchLit d' headInst)
               _           -> False))
  where
    ren = suffixVarsLit "_rc"
    bodyAbs' = map ren bodyAbs
    headAbs' = ren headAbs
    -- equations may have been matched in flipped orientation
    step s (b, t) = case (litTermM b, litTermM t) of
      (Just tb, Just tt) -> case unifyTerms tb tt s of
        Just s' -> Just s'
        Nothing -> case t of
          Eq l r -> litTermM (Eq r l) >>= \tt' -> unifyTerms tb tt' s
          _      -> Nothing
      _                  -> Nothing
    litTermM (Rel n as) = Just (App n as)
    litTermM (Eq l r)   = Just (App "=" [l, r])
    litTermM _          = Nothing
    mapLitTerms f (Rel n as) = Rel n (map f as)
    mapLitTerms f (Eq l r)   = Eq (f l) (f r)
    mapLitTerms _ l          = l
