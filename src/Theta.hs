-- Theorem 1's θ, the grounding substitution under which the input proof tree
-- T becomes a ground proof tree Tθ, and the check that validates an assembled
-- hyperresolution step before it is emitted.
--
-- Tθ is a proof tree only if every inference still applies after
-- instantiation, so θ must agree with the unifier of every step.  It is found
-- as one unification problem over the whole tree.  Each clause's variables are
-- renamed apart by position, each inference is replayed from its premises, and
-- the result is unified with the clause the prover printed.  The most general
-- solution is θ up to the variables no step binds.  Those are the theorem's
-- fresh constants, one per class of identified variables.
module Theta
  ( ThetaCtx (..)
  , computeNucleusTheta
  , sharedNodeTheta
  , resolutionCoherent
  , derivedHead
  , explainStatus
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
  , tcStatus  :: [(String, String)]     -- how well each inference replayed (see explainStatus)
  }

-- θ restricted to one nucleus, in the variables of its abstract clause.  This
-- is Theorem 1's θ'_k, where a variable in the head but in no body literal
-- stays free, so the derived electron is as general as the proof allows.
computeNucleusTheta :: ThetaCtx -> LeafEntry -> Subst
computeNucleusTheta ctx entry =
  let θ = Map.findWithDefault [] (lePos entry) (tcShared ctx)
      headOnly = case convertDeclToClause (leSrcDecl entry) of
        Just (Clause bs (Just h)) -> filter (`notElem` concatMap litVars bs) (litVars h)
        _                          -> []
  in filter (\(v, _) -> v `notElem` headOnly) θ

-- The clause a position stands for.  A leaf uses its source axiom, whose
-- variables the nucleus is processed with, and anything else uses the clause
-- printed there.
abstractDecl :: LeafEntry -> T.Declaration
abstractDecl e = if leRole e == OrigAxiom then leSrcDecl e else leDecl e

-- The global θ, computed once per run as θ|p for every position in its own
-- variable names.  A variable no inference binds is left out, unless it was
-- identified with another position's variable, and then both map to one
-- shared rigid variable.
sharedNodeTheta :: Map.Map String T.Declaration -> [LeafEntry] -> Map.Map String Subst
sharedNodeTheta declAt entries = Map.mapWithKey thetaAt clauses
  where
    entryClauses = Map.fromList [ (lePos e, c) | e <- entries, Just c <- [convertDeclToClause (abstractDecl e)] ]
    clauses = Map.union entryClauses (Map.mapMaybe convertDeclToClause declAt)

    -- variables renamed apart by position as v@p
    at p v = v ++ "@" ++ p
    litsAt p = [ (b, mapLiteralTerms (apart p) l) | (b, l) <- polLits (clauses Map.! p) ]
    apart p (Var v)    = Var (at p v)
    apart _ (Const c)  = Const c
    apart p (App f ts) = App f (map (apart p) ts)

    -- inferences root first, where a node's children are p0 and p1, or p1 alone
    nodes = sortBy (comparing (\(p, _) -> (length p, p)))
              [ (p, kids) | p <- Map.keys clauses
                          , let kids = filter (`Map.member` clauses) [p ++ "0", p ++ "1"]
                          , not (null kids) ]

    σ = solveAll [ (litsAt p, map litsAt kids) | (p, kids) <- nodes ]

    -- θ is grounding, so a variable no inference binds becomes a fresh
    -- constant named after its class representative.  computeNucleusTheta
    -- exempts head-only variables.
    thetaAt p c =
      [ (v, ground (walkDeep σ (Var (at p v))))
      | v <- nub (concatMap (litVars . snd) (polLits c)) ]
    ground (Var x)    = Const (rigidPrefix ++ map (\ch -> if ch == '@' then '_' else ch) x)
    ground (Const c)  = Const c
    ground (App f ts) = App f (map ground ts)

-- How well each inference could be replayed.  It is strict when the replay
-- matches the printed conclusion exactly, rewritten when the conclusion is an
-- instance of one premise rewritten by the other, loose when one literal on
-- each side is left over from a simplification the prover folded in, and none when
-- nothing explains it.  Anything but strict is where θ can lose a binding, so
-- check this first when a nucleus fails.
explainStatus :: Map.Map String T.Declaration -> [LeafEntry] -> [(String, String)]
explainStatus declAt entries =
  [ (p, status (litsAt p, map litsAt kids)) | (p, kids) <- nodes ]
  where
    entryClauses = Map.fromList [ (lePos e, c) | e <- entries, Just c <- [convertDeclToClause (abstractDecl e)] ]
    clauses = Map.union entryClauses (Map.mapMaybe convertDeclToClause declAt)
    at p v = v ++ "@" ++ p
    litsAt p = [ (b, mapLiteralTerms (apart p) l) | (b, l) <- polLits (clauses Map.! p) ]
    apart p (Var v)    = Var (at p v)
    apart _ (Const c)  = Const c
    apart p (App f ts) = App f (map (apart p) ts)
    nodes = sortBy (comparing (\(p, _) -> (length p, p)))
              [ (p, kids) | p <- Map.keys clauses
                          , let kids = filter (`Map.member` clauses) [p ++ "0", p ++ "1"]
                          , not (null kids) ]
    status inf = head ([ t | (t, ss) <- explainTiers inf Map.empty, not (null ss) ] ++ ["none"])

polLits :: Clause -> [(Bool, Literal)]
polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]

-- Solve the inferences in order, backtracking over the ways to explain each
-- within a step budget.  Past the budget, or with no joint solution, each keeps
-- its first explanation consistent with the rest.  An inference with no
-- explanation at all is left out up front, so its variables stay free and the
-- step fails honestly later rather than failing the whole search.
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

-- The solver's substitution, with one binding per variable of the whole tree.
-- A variable is dereferenced by walking the map, since applying an
-- association list to a fixed point at every step makes ALG006-1 quadratic.
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

-- Every substitution extending s under which the inference holds, so the
-- premises combine into the printed conclusion up to instantiation and the
-- dropping of trivial or duplicate literals.
explain :: ([(Bool, Literal)], [[(Bool, Literal)]]) -> USubst -> [USubst]
explain inf s = concat (take 1 [ ss | (_, ss) <- explainTiers inf s, not (null ss) ])

-- The explanations of an inference by how closely they reproduce it, the
-- first tier with any being the one used.
explainTiers :: ([(Bool, Literal)], [[(Bool, Literal)]]) -> USubst -> [(String, [USubst])]
explainTiers (parent, kids) s = [("strict", strict), ("rewritten", rewritten), ("loose", loose)]
  where
    -- A prover may fold a rewriting into an inference and print one body
    -- literal in its un-normalized form (Twee on ANA023-2 prints
    -- c_plus(c_0,g,t_b) <= k where the step used g <= k).  Then no replay
    -- reproduces the clause literally.  Rather than leave every variable of
    -- the premise free, the remaining literals are allowed to determine them.
    loose = concat [ coverLoose result parent s1
                   | (pairs, result) <- alternatives kids
                   , Just s1 <- [foldM (\acc (a, b) -> unifyU a b acc) s pairs] ]
    strict = [ s2 | (pairs, result) <- alternatives kids
                  , Just s1 <- [foldM (\acc (a, b) -> unifyU a b acc) s pairs]
                  , s2 <- cover result parent s1 ]
    -- A step that instantiates one premise and rewrites the instance by the
    -- other, a unit equation, at a position that was a variable, as Twee's
    -- rewriting of c31 by c17 on LCL902+1.  No superposition reaches such a
    -- position, and the conclusion is the instance up to that rewrite.
    rewritten = [ s2 | [x, y] <- [kids], (inst, eqk) <- [(x, y), (y, x)]
                     , [(True, Eq a b)] <- [eqk]
                     , (l, r) <- [(a, b), (b, a)]
                     , s2 <- coverRewritten (l, r) inst parent s ]

-- The ways two premises (or one) combine, each as the term equations the
-- step needs and the literals of its result.
alternatives :: [[(Bool, Literal)]] -> [([(Term, Term)], [(Bool, Literal)])]
alternatives kids = concat [ (pairs, r) : [ (pairs ++ ps', r') | (ps', r') <- eqResolve r ] | (pairs, r) <- base kids ]
  where
    base [a]    = [([], a)]
    -- The last two cover a step that instantiates one premise and then rewrites it
    -- by the other.  The rewritten position is still a variable when the
    -- conclusion is matched, so no superposition reaches it.  Treating the
    -- conclusion as an instance of that premise recovers the instantiation.
    base [a, b] = resolve a b ++ resolve b a ++ superpose a b ++ superpose b a
                  ++ [([], a), ([], b)]
    base _      = []

-- An equality resolution folded into a step, as E's er inside csr(er(...)),
-- removes a body equation s ≈ t by unifying s and t.
eqResolve :: [(Bool, Literal)] -> [([(Term, Term)], [(Bool, Literal)])]
eqResolve c = [ ([(s, t)], rest) | ((False, Eq s t), rest) <- picks c ]

heads, bodies :: [(Bool, Literal)] -> [Literal]
heads x  = [ l | (True, l) <- x ]
bodies x = [ l | (False, l) <- x ]

-- x's head against a body literal of y.  What survives is x's body and all of
-- y except the literal resolved away.  picks already keeps y's head in rest,
-- and appending it again would leave a duplicate head the conclusion cannot
-- cover.
resolve :: [(Bool, Literal)] -> [(Bool, Literal)] -> [([(Term, Term)], [(Bool, Literal)])]
resolve x y =
  [ ([(litTerm h, litTerm b')], [ (False, l) | l <- bodies x ] ++ rest)
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

-- The printed conclusion is the replayed result up to renaming and dropped
-- trivial or duplicate literals.  Each result literal matches a conclusion
-- literal of the same polarity, binding only premise variables, or is a body
-- equation s ≈ t dropped with s and t unified.  Every conclusion literal is
-- hit at least once.
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

-- Like cover, but a conclusion literal may be the result literal rewritten
-- once by l -> r, so the result literal matches the conclusion literal with
-- one instance of r put back to the instance of l.  At least one literal is
-- matched that way, since otherwise cover would have succeeded.
coverRewritten :: (Term, Term) -> [(Bool, Literal)] -> [(Bool, Literal)] -> USubst -> [USubst]
coverRewritten (l, r) result parent s0 = go result [] False s0
  where
    idxParent = zip [0 :: Int ..] parent
    rigid = Set.fromList
              (concatMap (litVars . mapLiteralTerms (walkDeep s0) . snd) parent)
    go [] hit used s
      | used && all ((`elem` hit) . fst) idxParent = [s]
      | otherwise = []
    go ((sign, lit) : ls) hit used s =
      [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
            , l' <- orientations lit
            , Just s' <- [matchModulo rigid (litTerm l') (litTerm p) s]
            , s'' <- go ls (i : hit) used s' ]
      ++ [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
               , (u, ctx) <- litSubtermCtxs p
               , Just s1 <- [matchModulo rigid r u s]
               , let p' = ctx (walkDeep s1 l)
               , l' <- orientations lit
               , Just s' <- [matchModulo rigid (litTerm l') (litTerm p') s1]
               , s'' <- go ls (i : hit) True s' ]

-- Matching under a substitution.  Unbound, non-rigid pattern variables may be
-- bound, and the target is never instantiated.
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

-- Like cover, but one literal on each side may go unaccounted for, namely the
-- one the prover rewrote when it folded a simplification in.  In ANA023-2 no
-- replay reproduces such a step, and freeing every premise variable would lose
-- it entirely.  This only widens θ, and the assembled step is still checked by
-- resolutionCoherent and by Lean, so a premise that does not follow fails.
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

-- Validate one assembled hyperresolution step.  The rule's body atoms are
-- unified against the matched electrons, and the step is coherent when that
-- unifier exists and its head covers the instance about to be stored.  This is
-- the judgement the Lean check makes, applied before emitting, so a spurious
-- premise match cannot justify a head.
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
