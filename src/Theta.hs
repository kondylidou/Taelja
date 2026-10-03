-- Theorem 1's grounding substitution θ, which turns the proof tree T into a
-- ground tree Tθ. It agrees with every step's unifier, so it is solved once
-- over the whole tree. The module also follows the rewrites of a nucleus's
-- atoms under θ and checks each hyperresolution step before it is emitted.
module Theta
  ( ThetaCtx (..)
  , thetaContext
  , computeNucleusTheta
  , resolutionCoherent
  , derivedHead
  , literalRewrites
  , headRewrites
  ) where

import Control.Applicative ((<|>))
import Control.Monad (foldM)
import Data.Bifunctor (first)
import Data.List (nub, sortBy)
import Data.Maybe (fromMaybe, isJust, isNothing, listToMaybe, mapMaybe)
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import qualified Data.Text as Text

import Types
import Helpers
import ProofTree (equationRuleNames)
import TptpConvert (convertDeclToClause)

-- θ over one proof tree, by position, with the clause it applies to there. It
-- also records the rewriting positions and how each inference replayed.
data ThetaCtx = ThetaCtx
  { tcRewriteAt :: Set.Set String      -- positions concluded by a rewriting rule (equationRuleNames)
  , tcTheta  :: Map.Map String Subst  -- θ|p at each position
  , tcStatus  :: [(String, String)]     -- how well each inference replayed (see explainStatus)
  , tcClauses :: Map.Map String Clause  -- the clause θ|p applies to at each position
  }

-- Theorem 1's θ'_k, θ restricted to one nucleus in the variables of its
-- abstract clause. Variables only in the head stay free, so the derived
-- electron is as general as the proof allows.
computeNucleusTheta :: ThetaCtx -> LeafEntry -> Subst
computeNucleusTheta ctx entry =
  let θ = Map.findWithDefault [] (lePos entry) (tcTheta ctx)
      headOnly = case convertDeclToClause (leSrcDecl entry) of
        Just (Clause bs (Just h)) -> filter (`notElem` concatMap litVars bs) (litVars h)
        _                          -> []
  in filter (\(v, _) -> v `notElem` headOnly) θ

-- The θ context of a proof tree, with its clauses computed once.
thetaContext :: ProofInfo -> ThetaCtx
thetaContext info = ThetaCtx
  { tcRewriteAt = Map.keysSet (Map.filter ((`elem` equationRuleNames) . Text.pack) (piRuleAt info))
  , tcTheta    = thetaByPosition clauses
  , tcStatus    = explainStatus clauses
  , tcClauses   = clauses
  }
  where clauses = thetaClauses (piDeclAt info) (piNuclei info ++ piElectrons info)

-- The clause θ is solved over at each position. An original axiom uses its
-- source declaration, in whose variables its nucleus is processed, and every
-- other position the clause printed there.
thetaClauses :: Map.Map String T.Declaration -> [LeafEntry] -> Map.Map String Clause
thetaClauses declAt entries = Map.union entryClauses (Map.mapMaybe convertDeclToClause declAt)
  where
    entryClauses = Map.fromList [ (lePos e, c) | e <- entries, Just c <- [convertDeclToClause (if leRole e == OrigAxiom then leSrcDecl e else leDecl e)] ]

-- The rewrites the proof makes to each body atom of the clause at a position
-- before it is resolved, so the electron states the rewritten atom. The atom
-- is followed up the tree under θ, and each equation instance is found by
-- matching, since θ fixes only what resolution binds.
literalRewrites :: ThetaCtx -> String -> [(Literal, [(String, Dir, (Term, Term), Literal)])]
literalRewrites ctx pos = case groundAt ctx pos of
  Just (Clause bs _) -> [ (b, up pos b) | b <- bs ]
  Nothing            -> []
  where
    up p cur
      | null p    = []
      | otherwise = case groundAt ctx q of
          Just (Clause qbs _)
            | any (sameLit cur) qbs -> up q cur
            | Just eq <- equationBeside
            , run@(_ : _) <- rewriteRun cur eq qbs
            -> withEquationPos sib run ++ up q (runResult run)
            -- The literal is gone. If the equation beside it does not state
            -- it, the step rewrote it to t = t, whatever the rule is called.
            -- If it does, the same holds in a rewriting step, while in a
            -- resolution step the equation is the electron.
            | Just (l, r) <- equationBeside
            , isNothing (matchLitEither (Eq l r) cur []) || Set.member q (tcRewriteAt ctx)
            -> withEquationPos sib (closingRun cur (l, r))
          _ -> []
      where
        q   = init p
        sib = sibling p
        equationBeside = headEquationAt ctx sib

-- The rewrites the proof makes to the head of the clause at a position while
-- it still has body atoms, so the derived electron states the rewritten head.
-- They come with the head under θ, where the chain starts. Rewrites after the
-- clause becomes a unit are steps of their own.
headRewrites :: ThetaCtx -> String -> (Maybe Literal, [(String, Dir, (Term, Term), Literal)])
headRewrites ctx pos = case groundAt ctx pos of
  Just (Clause (_ : _) (Just h)) -> (Just h, up pos h)
  _                              -> (Nothing, [])
  where
    up p cur
      | null p    = []
      | otherwise = case groundAt ctx q of
          Just (Clause qbs (Just qh))
            | sameLit cur qh -> if null qbs then [] else up q cur
            | not (null qbs)
            , Just eq <- headEquationAt ctx sib
            , run@(_ : _) <- rewriteRun cur eq [qh]
            -> withEquationPos sib run ++ up q (runResult run)
          _ -> []
      where
        q   = init p
        sib = sibling p

-- The clause at a position under θ.
groundAt :: ThetaCtx -> String -> Maybe Clause
groundAt ctx p = do
  Clause bs mh <- Map.lookup p (tcClauses ctx)
  let s = Map.findWithDefault [] p (tcTheta ctx)
  return (Clause (map (applySubstLit s) bs) (fmap (applySubstLit s) mh))

-- The position of the other premise of the step.
sibling :: String -> String
sibling p = init p ++ [if last p == '0' then '1' else '0']

-- The equation at the head of the clause at a position, also when the clause
-- has a body. E may rewrite with such a head, and the nucleus deriving it
-- comes earlier in the tree, so it is a unit by the time it rewrites.
headEquationAt :: ThetaCtx -> String -> Maybe (Term, Term)
headEquationAt ctx p = case Map.lookup p (tcClauses ctx) of
  Just (Clause _ (Just (Eq l r))) -> Just (l, r)
  _                               -> Nothing

-- Whether two literals are the same up to the orientation of an equation.
sameLit :: Literal -> Literal -> Bool
sameLit x y = x == y || x == flipLit y

-- Each rewrite of a run, with the position of its equation.
withEquationPos :: String -> [(Dir, (Term, Term), Literal)] -> [(String, Dir, (Term, Term), Literal)]
withEquationPos sib run = [ (sib, d, e, c) | (d, e, c) <- run ]

-- The literal a run of rewrites ends with.
runResult :: [(Dir, (Term, Term), Literal)] -> Literal
runResult run = (\(_, _, c) -> c) (last run)

-- The rewrites by l = r that take cur to one of ts in one step. The literals
-- may differ at several places, as when Vampire's superposition rewrites every
-- occurrence, each by an instance matched on both sides since one side may not
-- fix every variable. Results keep cur's orientation.
rewriteRun :: Literal -> (Term, Term) -> [Literal] -> [(Dir, (Term, Term), Literal)]
rewriteRun cur eq ts = fromMaybe [] $ listToMaybe
  [ rewriteAlong d cur ps
  | d <- [LR, RL]
  , t <- ts
  , t' <- nub [t, flipLit t]
  , Just ps@(_ : _) <- [litPlaces (instanceIn d) cur t'] ]
  where
    instanceIn d x y = instanceOfEq eq (case d of { LR -> (x, y); RL -> (y, x) })

-- The rewrites by l = r that turn an equation into t = t, which the step then
-- drops. Wherever its sides differ by an instance of l = r, the side holding
-- the instance of l is rewritten.
closingRun :: Literal -> (Term, Term) -> [(Dir, (Term, Term), Literal)]
closingRun cur@(Eq x y) eq = fromMaybe [] $ do
  ps@(_ : _) <- diffPlaces side x y
  return (rewriteAlong LR cur [ (k : path, e) | (path, (k, e)) <- ps ])
  where
    side u v = ((,) 0 <$> instanceOfEq eq (u, v)) <|> ((,) 1 <$> instanceOfEq eq (v, u))
closingRun _ _ = []

-- The instance of l = r that the two terms are the sides of.
instanceOfEq :: (Term, Term) -> (Term, Term) -> Maybe (Term, Term)
instanceOfEq (l, r) (u, v) = (\σ -> (applySubstTerm σ l, applySubstTerm σ r)) <$> matchLit (Eq l r) (Eq u v)

-- The places where two terms differ, as paths of argument indices. Each place
-- is the outermost point where why explains the difference, and comes with
-- that explanation. Nothing if some difference has no explanation.
diffPlaces :: (Term -> Term -> Maybe a) -> Term -> Term -> Maybe [([Int], a)]
diffPlaces why x y
  | x == y = Just []
  | Just e <- why x y = Just [([], e)]
  | App f xs <- x, App g ys <- y, f == g, length xs == length ys = argPlaces why xs ys
  | otherwise = Nothing

-- diffPlaces over two argument lists, each path starting at its argument index.
argPlaces :: (Term -> Term -> Maybe a) -> [Term] -> [Term] -> Maybe [([Int], a)]
argPlaces why xs ys = concat <$> sequence
  [ map (first (k :)) <$> diffPlaces why x y | (k, x, y) <- zip3 [0 ..] xs ys ]

-- diffPlaces over the arguments of two atoms of one predicate or two equations.
litPlaces :: (Term -> Term -> Maybe a) -> Literal -> Literal -> Maybe [([Int], a)]
litPlaces why (Eq x1 x2) (Eq y1 y2) = argPlaces why [x1, x2] [y1, y2]
litPlaces why (Rel n xs) (Rel m ys) | n == m, length xs == length ys = argPlaces why xs ys
litPlaces _ _ _ = Nothing

-- The literal after each rewrite of a run, one place at a time.
rewriteAlong :: Dir -> Literal -> [([Int], (Term, Term))] -> [(Dir, (Term, Term), Literal)]
rewriteAlong _ _ [] = []
rewriteAlong d lit ((path, e) : rest) = (d, e, lit') : rewriteAlong d lit' rest
  where
    -- a place is a path into the literal read as a term
    lit' = maybe lit (termAsLit lit . putTermAt path new) (litAsTerm lit)
    new = case d of { LR -> snd e; RL -> fst e }

-- θ|p for every position, in the variables of the clause there.
thetaByPosition :: Map.Map String Clause -> Map.Map String Subst
thetaByPosition clauses = Map.mapWithKey thetaAt clauses
  where
    σ = solveAll (map snd (treeInferences clauses))

    -- θ is grounding, so a variable no inference binds becomes a fresh
    -- constant, one per class of identified variables. computeNucleusTheta
    -- exempts head-only variables.
    thetaAt p c =
      [ (v, ground (walkDeep σ (Var (varAt p v))))
      | v <- nub (concatMap (litVars . snd) (polLits c)) ]
    ground (Var x)    = Fresh (map (\ch -> if ch == '@' then '_' else ch) x)
    ground (App f ts) = App f (map ground ts)
    ground t          = t

-- How well each inference replays on its own, the first tier of explainTiers
-- that explains it or "none". Anything but strict is where θ may lose a binding,
-- so check it first when a nucleus fails.
explainStatus :: Map.Map String Clause -> [(String, String)]
explainStatus clauses =
  [ (p, head ([ t | (t, ss) <- explainTiers inf Map.empty, not (null ss) ] ++ ["none"]))
  | (p, inf) <- treeInferences clauses ]

-- The inferences of the tree, root first, each as the literals of its
-- conclusion at p and of its premises at p0 and p1, or p1 alone. Variables
-- are renamed apart by position as v@p.
treeInferences :: Map.Map String Clause -> [(String, ([(Bool, Literal)], [[(Bool, Literal)]]))]
treeInferences clauses =
  [ (p, (litsAt p, map litsAt kids))
  | (p, kids) <- sortBy (comparing (\(p, _) -> (length p, p)))
                   [ (p, kids) | p <- Map.keys clauses
                               , let kids = filter (`Map.member` clauses) [p ++ "0", p ++ "1"]
                               , not (null kids) ] ]
  where
    litsAt p = [ (b, mapLiteralTerms (apart p) l) | (b, l) <- polLits (clauses Map.! p) ]
    apart p (Var v)    = Var (varAt p v)
    apart p (App f ts) = App f (map (apart p) ts)
    apart _ t          = t

-- Variable v renamed apart for position p.
varAt :: String -> String -> String
varAt p v = v ++ "@" ++ p

-- Solves the inferences in order, backtracking over the explanations of each.
-- An inference with no explanation on its own is dropped, so its step fails
-- later instead of the whole search. Without a joint solution nothing is bound.
solveAll :: [([(Bool, Literal)], [[(Bool, Literal)]])] -> TreeSubst
solveAll infs0 = fromMaybe Map.empty (search infs Map.empty)
  where
    infs = filter (not . null . (`explain` Map.empty)) infs0
    search [] s = Just s
    search (inf : rest) s = listToMaybe (mapMaybe (search rest) (explain inf s))

-- The solver's triangular substitution over the variables of the whole tree.
-- Variables are dereferenced by walking the map, since applying an
-- association list to a fixed point is quadratic on large proofs.
type TreeSubst = Map.Map String Term

-- Dereferences a bound variable, but not the arguments of a term.
walk :: TreeSubst -> Term -> Term
walk s t@(Var x) = maybe t (walk s) (Map.lookup x s)
walk _ t         = t

-- Dereferences every variable of a term.
walkDeep :: TreeSubst -> Term -> Term
walkDeep s t = case walk s t of
  App f ts -> App f (map (walkDeep s) ts)
  t'       -> t'

-- Whether variable x occurs in a term under s.
occursIn :: TreeSubst -> String -> Term -> Bool
occursIn s x t = case walk s t of
  Var y    -> x == y
  App _ ts -> any (occursIn s x) ts
  _        -> False

-- Unifies two terms by extending s, with the occurs check.
unifyInTree :: Term -> Term -> TreeSubst -> Maybe TreeSubst
unifyInTree a b s = case (walk s a, walk s b) of
  (Var x, Var y) | x == y -> Just s
  (Var x, t)              -> bind x t
  (t, Var y)              -> bind y t
  (Const c, Const d) | c == d -> Just s
  (Fresh x, Fresh y) | x == y -> Just s
  (App f as, App g bs) | f == g, length as == length bs ->
    foldM (\acc (p, q) -> unifyInTree p q acc) s (zip as bs)
  _ -> Nothing
  where bind x t = if occursIn s x t then Nothing else Just (Map.insert x t s)

-- The substitutions extending s under which the inference holds, from the
-- first tier of explainTiers that has any.
explain :: ([(Bool, Literal)], [[(Bool, Literal)]]) -> TreeSubst -> [TreeSubst]
explain inf s = concat (take 1 [ ss | (_, ss) <- explainTiers inf s, not (null ss) ])

-- The explanations of an inference in three tiers, strict, rewritten and
-- loose, starting with the one that replays it most closely.
explainTiers :: ([(Bool, Literal)], [[(Bool, Literal)]]) -> TreeSubst -> [(String, [TreeSubst])]
explainTiers (parent, kids) s = [("strict", strict), ("rewritten", rewritten), ("loose", loose)]
  where
    -- A prover may fold a rewrite into a step and print one atom unrewritten,
    -- so no replay reproduces the clause. The other literals still fix the
    -- premise's variables, which would otherwise all stay free.
    loose = concat [ coverLoose result parent s1
                   | (pairs, result) <- premiseCombinations kids
                   , Just s1 <- [foldM (\acc (a, b) -> unifyInTree a b acc) s pairs] ]
    strict = [ s2 | (pairs, result) <- premiseCombinations kids
                  , Just s1 <- [foldM (\acc (a, b) -> unifyInTree a b acc) s pairs]
                  , s2 <- cover result parent s1 ]
    -- One premise instantiated and then rewritten by the other, a unit
    -- equation, at a position that was a variable, which no superposition
    -- reaches.
    rewritten = [ s2 | [x, y] <- [kids], (inst, eqk) <- [(x, y), (y, x)]
                     , [(True, Eq a b)] <- [eqk]
                     , (l, r) <- [(a, b), (b, a)]
                     , s2 <- coverRewritten (l, r) inst parent s ]

-- The ways one or two premises combine, each as the term equations the step
-- needs and the literals of its result. Each may also fold in an equality
-- resolution, as E's er does, which removes a body equation s ≈ t by unifying
-- s and t.
premiseCombinations :: [[(Bool, Literal)]] -> [([(Term, Term)], [(Bool, Literal)])]
premiseCombinations kids = concat
  [ (pairs, r) : [ (pairs ++ [(s, t)], rest) | ((False, Eq s t), rest) <- picks r ]
  | (pairs, r) <- base kids ]
  where
    base [a]    = [([], a)]
    -- The last two cover a premise instantiated and then rewritten by the
    -- other at a variable position. The conclusion is still an instance of
    -- that premise, which recovers the instantiation.
    base [a, b] = resolve a b ++ resolve b a ++ superpose a b ++ superpose b a
                  ++ [([], a), ([], b)]
    base _      = []

-- The head literals and the body literals of a signed clause.
heads, bodies :: [(Bool, Literal)] -> [Literal]
heads x  = [ l | (True, l) <- x ]
bodies x = [ l | (False, l) <- x ]

-- x's head against a body atom of y, leaving x's body and the rest of y.
resolve :: [(Bool, Literal)] -> [(Bool, Literal)] -> [([(Term, Term)], [(Bool, Literal)])]
resolve x y =
  [ ([(litTerm h, litTerm b')], [ (False, l) | l <- bodies x ] ++ rest)
  | h <- heads x
  , ((False, b), rest) <- picks y
  , b' <- orientations b ]

-- x's equation head rewrites a non-variable subterm of y, at one occurrence
-- or at every occurrence in the clause.
superpose :: [(Bool, Literal)] -> [(Bool, Literal)] -> [([(Term, Term)], [(Bool, Literal)])]
superpose x y = nub
  [ ([(l, u)], [ (False, m) | m <- bodies x ] ++ y')
  | Eq s t <- heads x
  , (l, r) <- [(s, t), (t, s)]
  , rewritesFrom l r
  , (i, (_, lit)) <- zip [0 :: Int ..] y
  , (u, ctx) <- litSubtermCtxs lit
  , notVar u
  , y' <- [ [ (sign, if j == i then ctx r else m) | (j, (sign, m)) <- zip [0 :: Int ..] y ]
          , [ (sign, mapLiteralTerms (replaceAllTerm u r) m) | (sign, m) <- y ] ] ]

-- The substitutions under which the printed conclusion is the replayed result,
-- up to renaming and dropped duplicate or trivial literals. Each result literal
-- matches a conclusion literal, binding only premise variables, or is a body
-- equation s ≈ t dropped by unifying s and t. Every conclusion literal is hit.
cover :: [(Bool, Literal)] -> [(Bool, Literal)] -> TreeSubst -> [TreeSubst]
cover result parent s0 = go result [] s0
  where
    idxParent = zip [0 :: Int ..] parent
    rigid = rigidVars s0 parent
    go [] hit s
      | all ((`elem` hit) . fst) idxParent = [s]
      | otherwise = []
    go ((sign, l) : ls) hit s =
      [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
            , s' <- matchOriented rigid l p s
            , s'' <- go ls (i : hit) s' ]
      ++ [ s'' | not sign, Eq a b <- [l], Just s' <- [unifyInTree a b s], s'' <- go ls hit s' ]

-- Like cover, but a conclusion literal may be a result literal rewritten once
-- by l -> r, matched after putting the instance of l back. At least one
-- literal must match that way, or cover would have succeeded.
coverRewritten :: (Term, Term) -> [(Bool, Literal)] -> [(Bool, Literal)] -> TreeSubst -> [TreeSubst]
coverRewritten (l, r) result parent s0 = go result [] False s0
  where
    idxParent = zip [0 :: Int ..] parent
    rigid = rigidVars s0 parent
    go [] hit used s
      | used && all ((`elem` hit) . fst) idxParent = [s]
      | otherwise = []
    go ((sign, lit) : ls) hit used s =
      [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
            , s' <- matchOriented rigid lit p s
            , s'' <- go ls (i : hit) used s' ]
      ++ [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
               , (u, ctx) <- litSubtermCtxs p
               , Just s1 <- [matchInTree rigid r u s]
               , s' <- matchOriented rigid lit (ctx (walkDeep s1 l)) s1
               , s'' <- go ls (i : hit) True s' ]

-- The conclusion's variables as instantiated so far, which covering never binds.
rigidVars :: TreeSubst -> [(Bool, Literal)] -> Set.Set String
rigidVars s0 parent = Set.fromList (concatMap (litVars . mapLiteralTerms (walkDeep s0) . snd) parent)

-- The ways a result literal matches a conclusion literal, either way round
-- for an equation.
matchOriented :: Set.Set String -> Literal -> Literal -> TreeSubst -> [TreeSubst]
matchOriented rigid l p s =
  [ s' | l' <- orientations l, Just s' <- [matchInTree rigid (litTerm l') (litTerm p) s] ]

-- Matching under a substitution. Only unbound, non-rigid pattern variables
-- are bound, and the target is never instantiated.
matchInTree :: Set.Set String -> Term -> Term -> TreeSubst -> Maybe TreeSubst
matchInTree rigid = go
  where
    go pat tgt s = case (walk s pat, walk s tgt) of
      (Var x, Var y) | x == y -> Just s
      (Var x, t) | not (Set.member x rigid), not (occursIn s x t) -> Just (Map.insert x t s)
      (Const c, Const d) | c == d -> Just s
      (Fresh x, Fresh y) | x == y -> Just s
      (App f as, App g bs) | f == g, length as == length bs ->
        foldM (\acc (a, b) -> go a b acc) s (zip as bs)
      _ -> Nothing

-- Like cover, but one literal on each side may go unmatched, the one a folded
-- simplification rewrote. The assembled step is still checked by
-- resolutionCoherent and by Lean, so a wrong binding cannot slip through.
coverLoose :: [(Bool, Literal)] -> [(Bool, Literal)] -> TreeSubst -> [TreeSubst]
coverLoose result parent s0 = go result [] False s0
  where
    idxParent = zip [0 :: Int ..] parent
    rigid = rigidVars s0 parent
    go [] hit _ s
      | length [ () | (i, _) <- idxParent, i `notElem` hit ] <= 1 = [s]
      | otherwise = []
    go ((sign, l) : ls) hit skipped s =
      [ s'' | (i, (sign', p)) <- idxParent, sign == sign'
            , s' <- matchOriented rigid l p s
            , s'' <- go ls (i : hit) skipped s' ]
      ++ [ s'' | not skipped, s'' <- go ls hit True s ]

-- A literal and, for an equation, its flip.
orientations :: Literal -> [Literal]
orientations (Eq l r) = [Eq l r, Eq r l]
orientations l        = [l]

-- The head the rule derives from exactly these premise instances, if its body
-- atoms unify with them. A reader and the Lean check derive the same, so an
-- equation is printed in this orientation.
derivedHead :: [Literal] -> Literal -> [Literal] -> Maybe Literal
derivedHead bodyAbs headAbs targets
  | length bodyAbs /= length targets = Nothing
  | otherwise = case foldM stepU Map.empty (zip bodyAbs' targets) of
      Nothing -> Nothing
      Just s  -> Just (mapLiteralTerms (walkDeep s) headAbs')
  where
    ren = suffixVarsLit "_dh"
    bodyAbs' = map ren bodyAbs
    headAbs' = ren headAbs
    stepU s (b, t) = case (litAsTerm b, litAsTerm t) of
      (Just tb, Just tt) -> case unifyInTree tb tt s of
        Just s' -> Just s'
        Nothing -> case t of
          Eq l r -> litAsTerm (Eq r l) >>= \tt' -> unifyInTree tb tt' s
          _      -> Nothing
      _ -> Nothing

-- Checks one assembled hyperresolution step before it is emitted, as the Lean
-- check would. The rule's body atoms must unify with the matched electrons and
-- the derived head must cover the stored instance, so a spurious match cannot
-- justify a head.
resolutionCoherent :: [Literal] -> Literal -> [Literal] -> Literal -> Bool
resolutionCoherent bodyAbs headAbs targets headInst =
  -- a step whose conclusion is one of its own premises is vacuous
  headInst `notElem` targets && case derivedHead bodyAbs headAbs targets of
    Just derived -> derived `notElem` targets
                    && any (\d -> d == headInst || isJust (matchLit d headInst)) (orientations derived)
    Nothing      -> False
