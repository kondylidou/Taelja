-- Extract all information needed by the algorithm from a flat TSTP unit list.
-- Nodes are assigned bit-string positions: root ⊥ is ε, left child gets suffix
-- "0", right child gets suffix "1".  Leaves at smaller positions are available
-- as electrons for nuclei at larger positions.
module ProofTree
  ( buildProofInfo
  , headLitOf
  , unitNameStr
  , demodRuleNames
  , isPositiveUnitFormula
  , resolveSourceName
  , resolveCopySource
  , isFileSrc
  , lookupDecl
  , isDerivedUnit
  , isOrigAxiomDecl
  ) where
import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Data.List (inits, nub, sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (catMaybes, fromMaybe, isJust, listToMaybe)
import Data.Ord (comparing)
import Types
import Helpers (applySubst, applySubstTerm, deepApplySubstTerm, flipLit, litSubtermCtxs,
                mapLiteralTerms, matchLit, matchLitWith, matchTerms, suffixVarsLit,
                unifyLits, unifyTerms)
import TptpConvert (clauseToDecl, convertDeclToClause)
data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)
maxProofUnits :: Int
maxProofUnits = 2000
-- axHyps: treat a negated_conjecture clause that has a positive literal and
-- is merely a copy of an external or file input as an original axiom.  An
-- implication conjecture negates into its hypotheses plus the negated
-- conclusion; only the all-negative clause is the goal.  Off by default so
-- established outputs are unchanged; the rescue pass enables it.
buildProofInfo :: Bool -> [T.Unit] -> Maybe ProofInfo
buildProofInfo axHyps allUnits
  | length allUnits > maxProofUnits = Nothing
  | otherwise = do
  tree <- buildProofTree allUnits
  let unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      resolve = resolveSourceName unitMap
      -- a chain names the unit that rewrote: a copy resolves to its axiom,
      -- a derived equation keeps its own identity
      chains  = demodChainsForLeaves (resolveCopySource unitMap) tree
      leafRows  = gatherLeaves "" tree
      innerRows = gatherInner  "" tree
      mkLeaf (pos, name, decl) =
        let srcName = if isNegConj decl then name
                      else let r = resolve name
                           -- a definition-derived clause keeps its own (CNF)
                           -- identity; the introduced FOF equivalence behind
                           -- it is not a Horn clause
                           in if isIntroducedSrc unitMap r && r /= name then name else r
            srcDecl = case Map.lookup srcName unitMap of
                        Just (T.Unit _ d _) -> d
                        _                   -> decl
        in LeafEntry
        { lePos     = pos
        , leName    = srcName
        , leDecl    = decl
        , leSrcDecl = srcDecl
        , leRole    = classifyRole axHyps unitMap name decl
        , leSimpl   = fromMaybe [] (Map.lookup pos chains)
        }
      mkInner (pos, name, decl) = LeafEntry
        { lePos     = pos
        , leName    = name
        , leDecl    = decl
        , leSrcDecl = decl   -- inner nodes are already the derived form
        , leRole    = Derived
        , leSimpl   = []
        }
      byPos  = sortBy (comparing lePos)
      lEs    = map mkLeaf  leafRows
      iEs    = map mkInner innerRows
      electrons = byPos $
                    [e | e <- lEs, isPositiveUnitFormula (leDecl e)] ++
                    [e | e <- iEs, isPositiveUnitFormula (leDecl e)]
      nuclei    = byPos $
                    [e | e <- lEs, not (isPositiveUnitFormula (leDecl e))] ++
                    [e | e <- iEs, not (isPositiveUnitFormula (leDecl e))]
  -- prefer the original Conjecture unit: provers may split/simplify before refutation
  -- Without a conjecture unit the goal clause is the negated-conjecture
  -- clause resolved closest to the root: a disjunctive conjecture negates
  -- into several all-negative clauses, and the refutation's root step
  -- determines which one it uses.
  let byDepth = sortBy (comparing (\e -> (length (lePos e), lePos e)))
  goalLits <- fmap (concatMap (unfoldDefinition unitMap)) $ case extractConjectureGoals allUnits of
    Just lits -> Just lits
    Nothing   -> listToMaybe $
      [ lits
      | e <- byDepth [ e' | e' <- nuclei, leRole e' == NegConjecture ]
      , let goalDecl = fromMaybe (leDecl e) (lookupDecl unitMap (leName e))
      , Just lits <- [extractGoalLits goalDecl]
      ] ++
      -- UEQ problems: the negated conjecture is a disequality axiom (no negated_conjecture role)
      [ lits
      | e <- nuclei, leRole e == OrigAxiom
      , Just lits <- [extractGoalLits (leDecl e)]
      ]
  let declAtPos = declByPath tree
      -- every prefix of an entry position, plus the sibling of each prefix
      wanted = Set.toList $ Set.fromList $ concat
        [ p : [ init p ++ [sib] | not (null p), let sib = if last p == '0' then '1' else '0' ]
        | e <- electrons ++ nuclei
        , p <- inits (lePos e) ]
      declMap = Map.fromList [ (p, d) | p <- wanted, Just d <- [declAtPos p] ]
  return ProofInfo
    { piElectrons = electrons
    , piNuclei    = nuclei
    , piGoalLits  = goalLits
    , piDeclAt    = declMap
    }
-- Navigate the memoised tree along a position string; each character is the
-- child index used by gatherLeaves/gatherInner ('0','1',... or '1' for unary).
declByPath :: ProofTree -> String -> Maybe T.Declaration
declByPath t [] = Just (ptDeclOf t)
declByPath (PTLeaf _ _) _ = Nothing
declByPath (PTNode _ _ _ kids) (c : rest) =
  case kids of
    [k]  -> if c == '1' then declByPath k rest else Nothing
    _ -> let i = fromEnum c - fromEnum '0'
         in if i >= 0 && i < length kids then declByPath (kids !! i) rest else Nothing
ptDeclOf :: ProofTree -> T.Declaration
ptDeclOf (PTLeaf _ d)     = d
ptDeclOf (PTNode _ d _ _) = d
buildProofTree :: [T.Unit] -> Maybe ProofTree
buildProofTree allUnits =
  case findRoot allUnits of
    Nothing   -> Nothing
    Just root -> Just (expandMemo root)
  where
    unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
    -- Memoised node table: each TSTP clause is built at most once.
    -- Data.Map.Strict forces each value to WHNF (the outer constructor),
    -- but the children field of PTNode is a lazy thunk — it is not forced
    -- during Map.fromList.  Because TSTP proofs are acyclic DAGs, the
    -- thunks are safe to force later and are evaluated at most once.
    expandedNodes :: Map.Map String ProofTree
    expandedNodes = Map.fromList
      [ (name, buildNode name u)
      | (name, u) <- Map.toList unitMap ]
    expandMemo name = case Map.lookup name expandedNodes of
      Just t  -> t
      Nothing -> PTLeaf name (T.Formula (T.Standard T.Plain)
                   (T.FOF (T.Atomic (T.Predicate (T.Defined (T.Atom (Text.pack name))) []))))
    buildNode name u = case u of
      T.Unit _ decl _ ->
        case coreParentNames u of
          Nothing      -> PTLeaf name decl
          Just parents ->
            let rule = fromMaybe Text.empty (inferenceRuleName u)
            in PTNode name decl rule (orderedChildren decl rule parents)
      _ ->
        PTLeaf name (T.Formula (T.Standard T.Plain)
          (T.FOF (T.Atomic (T.Predicate (T.Defined (T.Atom (Text.pack name))) []))))
    orderedChildren decl rule parents = case parents of
      [p1n, p2n] ->
        let d1 = declOf p1n; d2 = declOf p2n
            (ln, rn) = if firstParentIsLeft rule decl d1 d2
                       then (p1n, p2n) else (p2n, p1n)
        in [expandMemo ln, expandMemo rn]
      (p0:p1:p2:rest) ->
        -- A nested inference (E's cn(rw(spm(A,B),L)), sr(rw(..),..)): the
        -- innermost step resolves p0 with p1, each further parent simplifies
        -- the result by a unit, and the outer node is the last such step.
        -- The intermediate clauses are not printed; they are recomputed here
        -- (synthetic "?" nodes) so that θ is traced through them like
        -- through any other node.  When no replay reproduces the outer
        -- clause the intermediates fall back to the complement of the last
        -- unit for a ⊥ outer node (or the outer clause itself).
        let eqs  = p1:p2:rest
            lastIsProvider = isPositiveUnitFormula (declOf (last eqs))
            fallbackDecl
              | declIsBottom decl, not lastIsProvider
              = fromMaybe decl (posUnitOf (declOf (last eqs)))
              | declIsBottom decl
              = fromMaybe decl (negUnitOf (declOf (last eqs)))
              | otherwise = decl
            replayed = replayNested decl (declOf p0) (map declOf eqs)
            innerDecls = maybe (replicate (length eqs - 1) fallbackDecl) snd replayed
            p0Provides = maybe False fst replayed
            first = PTNode "?" (head innerDecls) rule
                      (if p0Provides then [expandMemo p0, expandMemo p1]
                                     else [expandMemo p1, expandMemo p0])
            inner = foldl (\r (eq, d) -> PTNode "?" d rule [expandMemo eq, r])
                          first (zip (drop 1 (init eqs)) (drop 1 innerDecls))
        in if lastIsProvider
           then [expandMemo (last eqs), inner]
           else [inner, expandMemo (last eqs)]
      _ -> map expandMemo parents
    declOf n = case Map.lookup n unitMap of
      Just (T.Unit _ d _) -> d
      _                   -> T.Formula (T.Standard T.Plain)
                               (T.CNF (T.Clause (pure (T.Positive,
                                 T.Predicate (T.Defined (T.Atom (Text.pack "unknown"))) []))))
-- Flip a unit negation to its positive form, used to infer the declaration of
-- a synthetic "?" intermediate node in inline refutation steps (e.g. E's sr(spm(A,B), ~L)).
posUnitOf :: T.Declaration -> Maybe T.Declaration
posUnitOf (T.Formula _ (T.CNF (T.Clause lits))) =
  case toList lits of
    [(T.Negative, lit)] ->
      Just (T.Formula (T.Standard T.Plain) (T.CNF (T.Clause (pure (T.Positive, lit)))))
    _ -> Nothing
posUnitOf _ = Nothing
-- Replay a nested inference: resolve (or superpose) c0 with c1, simplify
-- the result by each further unit in turn, and accept the replay whose
-- final clause is a variant of the outer clause.  Returns whether c0 is the
-- provider of the first step (its head was consumed) and the intermediate
-- clauses, innermost first, as declarations.
replayNested :: T.Declaration -> T.Declaration -> [T.Declaration] -> Maybe (Bool, [T.Declaration])
replayNested outerD d0 ds = do
  outer <- convertDeclToClause outerD
  c0    <- convertDeclToClause d0
  cs    <- mapM convertDeclToClause ds
  (c1, units) <- case cs of { (x : xs) -> Just (x, xs); [] -> Nothing }
  listToMaybe
    [ (prov, map (clauseToDecl . instC σ) chain)
    | (prov, r) <- resolvents c0 c1
    , chain <- chains r (init units)
    , final <- simplifyBy (last chain) (last units)
    , Just σ <- [matchClause final outer] ]
  where
    chains r []       = [[r]]
    chains r (u : us) = [ r : rest | r' <- simplifyBy r u, rest <- chains r' us ]
    instC σ (Clause bs mh) = Clause (map (inst σ) bs) (fmap (inst σ) mh)
    inst σ = mapLiteralTerms (deepApplySubstTerm σ)
-- Every resolvent and superposition of two clauses (variables renamed
-- apart), tagged with whether the first clause's head was the one used.
resolvents :: Clause -> Clause -> [(Bool, Clause)]
resolvents a b =
  [ (True, r) | r <- headInto a b' ] ++ [ (False, r) | r <- headInto b' a ]
  where
    b' = Clause (map (suffixVarsLit "_q") (body b)) (fmap (suffixVarsLit "_q") (hd b))
    headInto x y = case hd x of
      Nothing -> []
      Just h  ->
        -- resolution: the head against a body literal
        [ mk σ (body x ++ rest) (hd y)
        | (l, rest) <- picks (body y), Just σ <- [unifyLits h l []] ]
        -- superposition: an equation head into a subterm of any literal
        ++ [ mk σ (body x ++ bodyY') hdY'
           | Eq s t <- [h], (lhs, rhs) <- [(s, t), (t, s)], notVar lhs
           , (i, lit) <- zip [0 :: Int ..] (polLits y)
           , (u, ctx) <- litSubtermCtxs (snd lit), notVar u
           , Just σ <- [unifyTerms lhs u []]
           , let lit' = ctx rhs
                 ys   = [ if j == i then (fst l, lit') else l | (j, l) <- zip [0 ..] (polLits y) ]
                 bodyY' = [ l | (False, l) <- ys ]
                 hdY'   = listToMaybe [ l | (True, l) <- ys ] ]
    mk σ bs mh = Clause (map (deep σ) bs) (fmap (deep σ) mh)
    deep σ = mapLiteralTerms (deepApplySubstTerm σ)
    polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]
    notVar (Var _) = False
    notVar _       = True
-- One simplification step, as E's rw/sr/csr/cn perform it: a clause with a
-- head resolves away a body literal (contextual simplify-reflect brings its
-- own conditions along, which then merge with the clause's) or, as a unit
-- equation, rewrites in either orientation; a negative unit ~L removes a
-- head that is an instance of L.  Trivial body equations and duplicate
-- literals are dropped afterwards.
simplifyBy :: Clause -> Clause -> [Clause]
simplifyBy c u@(Clause _ (Just _)) =
  map cn $
    [ Clause (map (deep σ) (body u' ++ rest)) (fmap (deep σ) (hd c))
    | Just h <- [hd u'], (l, rest) <- picks (body c), Just σ <- [unifyLits h l []] ]
    ++ [ c' | Clause [] (Just (Eq s t)) <- [u']
            , (lhs, rhs) <- [(s, t), (t, s)], notVarTerm lhs
            , c' <- rewriteOnce (lhs, rhs) c ]
  where
    u' = Clause (map (suffixVarsLit "_u") (body u)) (fmap (suffixVarsLit "_u") (hd u))
    deep σ = mapLiteralTerms (deepApplySubstTerm σ)
simplifyBy c (Clause [l] Nothing) =
  [ Clause (body c) Nothing
  | Just h <- [hd c], isJust (matchLit l h) || isJust (matchLit (flipLit l) h) ]
simplifyBy _ _ = []
-- One demodulation step: the equation is applied to a single redex, either at
-- that one occurrence or at every occurrence of the same subterm.  A prover
-- records each application as its own rw inference, so a step is never a
-- normalisation to a fixed point.  Modelling it this way needs no orientation
-- condition, so a permutative equation such as u(X,X,Y) = u(Y,X,X) stays
-- usable, and nothing is iterated so nothing can diverge.
rewriteOnce :: (Term, Term) -> Clause -> [Clause]
rewriteOnce (lhs, rhs) (Clause bs mh) =
  [ Clause [ l | (False, l) <- ls' ] (listToMaybe [ l | (True, l) <- ls' ])
  | let ls = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]
  , (i, (_, lit)) <- zip [0 :: Int ..] ls
  , (u, ctx) <- litSubtermCtxs lit
  , notVarTerm u
  , Just s <- [matchTerms lhs u]
  , let r = applySubstTerm s rhs
  , ls' <- [ [ if j == i then (sg, ctx r) else (sg, m) | (j, (sg, m)) <- zip [0 :: Int ..] ls ]
           , [ (sg, mapLiteralTerms (replaceAll u r) m) | (sg, m) <- ls ] ] ]
  where
    replaceAll u r t | t == u = r
    replaceAll u r (App f ts) = App f (map (replaceAll u r) ts)
    replaceAll _ _ t          = t
notVarTerm :: Term -> Bool
notVarTerm (Var _) = False
notVarTerm _       = True
cn :: Clause -> Clause
cn (Clause bs mh) = Clause (nub [ l | l <- bs, not (trivial l) ]) mh
  where
    trivial (Eq s t) = s == t
    trivial _        = False
-- The substitution under which the replayed clause becomes the clause the
-- prover printed: every replayed literal is matched onto a printed literal
-- of the same polarity (equations in either orientation) and every printed
-- literal is hit.  Two replayed literals may land on the same printed one,
-- which is how a duplicate condition merges (E's csr brings the
-- simplifier's own conditions along, and they merge with conditions the
-- clause already carries).  Only the replayed clause is instantiated.
matchClause :: Clause -> Clause -> Maybe Subst
matchClause final outer
  | isJust (hd final) /= isJust (hd outer) = Nothing
  | otherwise = listToMaybe (go (polLits final') [] [])
  where
    ren = suffixVarsLit "_f"
    final' = Clause (map ren (body final)) (fmap ren (hd final))
    polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]
    idxOuter = zip [0 :: Int ..] (polLits outer)
    go [] hit s
      | all ((`elem` hit) . fst) idxOuter = [s]
      | otherwise = []
    go ((b, l) : ls) hit s =
      [ s'' | (i, (b', p)) <- idxOuter, b == b'
            , s' <- catMaybes [matchLitWith l p s, matchLitWith (flipLit l) p s]
            , s'' <- go ls (i : hit) s' ]
picks :: [a] -> [(a, [a])]
picks xs = [ (x, take i xs ++ drop (i + 1) xs) | (i, x) <- zip [0 ..] xs ]
-- The converse for a positive non-equational unit (an equation closed by
-- rewriting leaves the intermediate's shape open, so it stays as is).
negUnitOf :: T.Declaration -> Maybe T.Declaration
negUnitOf (T.Formula _ (T.CNF (T.Clause lits))) =
  case toList lits of
    [(T.Positive, lit@(T.Predicate (T.Defined _) _))] ->
      Just (T.Formula (T.Standard T.Plain) (T.CNF (T.Clause (pure (T.Negative, lit)))))
    _ -> Nothing
negUnitOf _ = Nothing
-- Gather leaves with two-level deduplication, to keep traversal of the
-- (DAG-shared, memoised) proof tree O(N):
--  seenElec  – names of positive-unit (electron) leaves already recorded, so
--              each is kept once, at its first/shallowest DFS position.
--  seenInner – inner-node name -> its non-unit leaves from their first
--              traversal, as (relative_pos, name, decl). A second encounter
--              of the same PTNode re-emits them at new_pos ++ relative_pos
--              instead of re-traversing the subtree. Electron leaves are
--              never re-emitted (seenElec already dedups them globally);
--              non-unit leaves (rule clauses) DO reappear at every distinct
--              position, since each occurrence is a separate rule
--              application that may see different available electrons.
gatherLeaves :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherLeaves pos0 tree0 =
    let (_, _, res) = go pos0 tree0 Set.empty Map.empty in res
  where
    -- seenElec  :: Set String
    -- seenInner :: Map String [(String, String, T.Declaration)]
    --              inner-name → [(rel_pos, leaf_name, leaf_decl)]  (non-unit only)
    go pos (PTLeaf n d) seenElec seenInner
      | isPositiveUnitFormula d =
          if Set.member n seenElec
            then (seenElec, seenInner, [])
            else (Set.insert n seenElec, seenInner, [(pos, n, d)])
      | otherwise = (seenElec, seenInner, [(pos, n, d)])
    go pos (PTNode n _ _ kids) seenElec seenInner
      | n /= "?" =
          case Map.lookup n seenInner of
            Just stored ->
              -- Re-emit stored non-unit leaves at the current absolute position.
              let reemit = [(pos ++ rel, nm, d) | (rel, nm, d) <- stored]
              in (seenElec, seenInner, reemit)
            Nothing ->
              let (se', si', res) = goKids pos kids seenElec seenInner
                  -- Store only non-unit leaves, using relative positions.
                  nucleiEntries =
                    [(drop (length pos) p, nm, d)
                    | (p, nm, d) <- res, not (isPositiveUnitFormula d)]
                  si'' = Map.insert n nucleiEntries si'
              in (se', si'', res)
      | otherwise = goKids pos kids seenElec seenInner
    goKids pos [k] seenElec seenInner =
      go (pos ++ "1") k seenElec seenInner
    goKids pos [l, r] seenElec seenInner =
      let (se',  si',  ls) = go (pos ++ "0") l seenElec seenInner
          (se'', si'', rs) = go (pos ++ "1") r se' si'
      in (se'', si'', ls ++ rs)
    goKids pos kids seenElec seenInner =
      foldl (\(se, si, acc) (c, kid) ->
               let (se', si', r) = go (pos ++ [c]) kid se si
               in (se', si', acc ++ r))
            (seenElec, seenInner, []) (zip ['0'..] kids)
-- Gather inner nodes, recording each distinct TSTP clause name at most once.
-- Synthetic nodes (name "?") are always included since they are distinct objects.
gatherInner :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherInner pos0 tree0 = snd (go pos0 tree0 Set.empty)
  where
    go _   (PTLeaf _ _) seen = (seen, [])
    go pos (PTNode n d rule [k]) seen =
      let (seen', ks)       = go (pos ++ "1") k seen
          (seen'', inner)   = addNode pos n d rule seen'
      in  (seen'', ks ++ inner)
    go pos (PTNode n d rule [l,r]) seen =
      let (seen',  ls)      = go (pos ++ "0") l seen
          (seen'', rs)      = go (pos ++ "1") r seen'
          (seen''', inner)  = addNode pos n d rule seen''
      in  (seen''', ls ++ rs ++ inner)
    go pos (PTNode n d rule kids) seen =
      let (seen', kidsRes) =
            foldl (\(s, acc) (c, kid) ->
                     let (s', res) = go (pos ++ [c]) kid s
                     in  (s', acc ++ res))
                  (seen, []) (zip ['0'..] kids)
          (seen'', inner) = addNode pos n d rule seen'
      in  (seen'', kidsRes ++ inner)
    addNode pos n d rule seen
      | rule == Text.pack "proved_conjecture" = (seen, [])
      | n == "?"               = (seen, [(pos, n, d)])   -- synthetic: always include
      | Set.member n seen      = (seen, [])
      | otherwise              = (Set.insert n seen, [(pos, n, d)])
classifyRole :: Bool -> Map.Map String T.Unit -> String -> T.Declaration -> LeafRole
classifyRole axHyps unitMap name decl
  -- positive-unit file clauses are axioms even if labeled negated_conjecture
  -- (Vampire's "prove the negation" mode does this for all input clauses)
  | isPositiveUnitFormula decl && isFileSrc unitMap name     = OrigAxiom
  | isPositiveUnitFormula decl && isFileSrc unitMap resolvedNm = OrigAxiom
  -- hypothesis clause of a negated implication conjecture (see buildProofInfo)
  | axHyps && isNegConj decl && isJust (headLitOf decl)
  , let cs = resolveCopySource unitMap name
  , Map.notMember cs unitMap || isFileSrc unitMap cs         = OrigAxiom
  | isNegConj decl                                           = NegConjecture
  | maybe False isNegConj (lookupDecl unitMap resolvedNm)    = NegConjecture
  -- A clause whose source traces back to a file-sourced *conjecture* is part
  -- of the negation chain (e.g. FOF clausification: plain → clausify → negate_conjecture → conjecture)
  | maybe False isConjDecl (lookupDecl unitMap resolvedNm)   = NegConjecture
  | isFileSrc unitMap name                                    = OrigAxiom
  | isFileSrc unitMap resolvedNm                              = OrigAxiom
  -- clauses derived from prover-introduced definitions (E's epredN
  -- equivalences, annotation "introduced(definition)") are axioms of the
  -- clausified presentation; their own CNF is the axiom statement
  | isIntroducedSrc unitMap resolvedNm                        = OrigAxiom
  | otherwise                                                 = Derived
  where
    resolvedNm = resolveSourceName unitMap name
    isConjDecl (T.Formula (T.Standard T.Conjecture) _) = True
    isConjDecl _                                        = False
isNegConj :: T.Declaration -> Bool
isNegConj (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegConj _                                              = False
-- A unit the prover introduced itself (E: introduced(definition)).
isIntroducedSrc :: Map.Map String T.Unit -> String -> Bool
isIntroducedSrc unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ _ (Just (T.Introduced _ _, _))) -> True
  _                                              -> False
isFileSrc :: Map.Map String T.Unit -> String -> Bool
isFileSrc unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ _ (Just (T.File _ _, _))) -> True
  _                                         -> False
lookupDecl :: Map.Map String T.Unit -> String -> Maybe T.Declaration
lookupDecl unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ d _) -> Just d
  _                   -> Nothing
-- Trace back only through copy-like steps (bare unit references and
-- single-parent preprocessing inferences such as fof_simplification or
-- cnf_transformation).  Unlike resolveSourceName, a genuine inference such as
-- resolution is a stopping point: its conclusion is a new clause, not a copy
-- of its first parent.  Used to decide whether a derived clause is merely a
-- renamed axiom (and therefore not a lemma candidate).
resolveCopySource :: Map.Map String T.Unit -> String -> String
resolveCopySource unitMap = go
  where
    go name = case Map.lookup name unitMap of
      Just (T.Unit _ _ (Just (T.UnitSource parentName, _))) ->
        go (unitNameStr parentName)
      Just (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ [p], _)))
        | not (Set.member rule coreInferenceNames)
        , rule /= Text.pack "negated_conjecture"
        , [pn] <- flatParents p
        -> go pn
      _ -> name
    flatParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    flatParents (T.Parent (T.Inference _ _ ps) _) = concatMap flatParents ps
    flatParents _                                  = []
-- trace back to the original file-sourced unit; stop at negated_conjecture inferences
-- and at Twee's rewriting steps (which create new equations by completion, not demodulate existing ones)
resolveSourceName :: Map.Map String T.Unit -> String -> String
resolveSourceName unitMap = go
  where
    go name = case Map.lookup name unitMap of
      -- trace through bare UnitSource references (E copies axioms this way)
      Just (T.Unit _ _ (Just (T.UnitSource parentName, _))) ->
        go (unitNameStr parentName)
      Just (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ parents, _)))
        | rule /= Text.pack "negated_conjecture"
        , rule /= Text.pack "rewriting"        -- Twee: creates new eqs, don't trace back
        , rule /= Text.pack "proved_conjecture" -- Twee: terminal step
        ->
            case concatMap flatParents parents of
              (p:_) -> go p
              []    -> name
      Just (T.Unit n _ _) -> unitNameStr n
      Just _               -> name
      Nothing              -> name
    flatParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    flatParents (T.Parent (T.Inference _ _ ps) _) = concatMap flatParents ps
    flatParents _                                  = []
extractGoalLits :: T.Declaration -> Maybe [T.Literal]
extractGoalLits (T.Formula _ (T.CNF (T.Clause lits))) = case toList lits of
  [(T.Negative, lit)]                       -> Just [lit]
  [(T.Positive, T.Equality l T.Negative r)] -> Just [T.Equality l T.Positive r]
  ls | all ((== T.Negative) . fst) ls      -> Just (map snd ls)
  _                                         -> Nothing
extractGoalLits (T.Formula _ (T.FOF f)) = extractFOF f
  where
    extractFOF (T.Quantified T.Forall _ body)          = extractFOF body
    extractFOF (T.Negated body)                        = extractConj body
    extractFOF (T.Atomic (T.Equality l T.Negative r)) = Just [T.Equality l T.Positive r]
    -- A clause with a positive literal is a hypothesis (Vampire labels every
    -- input clause negated_conjecture when it proves the negation), never a
    -- goal source; only an all-negative clause states negated goals, as in
    -- the CNF case above.  Uses its own local pos/neg scan (rather than the
    -- shared posLitsOfDisjFOF/negLitsOfDisjFOF) because a disequality atom
    -- (s != t) must count as negative here: those two are also relied on by
    -- headLitOf's general Horn-clause path, and correcting their classification
    -- of disequalities there changes which premise-matching path the search
    -- takes elsewhere (verified by golden regression), which is out of scope
    -- for a goal-clause check.
    extractFOF g =
      let posLits = goalPosLits g
          negLits = goalNegLits g
      in if null posLits && not (null negLits) then Just negLits else Nothing
    goalPosLits (T.Atomic (T.Equality _ T.Negative _)) = []
    goalPosLits (T.Atomic lit)                         = [lit]
    goalPosLits (T.Negated _)                          = []
    goalPosLits (T.Connected l T.Disjunction r)        = goalPosLits l ++ goalPosLits r
    goalPosLits _                                      = []
    goalNegLits (T.Negated (T.Atomic lit))             = [lit]
    goalNegLits (T.Atomic (T.Equality l T.Negative r)) = [T.Equality l T.Positive r]
    goalNegLits (T.Atomic _)                           = []
    goalNegLits (T.Connected l T.Disjunction r)        = goalNegLits l ++ goalNegLits r
    goalNegLits _                                      = []
    extractConj (T.Atomic lit)                   = Just [lit]
    extractConj (T.Connected l T.Conjunction r)  = do
      ls <- extractConj l
      rs <- extractConj r
      return (ls ++ rs)
    extractConj _                                = Nothing
extractGoalLits _ = Nothing
-- A goal atom that the prover introduced as an abbreviation (E's definitional
-- predicates: "~epred <=> ! [X] : ~E(f(X),0)", introduced(definition)) stands
-- for the atom it abbreviates; the reader's goal is that atom.  Atoms
-- without such a definition are returned unchanged.
unfoldDefinition :: Map.Map String T.Unit -> T.Literal -> [T.Literal]
unfoldDefinition unitMap lit@(T.Predicate (T.Defined (T.Atom pname)) []) =
  case [ body | T.Unit _ (T.Formula _ (T.FOF f)) (Just (T.Introduced _ _, _)) <- Map.elems unitMap
              , Just body <- [definitionBody f] ] of
    (body : _) -> body
    []         -> [lit]
  where
    isAtom (T.Atomic (T.Predicate (T.Defined (T.Atom n)) [])) = n == pname
    isAtom _ = False
    -- "p <=> phi" or "~p <=> ~phi" (quantifiers stripped): the atoms of phi
    definitionBody (T.Connected l T.Equivalence r)
      | isAtom l = atomsOf r
      | isAtom r = atomsOf l
      | T.Negated l' <- l, isAtom l' = atomsOf (negatedOf r)
      | T.Negated r' <- r, isAtom r' = atomsOf (negatedOf l)
    definitionBody (T.Quantified _ _ body) = definitionBody body
    definitionBody _ = Nothing
    negatedOf (T.Quantified q vs body) = T.Quantified q vs (negatedOf body)
    negatedOf (T.Negated body)         = body
    negatedOf body                     = T.Negated body
    atomsOf (T.Quantified _ _ body) = atomsOf body
    atomsOf (T.Atomic a)            = Just [a]
    atomsOf (T.Connected l T.Conjunction r) = (++) <$> atomsOf l <*> atomsOf r
    atomsOf _ = Nothing
unfoldDefinition _ lit = [lit]
-- more reliable than NegConjecture entry: E may split/simplify before refutation
extractConjectureGoals :: [T.Unit] -> Maybe [T.Literal]
extractConjectureGoals units = listToMaybe
  [ lits
  | T.Unit _ decl _ <- units
  , isConjDecl decl
  , Just lits <- [extractConjLits decl]
  ]
  where
    isConjDecl (T.Formula (T.Standard T.Conjecture) _) = True
    isConjDecl _                                        = False
    -- Twee emits the conjecture as a CNF clause with a single positive literal
    extractConjLits (T.Formula _ (T.CNF (T.Clause lits))) =
      case toList lits of
        [(T.Positive, lit)] -> Just [lit]
        _                   -> Nothing
    extractConjLits (T.Formula _ (T.FOF f)) = extractFOFConj f
    extractConjLits _                        = Nothing
    extractFOFConj (T.Quantified T.Forall _ body) = extractFOFConj body
    extractFOFConj (T.Atomic lit)                  = Just [lit]
    extractFOFConj (T.Connected l T.Conjunction r) = do
      ls <- extractFOFConj l
      rs <- extractFOFConj r
      return (ls ++ rs)
    extractFOFConj _                               = Nothing
-- for each PTLeaf position, the chain of demod steps before it was consumed;
-- outermost step listed first
demodChainsForLeaves
  :: (String -> String)
  -> ProofTree
  -> Map.Map String [(String, Dir)]
demodChainsForLeaves resolveName tree0 =
    let (_, _, m) = go "" tree0 Set.empty Set.empty in m
  where
    go pos (PTLeaf n d) seenElec seenInner
      | isPositiveUnitFormula d =
          if Set.member n seenElec
            then (seenElec, seenInner, Map.empty)
            else (Set.insert n seenElec, seenInner, Map.singleton pos [])
      | otherwise = (seenElec, seenInner, Map.singleton pos [])
    go pos (PTNode n _ rule [l, r]) seenElec seenInner
      | n /= "?" && Set.member n seenInner = (seenElec, seenInner, Map.empty)
      | isDemodRule rule && isDemodApplicationTo rule r =
          let eqName = resolveName (treeName l)
              dir    = if rule `elem` map Text.pack
                            ["forward_demodulation", "rw", "definition_unfolding"]
                       then LR else RL
              (se',  si',  lMap) = go (pos ++ "0") l seenElec seenInner
              (se'', si'', rMap) = go (pos ++ "1") r se' si'
              si''' = if n /= "?" then Set.insert n si'' else si''
          in  (se'', si''', Map.union lMap (Map.map ((eqName, dir) :) rMap))
      | otherwise =
          let (se',  si',  lMap) = go (pos ++ "0") l seenElec seenInner
              (se'', si'', rMap) = go (pos ++ "1") r se' si'
              si''' = if n /= "?" then Set.insert n si'' else si''
          in  (se'', si''', Map.union lMap rMap)
    go pos (PTNode n _ _ [k]) seenElec seenInner
      | n /= "?" && Set.member n seenInner = (seenElec, seenInner, Map.empty)
      | otherwise =
          let (se', si', m) = go (pos ++ "1") k seenElec seenInner
              si'' = if n /= "?" then Set.insert n si' else si'
          in (se', si'', m)
    go pos (PTNode n _ _ kids) seenElec seenInner
      | n /= "?" && Set.member n seenInner = (seenElec, seenInner, Map.empty)
      | otherwise =
          let (se', si', m) =
                foldl (\(se, si, acc) (c, kid) ->
                         let (se2, si2, km) = go (pos ++ [c]) kid se si
                         in (se2, si2, Map.union acc km))
                      (seenElec, seenInner, Map.empty) (zip ['0'..] kids)
              si'' = if n /= "?" then Set.insert n si' else si'
          in (se', si'', m)
    -- definition_unfolding has three uses; only track it when rewriting a predicate unit.
    isDemodApplicationTo rule r
      | rule == Text.pack "definition_unfolding" =
          case headLitOf (ptDecl r) of
            Just (T.Equality {}) -> False  -- transitivity chain
            Just _               -> True   -- predicate unit rewrite
            Nothing              -> False  -- non-unit nucleus
      | otherwise = True
    ptDecl (PTLeaf _ d)     = d
    ptDecl (PTNode _ d _ _) = d
    isDemodRule r = Set.member r demodRuleNames
    treeName (PTLeaf n _)     = n
    treeName (PTNode n _ _ _) = n
demodRuleNames :: Set.Set Text.Text
demodRuleNames = Set.fromList $ map Text.pack
  [ "forward_demodulation", "backward_demodulation"
  , "rw", "definition_unfolding" ]
  -- Note: Twee's "rewriting" is NOT here — it creates new equations (not demodulation)
unitNameStr :: T.UnitName -> String
unitNameStr (Left (T.Atom t)) = Text.unpack t
unitNameStr (Right n)         = show n
coreInferenceNames :: Set.Set Text.Text
coreInferenceNames = Set.fromList $ map Text.pack
  [ "resolution", "superposition", "paramodulation"
  , "equality_resolution", "equality_factoring"
  , "forward_subsumption_resolution", "backward_subsumption_resolution"
  , "factoring", "condensation"
  , "definition_unfolding", "trivial_inequality_removal"
  , "forward_demodulation", "backward_demodulation"
  , "duplicate_literal_removal", "subsumption_resolution"
  , "spm", "sr", "csr", "er", "ef", "rw", "cn", "pm"
  , "proved_conjecture"
  , "rewriting" ]  -- Twee: creates new equations by rewriting; expands into proof tree
coreParentNames :: T.Unit -> Maybe [String]
coreParentNames (T.Unit _ decl (Just (T.Inference (T.Atom rule) _ parents, _)))
  | Set.member rule coreInferenceNames = Just (concatMap extractName parents)
  | isPredicateRewriting rule decl     = Just (concatMap extractName parents)
  where
    extractName (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    extractName (T.Parent (T.Inference _ _ ps) _) = concatMap extractName ps
    extractName (T.Parent _ _)                    = []  -- unknown source: skip
    isPredicateRewriting r d
      | r == Text.pack "rewriting" = case headLitOf d of
          Just (T.Equality {}) -> False
          Just _               -> True
          Nothing              -> False
      | otherwise = False
coreParentNames _ = Nothing
inferenceRuleName :: T.Unit -> Maybe Text.Text
inferenceRuleName (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ _, _))) = Just rule
inferenceRuleName _ = Nothing
isFalsum :: T.Clause -> Bool
isFalsum (T.Clause lits) = case toList lits of
  [(T.Positive, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])] -> True
  _ -> False
declIsBottom :: T.Declaration -> Bool
declIsBottom (T.Formula _ (T.CNF cl)) = isFalsum cl
declIsBottom (T.Formula _ (T.FOF (T.Atomic
  (T.Predicate (T.Reserved (T.Standard T.Falsum)) [])))) = True
declIsBottom (T.Formula _ (T.FOF (T.Negated (T.Atomic
  (T.Predicate (T.Reserved (T.Standard T.Tautology)) []))))) = True
declIsBottom _ = False
findRoot :: [T.Unit] -> Maybe String
findRoot units =
  case [unitNameStr n | T.Unit n decl _ <- units, declIsBottom decl] of
    [] -> Nothing
    rs -> Just (last rs)
isPositiveUnitFormula :: T.Declaration -> Bool
isPositiveUnitFormula (T.Formula _ (T.FOF f))  = isPosAtomFOF f
isPositiveUnitFormula (T.Formula _ (T.CNF cl)) = isPosAtomCNF cl
isPositiveUnitFormula _                        = False
isPosAtomFOF :: T.UnsortedFirstOrder -> Bool
isPosAtomFOF (T.Quantified T.Forall _ body)           = isPosAtomFOF body
isPosAtomFOF (T.Atomic (T.Equality _ T.Positive _))   = True
isPosAtomFOF (T.Atomic (T.Predicate (T.Defined _) _)) = True
isPosAtomFOF _                                         = False
isPosAtomCNF :: T.Clause -> Bool
isPosAtomCNF (T.Clause lits) = case toList lits of
  [(T.Positive, T.Equality _ T.Positive _)]   -> True
  [(T.Positive, T.Predicate (T.Defined _) _)] -> True
  _                                           -> False
headLitOf :: T.Declaration -> Maybe T.Literal
headLitOf (T.Formula _ (T.CNF (T.Clause lits))) =
  case [l | (T.Positive, l) <- toList lits] of
    [l] -> Just l
    _   -> Nothing
headLitOf (T.Formula _ (T.FOF f)) = headLitOfFOF f
headLitOf _ = Nothing
headLitOfFOF :: T.UnsortedFirstOrder -> Maybe T.Literal
headLitOfFOF (T.Quantified T.Forall _ body)               = headLitOfFOF body
headLitOfFOF (T.Atomic lit)                               = Just lit
headLitOfFOF (T.Connected _ T.Implication (T.Atomic lit)) = Just lit
headLitOfFOF f = case posLitsOfDisjFOF f of
  [lit] -> Just lit
  _     -> Nothing
posLitsOfDisjFOF :: T.UnsortedFirstOrder -> [T.Literal]
posLitsOfDisjFOF (T.Atomic lit)                   = [lit]
posLitsOfDisjFOF (T.Negated _)                    = []
posLitsOfDisjFOF (T.Connected l T.Disjunction r)  =
  posLitsOfDisjFOF l ++ posLitsOfDisjFOF r
posLitsOfDisjFOF _                                = []
headInDecl :: T.Literal -> T.Declaration -> Bool
headInDecl needle (T.Formula _ (T.CNF (T.Clause lits))) =
  any (litSameHead needle) [l | (T.Positive, l) <- toList lits]
headInDecl needle (T.Formula _ (T.FOF f)) = headInFOF needle f
headInDecl _ _ = False
headInFOF :: T.Literal -> T.UnsortedFirstOrder -> Bool
headInFOF needle (T.Quantified T.Forall _ body)    = headInFOF needle body
headInFOF needle (T.Atomic lit)                    = litSameHead needle lit
headInFOF needle (T.Connected _ T.Implication r)   = headInFOF needle r
headInFOF needle (T.Connected l _ r)               =
  headInFOF needle l || headInFOF needle r
headInFOF _ _                                      = False
litSameHead :: T.Literal -> T.Literal -> Bool
litSameHead (T.Predicate n1 _) (T.Predicate n2 _) = n1 == n2
litSameHead (T.Equality {})    (T.Equality {})     = True
litSameHead _ _                                    = False
superpositionRules :: Set.Set Text.Text
superpositionRules = Set.fromList $ map Text.pack
  [ "superposition", "paramodulation", "spm"
  , "forward_demodulation", "backward_demodulation" ]
firstParentIsLeft :: Text.Text -> T.Declaration -> T.Declaration -> T.Declaration -> Bool
firstParentIsLeft rule _ _ _
  | Set.member rule superpositionRules = False
firstParentIsLeft _ _ d1 d2
  | isPositiveUnitFormula d1 && not (isPositiveUnitFormula d2) = True
  | isPositiveUnitFormula d2 && not (isPositiveUnitFormula d1) = False
  | isPositiveUnitFormula d1 && isPositiveUnitFormula d2 =
      let isEqLitOf d = case headLitOf d of { Just (T.Equality {}) -> True; _ -> False }
      in case (isEqLitOf d1, isEqLitOf d2) of
           (True,  False) -> True
           (False, True ) -> False
           _              -> True
firstParentIsLeft _ result d1 d2 = case consumerIsFirst result d1 d2 of
  -- the paper's order: the premise whose atom is consumed (the provider)
  -- goes to p0, the consumer to p1
  Just True  -> False
  Just False -> True
  Nothing    -> case (posHead d1, posHead d2) of
    (Just h1, _)       -> not (headInDecl h1 result)
    (Nothing, Just h2) -> headInDecl h2 result
    (Nothing, Nothing) -> True  -- both non-unit: keep original order
  where
    -- Like headLitOf, but a disequality atom (s != t) counts as a negative
    -- literal.  headLitOf treats it as positive, which hid the true head of
    -- clauses like g(X) != X | q(X): both heads came back Nothing, the
    -- parent order was kept, and the resolved-positive premise could end up
    -- right of its consumer, forcing a skip-and-retry during translation.
    posHead (T.Formula _ (T.CNF (T.Clause lits))) =
      single [ l | (T.Positive, l) <- toList lits, not (isNegEq l) ]
    posHead (T.Formula _ (T.FOF f)) = fofHead (stripQ f)
    posHead _ = Nothing
    stripQ (T.Quantified T.Forall _ b) = stripQ b
    stripQ f = f
    fofHead (T.Connected _ T.Implication (T.Atomic l))
      | not (isNegEq l) = Just l
    fofHead f = single (filter (not . isNegEq) (posLitsOfDisjFOF f))
    single [l] = Just l
    single _   = Nothing
    isNegEq (T.Equality _ T.Negative _) = True
    isNegEq _ = False
-- Which premise of a binary resolution consumes: its head is what the
-- resolvent's head instantiates, all but one of its body literals reappear
-- in the resolvent, and the one that does not is what the other premise's
-- head resolved against.  Nothing when the clauses are unavailable or when
-- both or neither read as the consumer (the caller then falls back to the
-- name-based guess).  This is the paper's tree order: the provider at p0.
consumerIsFirst :: T.Declaration -> T.Declaration -> T.Declaration -> Maybe Bool
consumerIsFirst result d1 d2 =
  case (convertDeclToClause result, convertDeclToClause d1, convertDeclToClause d2) of
    (Just r, Just c1, Just c2) ->
      -- the resolvent's variables are rigid (frozen to constants) and the
      -- premises' are renamed apart, so a premise variable never collides
      -- with a resolvent variable of the same name
      let r'  = onLits freeze r
          c1' = onLits (suffixVarsLit "_c") c1
          c2' = onLits (suffixVarsLit "_c") c2
      in case (consumes r' c1' c2', consumes r' c2' c1') of
           (True, False) -> Just True
           (False, True) -> Just False
           _             -> Nothing
    _ -> Nothing
  where
    onLits f (Clause bs mh) = Clause (map f bs) (fmap f mh)
    freeze = mapLiteralTerms fr
      where fr (Var v)    = Const ("_rv_" ++ v)
            fr (App f ts) = App f (map fr ts)
            fr t          = t
    consumes (Clause rb (Just rh)) (Clause cb (Just ch)) (Clause _ (Just ph)) =
      case matchLit ch rh of
        Nothing -> False
        Just σ ->
          let inResult l = any (isJust . matchLit l) rb
              missing = [ l | l <- map (applySubst σ) cb, not (inResult l) ]
          in case missing of
               [m] -> isJust (unifyLits (suffixVarsLit "_q" ph) m [])
               _   -> False
    consumes _ _ _ = False
isDerivedUnit :: T.Unit -> Bool
isDerivedUnit (T.Unit _ _ (Just (T.Inference {}, _))) = True
isDerivedUnit _                                           = False
-- True only for TPTP roles that indicate an original problem axiom.
isOrigAxiomDecl :: T.Declaration -> Bool
isOrigAxiomDecl (T.Formula (T.Standard T.Axiom)      _) = True
isOrigAxiomDecl (T.Formula (T.Standard T.Hypothesis) _) = True
isOrigAxiomDecl _                                        = False
