-- Extract everything the algorithm needs from a flat TSTP unit list.  Nodes get
-- bit-string positions, with root ⊥ at ε and children at suffixes 0 and 1.
-- Leaves at smaller positions are electrons for nuclei at larger positions.
module ProofTree
  ( buildProofInfo
  , conjectureHypotheses
  , headLitOf
  , unitNameStr
  , demodRuleNames
  , isPositiveUnitFormula
  , resolveSourceName
  , resolveCopySource
  , isFileSrc
  , isIntroducedSrc
  , lookupDecl
  , isDerivedUnit
  , isOrigAxiomDecl
  ) where
import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Control.Applicative ((<|>))
import Control.Monad (forM)
import Data.List (inits, intercalate, nub, partition, sortBy)
import Data.List.NonEmpty (NonEmpty ((:|)), toList)
import Data.Maybe (catMaybes, fromMaybe, isJust, listToMaybe)
import Data.Ord (comparing)
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import Types
import Helpers (applySubst, applySubstTerm, clauseInstance, deepApplySubstTerm, flipLit, litSubtermCtxs,
                mapLiteralTerms, matchLit, matchLitWith, matchTerms, suffixVarsLit,
                unifyLits, unifyTerms)
import TptpConvert (clauseToDecl, collectDisjuncts, convertDeclToClause, convertFOFToClause, convertLit, isReservedTLit)
data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)
-- A declaration with a distinct object, "Apple" say, in a term.
usesDistinctObjects :: T.Declaration -> Bool
usesDistinctObjects d = case d of
  T.Formula _ (T.CNF (T.Clause lits)) -> any (litHas . snd) (toList lits)
  T.Formula _ (T.FOF f)               -> formulaHas f
  _                                   -> False
  where
    formulaHas (T.Atomic l)         = litHas l
    formulaHas (T.Negated g)        = formulaHas g
    formulaHas (T.Connected l _ r)  = formulaHas l || formulaHas r
    formulaHas (T.Quantified _ _ b) = formulaHas b
    litHas (T.Predicate _ ts) = any termHas ts
    litHas (T.Equality a _ b) = termHas a || termHas b
    termHas (T.DistinctTerm _) = True
    termHas (T.Function _ ts)  = any termHas ts
    termHas _                  = False
-- A negated_conjecture clause that has a positive literal and only copies an
-- input is a hypothesis the conjecture granted, listed with the axioms.  An
-- implication conjecture negates into its hypotheses plus the negated
-- conclusion, and only the all-negative clause is the goal.
buildProofInfo :: [T.Unit] -> Either String ProofInfo
buildProofInfo allUnits = do
  tree <- maybe (Left "the proof never derives $false") Right (buildProofTree allUnits)
  let unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      resolve = resolveSourceName unitMap
      -- the clauses the conjecture grants as hypotheses
      granted = maybe [] (uncurry (++)) (conjectureHypotheses allUnits)
      -- a chain names the unit that rewrote.  A copy resolves to its axiom
      -- and a derived equation keeps its own identity
      chains  = demodChainsForLeaves (resolveCopySource unitMap) tree
      leafRows  = gatherLeaves "" tree
      innerRows = gatherInner  "" tree
      mkLeaf (pos, name, decl) =
        let srcName = if isNegConj decl then name
                      else let r = resolve name
                           -- a definition-derived clause keeps its own CNF
                           -- identity, since the FOF equivalence behind it
                           -- is not a Horn clause
                           in if isIntroducedSrc unitMap r && r /= name then name else r
            -- a FOF axiom that clausifies to several clauses is not this
            -- leaf's statement, which then keeps its own clause.  The negated
            -- conjecture keeps its source, which the goal reading expects
            role    = classifyRole granted unitMap name decl
            srcDecl = case Map.lookup srcName unitMap of
                        Just (T.Unit _ d _)
                          | role == NegConjecture || isJust (convertDeclToClause d) -> d
                        _ -> decl
        in LeafEntry
        { lePos     = pos
        , leUnit    = name
        , leName    = srcName
        , leDecl    = decl
        , leSrcDecl = srcDecl
        , leRole    = role
        , leHyp     = isHypothesisOfConjecture granted unitMap name decl
        , leSimpl   = fromMaybe [] (Map.lookup pos chains)
        }
      mkInner (pos, name, decl) = LeafEntry
        { lePos     = pos
        , leUnit    = name
        , leName    = name
        , leDecl    = decl
        , leSrcDecl = decl   -- inner nodes are already the derived form
        , leRole    = Derived
        , leHyp     = False
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
  -- Unsupported means one thing only, that the refutation uses a clause with
  -- more than one positive literal.  Every other failure has its own message.
  mapM_ (\n -> Left ("unsupported proof, clause " ++ n ++ " is not Horn"))
        (take 1 [ n | (_, n, d) <- leafRows ++ innerRows, isNonHorn d ])
  mapM_ Left (calculusViolation unitMap =<< findRoot allUnits)
  -- distinct objects are unequal by a theory fact, not by an inference
  mapM_ (\n -> Left ("unsupported proof, unit " ++ n
                     ++ " uses distinct objects, whose inequality is a theory fact outside the calculus"))
        (take 1 [ unitNameStr n | T.Unit n d _ <- allUnits, usesDistinctObjects d ])
  conjecture <- mapM readConjecture (listToMaybe (fofConjectures allUnits))
  -- prefer the original conjecture unit since provers may split or simplify
  -- it.  Without one the goal clause is the negated conjecture clause resolved
  -- closest to the root, and for a negated conclusion, proved by deriving
  -- $false from its conjuncts, the all-negative clause that closed the
  -- refutation, which may be a derived one.
  let byDepth = sortBy (comparing (\e -> (length (lePos e), lePos e)))
      negatedConclusion = maybe False (\c -> null (cjGoals c) && not (null (cjNegated c))) conjecture
  rawGoalLits <- maybe (Left "no clause of the proof states the goal") Right
            $ case extractConjectureGoals allUnits of
    Just lits -> Just lits
    Nothing   -> listToMaybe $
      -- the source unit's statement, or the clause's own when the source is
      -- a whole negated formula, as Twee's negate_conjecture leaves it
      [ lits
      | e <- byDepth [ e' | e' <- nuclei, leRole e' == NegConjecture ]
      , let goalDecl = fromMaybe (leDecl e) (lookupDecl unitMap (leName e))
      , Just lits <- [extractGoalLits goalDecl <|> extractGoalLits (leDecl e)]
      ] ++
      -- in UEQ problems the negated conjecture is a disequality axiom with no negated_conjecture role
      [ lits
      | e <- nuclei, leRole e == OrigAxiom
      , Just lits <- [extractGoalLits (leDecl e)]
      ] ++
      [ lits
      | negatedConclusion
      , e <- byDepth [ e' | e' <- nuclei, leRole e' == Derived ]
      , Just lits <- [extractGoalLits (leDecl e)]
      ]
  -- A goal atom that abbreviates a formula the prover introduced is that
  -- formula's atoms, and when the formula is not a conjunction of atoms, as a
  -- disjunction of cases is not, the reader's goal has no Horn statement.
  let definedSymbols = Set.fromList [ n | T.Unit _ (T.Formula _ (T.FOF f)) (Just (T.Introduced _ _, _)) <- allUnits
                                        , Just n <- [definedAtom f] ]
      definedAtom (T.Connected l T.Equivalence r) = atomName l <|> atomName r
      definedAtom (T.Quantified _ _ body)          = definedAtom body
      definedAtom _                                 = Nothing
      atomName (T.Atomic (T.Predicate (T.Defined (T.Atom n)) [])) = Just n
      atomName (T.Negated f)                                       = atomName f
      atomName _                                                   = Nothing
  goalLits <- fmap concat $ forM rawGoalLits $ \lit -> case unfoldDefinition unitMap lit of
    [same] | same == lit, T.Predicate (T.Defined (T.Atom n)) [] <- lit, Set.member n definedSymbols ->
      Left ("unsupported conjecture, " ++ Text.unpack n
            ++ " abbreviates a formula the prover introduced that is not a conjunction of atoms, so its proof is a case split")
    lits -> Right lits
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
-- Navigate the memoised tree along a position string.  Each character is the
-- child index used by gatherLeaves and gatherInner, and unary nodes use 1.
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
    -- Memoised node table, so each TSTP clause is built at most once.
    -- Data.Map.Strict forces values to WHNF only, and PTNode's children stay
    -- a lazy thunk.  TSTP proofs are acyclic, so the thunks are safe to force
    -- later and are evaluated at most once.
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
        -- A nested inference such as E's cn(rw(spm(A,B),L)).  The innermost
        -- step resolves p0 with p1, each further parent simplifies by a unit,
        -- and the outer node is the last step.  The unprinted intermediates
        -- are recomputed as synthetic "?" nodes so θ is traced through them.
        -- Without a replay they fall back to the complement of the last unit
        -- for a ⊥ outer node, or else the outer clause.
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
-- Replay a nested inference.  Resolve or superpose c0 with c1, simplify by
-- each further unit, and accept a replay whose final clause is a variant of
-- the outer clause.  Returns whether c0 provides the first step and the
-- intermediate clauses innermost first.
replayNested :: T.Declaration -> T.Declaration -> [T.Declaration] -> Maybe (Bool, [T.Declaration])
replayNested outerD d0 ds = do
  outer <- convertDeclToClause outerD
  c0    <- convertDeclToClause d0
  cs    <- mapM convertDeclToClause ds
  (c1, units) <- case cs of { (x : xs) -> Just (x, xs); [] -> Nothing }
  listToMaybe
    [ (prov, map (clauseToDecl . instC σ) chain)
    -- Condense the resolvent before simplifying it.  A Horn premise brings its
    -- own body literals along, and one of them may already be present in the
    -- other clause.  The prover merges the duplicates with E's cn and removes
    -- the survivor with a unit.  Resolving one copy first leaves the other
    -- behind, as on MGT006-1.
    | (prov, r0) <- resolvents c0 c1
    , let r = cn r0
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
        -- resolution of the head against a body literal
        [ mk σ (body x ++ rest) (hd y)
        | (l, rest) <- picks (body y), Just σ <- [unifyLits h l []] ]
        -- superposition of an equation head into a subterm of any literal.
        -- As in rewriteOnce it applies at the one redex or at every occurrence.
        -- A prover using the equation as a demodulator replaces them all, and
        -- a clause with the term twice is otherwise never reproduced, as on
        -- LAT263-2.
        ++ [ mk σ (body x ++ bodyY') hdY'
           | Eq s t <- [h], (lhs, rhs) <- [(s, t), (t, s)], notVar lhs
           , (i, lit) <- zip [0 :: Int ..] (polLits y)
           , (u, ctx) <- litSubtermCtxs (snd lit), notVar u
           , Just σ <- [unifyTerms lhs u []]
           , ys <- [ [ if j == i then (fst l, ctx rhs) else l
                     | (j, l) <- zip [0 :: Int ..] (polLits y) ]
                   , [ (sg, mapLiteralTerms (replaceAll u rhs) m)
                     | (sg, m) <- polLits y ] ]
           , let bodyY' = [ l | (False, l) <- ys ]
                 hdY'   = listToMaybe [ l | (True, l) <- ys ] ]
    mk σ bs mh = Clause (map (deep σ) bs) (fmap (deep σ) mh)
    deep σ = mapLiteralTerms (deepApplySubstTerm σ)
    polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]
    notVar (Var _) = False
    notVar _       = True
-- One simplification step as E's rw, sr, csr and cn perform it.  A clause with
-- a head resolves away a body literal, bringing its own conditions along, or
-- as a unit equation rewrites in either orientation.  A negative unit ~L
-- removes a head that is an instance of L.  Trivial body equations and
-- duplicate literals are dropped afterwards.
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
-- An all-negative simplifier cancels the clause's head against one of its
-- literals and brings its other conditions along instantiated, as E's csr
-- does.  With one literal this is plain simplify-reflect.  SYN590-1 needs the
-- general form, where ~p12(f8(X1),c15) | ~p11(X1) cancels p12(f8(f9(c16)),c15)
-- and contributes ~p11(f9(c16)).
simplifyBy c (Clause ls Nothing) =
  map cn
    [ Clause (body c ++ map (applySubst σ) rest) Nothing
    | Just h <- [hd c]
    , (l, rest) <- picks (map (suffixVarsLit "_u") ls)
    , l' <- [l, flipLit l]
    , Just σ <- [matchLit l' h] ]
-- One demodulation step.  The equation is applied to a single redex, either at
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

-- Replace every occurrence of one subterm by another.
replaceAll :: Term -> Term -> Term -> Term
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
-- The substitution under which the replayed clause becomes the printed one.
-- Every replayed literal matches a printed literal of the same polarity and
-- every printed literal is hit.  Two replayed literals may land on the same
-- printed one, which is how a condition brought along by E's csr merges with
-- one the clause already carries.  Only the replayed clause is instantiated.
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
-- Gather leaves with two levels of deduplication, keeping traversal of the
-- shared memoised tree O(N).  seenElec records electron leaves, each kept once
-- at its first DFS position.  seenInner maps an inner node to its non-unit
-- leaves with relative positions, so a second encounter re-emits them at the
-- new position without re-traversing.  Electrons are never re-emitted, but
-- rule clauses reappear at every position since each occurrence is a separate
-- rule application that may see different electrons.
gatherLeaves :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherLeaves pos0 tree0 =
    let (_, _, res) = go pos0 tree0 Set.empty Map.empty in res
  where
    -- seenElec is a set of names, and seenInner maps an inner name to its
    -- non-unit leaves as (relative position, name, declaration)
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
      | n == "?"               = (seen, [(pos, n, d)])   -- synthetic nodes are always included
      | Set.member n seen      = (seen, [])
      | otherwise              = (Set.insert n seen, [(pos, n, d)])
classifyRole :: [Clause] -> Map.Map String T.Unit -> String -> T.Declaration -> LeafRole
classifyRole granted unitMap name decl
  -- positive-unit file clauses are axioms even if labeled negated_conjecture
  -- (Vampire's "prove the negation" mode does this for all input clauses)
  | isPositiveUnitFormula decl && isFileSrc unitMap name     = OrigAxiom
  | isPositiveUnitFormula decl && isFileSrc unitMap resolvedNm = OrigAxiom
  | isConjHypothesis granted unitMap name decl                = OrigAxiom
  | isNegConj decl                                           = NegConjecture
  | maybe False isNegConj (lookupDecl unitMap resolvedNm)    = NegConjecture
  -- A clause whose source traces back to a file conjecture is part of the
  -- negation chain, as in FOF clausification
  | maybe False isConjDecl (lookupDecl unitMap resolvedNm)   = NegConjecture
  | isFileSrc unitMap name                                    = OrigAxiom
  | isFileSrc unitMap resolvedNm                              = OrigAxiom
  -- clauses derived from definitions the prover introduced, like E's epredN
  -- equivalences, are axioms of the clausified presentation and their own CNF
  -- is the axiom statement
  | isIntroducedSrc unitMap resolvedNm                        = OrigAxiom
  | otherwise                                                 = Derived
  where
    resolvedNm = resolveSourceName unitMap name
    isConjDecl (T.Formula (T.Standard T.Conjecture) _) = True
    isConjDecl _                                        = False
isNegConj :: T.Declaration -> Bool
isNegConj (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegConj _                                              = False

-- A positive clause of the negated conjecture is a hypothesis of an
-- implication conjecture.  It may carry the negated_conjecture role itself,
-- as with E and Vampire, or be a plain clausified copy of the negated
-- formula, as TPTP's own tools write it.
-- A clause with a head, or one the conjecture grants, as a head-less clause
-- of its antecedent is a hypothesis too while a head-less clause it does not
-- grant is the negated conclusion, the goal.
isConjHypothesis :: [Clause] -> Map.Map String T.Unit -> String -> T.Declaration -> Bool
isConjHypothesis granted unitMap name decl =
  (hasHead || grantedClause)
  && (isNegConj decl || csNeg)
  && (Map.notMember cs unitMap || isFileSrc unitMap cs || csNeg)
  where
    cs    = resolveCopySource unitMap name
    csNeg = maybe False isNegConj (lookupDecl unitMap cs)
    -- the clause's head, where a disequality is a negated goal, not a head
    clause  = convertDeclToClause decl
    hasHead = maybe False (isJust . hd) clause
    grantedClause = maybe False (\c -> any (`clauseInstance` c) granted) clause

-- Such a clause was assumed by an implication conjecture only when the
-- negated conjecture it copies was derived by negating one.  A problem that
-- states its negated conjecture as clauses has stated inputs instead.
isHypothesisOfConjecture :: [Clause] -> Map.Map String T.Unit -> String -> T.Declaration -> Bool
isHypothesisOfConjecture granted unitMap name decl =
  isConjHypothesis granted unitMap name decl
  && maybe False isNegConj (lookupDecl unitMap cs)
  && not (isFileSrc unitMap cs)
  where cs = resolveCopySource unitMap name

-- The FOF conjecture as the format states it.  After the universal prefix,
-- H => G assumes the Horn clauses of H, a conclusion ~F assumes the clauses
-- of F and derives $false, and any other conclusion is a conjunction of goal
-- atoms whose existential variables θ instantiates.  Other shapes, a
-- disjunction or an equivalence say, have no direct Horn proof and are
-- refused with the shape named.
data Conjecture = Conjecture
  { cjHyps    :: [Clause]      -- the antecedent's clauses
  , cjNegated :: [Clause]      -- the clauses of a negated conclusion, assumed too
  , cjGoals   :: [T.Literal] } -- the goal atoms, none for a negated conclusion

readConjecture :: T.UnsortedFirstOrder -> Either String Conjecture
readConjecture = conclusion [] . normalizeConjecture
  where
    conclusion hs f = case f of
      T.Quantified T.Forall _ b     -> conclusion hs b
      -- ? Y ! X (A(Y) => B(X)) is proved by the Horn refutation of
      -- (! Y A(Y)) => (! X B(X)), which implies it, since with every Y
      -- satisfying A every X satisfies B, and otherwise a Y with ~A(Y) is the
      -- witness.  So an existential over an implication is read as the
      -- implication with a closed hypothesis and a universal goal.
      T.Quantified T.Exists _ b@(T.Connected _ T.Implication _) -> conclusion hs b
      T.Quantified T.Exists _ b@(T.Quantified T.Forall _ (T.Connected _ T.Implication _)) -> conclusion hs b
      T.Connected l T.Implication r -> do
        cs <- hypotheses l
        conclusion (hs ++ cs) r
      -- ~(C & ~G) is C => G, so one negated conjunct of a negated conclusion
      -- is the goal and the others are assumed, while several negated
      -- conjuncts leave a disjunction
      T.Negated g -> case partition isNegated (conjuncts g) of
        ([], pos)          -> do
          cs <- mapM assumed pos
          Right (Conjecture hs (concat cs) [])
        ([T.Negated goal], pos) -> do
          cs <- mapM assumed pos
          conclusion (hs ++ concat cs) goal
        (negs, _) -> Left (refused ("its negated formula has the negated conjuncts "
                                     ++ intercalate " and " (map render negs) ++ ", so its proof is a case split"))
      -- ? X (C & ~G) is ~ ! X (C => G), a negated universal clause
      T.Quantified T.Exists vs b | any isNegated (conjuncts b) ->
        conclusion hs (T.Negated (T.Quantified T.Forall vs (T.Negated b)))
      -- a conclusion written as a Horn clause, ~A | B, is the implication
      -- A => B, and an all-negative one, ~A | ~B, the negation ~(A & B)
      T.Connected _ T.Disjunction _ | Just g <- hornImplication f -> conclusion hs g
      -- any other disjunction of literals, A | B, is ~(~A & ~B), so its
      -- proof assumes the negation of each literal and derives $false
      _ | Just cs <- negatedDisjuncts f -> Right (Conjecture hs cs [])
      _ -> Conjecture hs [] <$> goalAtoms False f
    -- a $false disjunct adds nothing, and a $true one is not read here, so
    -- the conclusion is refused as a tautology below
    negatedDisjuncts f = case collectDisjuncts (stripQuantifiers f) of
      Just pairs | length pairs > 1, not (any tautological pairs) ->
        Just [ case s of
                 T.Positive -> Clause [convertLit l] Nothing
                 T.Negative -> Clause [] (Just (convertLit l))
             | (s, l) <- pairs, not (isReservedTLit l) ]
      _ -> Nothing
    tautological (T.Positive, T.Predicate (T.Reserved (T.Standard T.Tautology)) []) = True
    tautological (T.Negative, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])    = True
    tautological _                                                                 = False
    stripQuantifiers (T.Quantified _ _ b) = stripQuantifiers b
    stripQuantifiers g                   = g
    hornImplication f = case collectDisjuncts f of
      Just pairs | body@(_ : _) <- [ T.Atomic l | (T.Negative, l) <- pairs ] ->
        let conj = foldr1 (\l r -> T.Connected l T.Conjunction r) body
        in case [ l | (T.Positive, l) <- pairs ] of
             [h] -> Just (T.Connected conj T.Implication (T.Atomic h))
             []  -> Just (T.Negated conj)
             _   -> Nothing
      _ -> Nothing
    conjuncts f = case f of
      T.Connected l T.Conjunction r -> conjuncts l ++ conjuncts r
      T.Quantified T.Exists _ b     -> conjuncts b
      _                             -> [f]
    isNegated (T.Negated _) = True
    isNegated _             = False
    -- the antecedent's conjuncts, an equivalence giving both directions and a
    -- negated implication its premise and negated conclusion
    hypotheses f = case f of
      T.Quantified T.Forall _ b     -> hypotheses b
      T.Connected l T.Conjunction r -> (++) <$> hypotheses l <*> hypotheses r
      T.Connected l T.Equivalence r -> (++) <$> hypotheses (T.Connected l T.Implication r)
                                           <*> hypotheses (T.Connected r T.Implication l)
      T.Negated (T.Connected l T.Implication r) -> (++) <$> hypotheses l <*> hypotheses (T.Negated r)
      T.Quantified T.Exists _ b     -> hypotheses b
      _ -> clause ("its hypothesis " ++ render f ++ " is not a Horn clause") f
    -- a conjunct of the negated conclusion, assumed to derive $false
    assumed f = clause ("the negated formula has the conjunct " ++ render f ++ ", which is not a Horn clause") f
    clause why f = maybe (Left (refused why)) (Right . pure) (convertFOFToClause f)
    -- the goal atoms, and the shape that stops the reading, where an
    -- implication among them has its own hypotheses and one under an
    -- existential quantifier negates into a positive clause for every value
    goalAtoms ex f = case f of
      T.Quantified T.Exists _ b     -> goalAtoms True b
      T.Quantified T.Forall _ b     -> goalAtoms ex b
      T.Atomic a | isReservedTLit a -> Left (refused ("its conclusion " ++ render f ++ " is a truth constant, not an atom"))
      T.Atomic a                    -> Right [a]
      T.Connected l T.Conjunction r -> (++) <$> goalAtoms ex l <*> goalAtoms ex r
      T.Connected _ T.Disjunction _
        | maybe False (any tautological) (collectDisjuncts f) -> Left (refused ("its conclusion " ++ render f ++ " is a tautology"))
        | not (isJust (convertFOFToClause f)) -> Left (refused ("its conclusion has the disjunction " ++ render f ++ ", so its proof is a case split"))
      T.Connected _ T.Equivalence _ -> Left (refused ("its conclusion has the equivalence " ++ render f ++ ", two implications with different hypotheses"))
      _ | ex        -> Left (refused ("its conclusion has the implication " ++ render f ++ " under an existential quantifier, so its proof is a case split"))
        | isJust (convertFOFToClause f) -> Left (refused ("its conclusion has the conjunct " ++ render f ++ ", an implication with its own hypotheses"))
        | otherwise -> Left (refused ("its conclusion has the conjunct " ++ render f ++ ", which is not an atom"))
    refused why = "unsupported conjecture, " ++ why
    render f = show (pretty f)

-- A <= B is B => A, a double negation cancels, and a negation moves through
-- an existential quantifier so that ~ ? X F is ! X ~F and ? X ~F is ~ ! X F,
-- which the reader states as the negation of a universal clause.
normalizeConjecture :: T.UnsortedFirstOrder -> T.UnsortedFirstOrder
normalizeConjecture f = case f of
  T.Quantified q vs b -> case (q, normalizeConjecture b) of
    (T.Exists, T.Negated g) -> T.Negated (T.Quantified T.Forall vs g)
    (T.Exists, T.Connected l T.Implication r)
      | Just g <- scopeImplication vs l r -> g
    (_, b')                 -> T.Quantified q vs b'
  T.Connected l T.ReversedImplication r -> normalizeConjecture (T.Connected r T.Implication l)
  T.Connected l c r -> T.Connected (normalizeConjecture l) c (normalizeConjecture r)
  T.Negated g -> case normalizeConjecture g of
    T.Negated h                -> h
    T.Quantified T.Exists vs b -> normalizeConjecture (T.Quantified T.Forall vs (T.Negated b))
    g'                         -> T.Negated g'
  _ -> f

-- ? [Xs] (A => B) quantifies over the implication only for a variable free
-- in both sides.  One free in A alone is universal over A, so the hypothesis
-- is a clause, and one free in B alone is existential over B, so the goal
-- is an existential conjunction.  Nothing when every variable is in both.
scopeImplication :: NonEmpty (T.Var, T.Unsorted) -> T.UnsortedFirstOrder -> T.UnsortedFirstOrder
                 -> Maybe T.UnsortedFirstOrder
scopeImplication vs l r
  | null vsL && null vsR = Nothing
  | otherwise = Just (quant T.Exists vsBoth
                        (T.Connected (quant T.Forall vsL l) T.Implication (quant T.Exists vsR r)))
  where
    fl = freeVars l
    fr = freeVars r
    vsL    = [ v | v <- toList vs, Set.member (fst v) fl, Set.notMember (fst v) fr ]
    vsR    = [ v | v <- toList vs, Set.notMember (fst v) fl ]
    vsBoth = [ v | v <- toList vs, Set.member (fst v) fl, Set.member (fst v) fr ]
    quant _ [] g         = g
    quant q (v : more) g = T.Quantified q (v :| more) g

freeVars :: T.FirstOrder s -> Set.Set T.Var
freeVars (T.Atomic l)          = Set.fromList (litV l)
  where
    litV (T.Predicate _ ts) = concatMap termV ts
    litV (T.Equality a _ b) = termV a ++ termV b
    termV (T.Variable v)    = [v]
    termV (T.Function _ ts) = concatMap termV ts
    termV _                 = []
freeVars (T.Negated g)         = freeVars g
freeVars (T.Connected l _ r)   = Set.union (freeVars l) (freeVars r)
freeVars (T.Quantified _ vs b) = freeVars b `Set.difference` Set.fromList (map fst (toList vs))

-- The conjecture formulas of the proof.  Twee writes a clausal conjecture as
-- a cnf unit, which is read as the disjunction of its literals.
fofConjectures :: [T.Unit] -> [T.UnsortedFirstOrder]
fofConjectures units = concat
  [ case decl of
      T.Formula (T.Standard T.Conjecture) (T.FOF f)                -> [f]
      T.Formula (T.Standard T.Conjecture) (T.CNF (T.Clause lits)) -> [clauseFormula (toList lits)]
      _                                                            -> []
  | T.Unit _ decl _ <- units ]

clauseFormula :: [(T.Sign, T.Literal)] -> T.UnsortedFirstOrder
clauseFormula ls = foldr1 (\a b -> T.Connected a T.Disjunction b)
  [ if s == T.Positive then T.Atomic l else T.Negated (T.Atomic l) | (s, l) <- ls ]

-- The clauses a conjecture grants as hypotheses, those of the antecedent and
-- those of a negated conclusion, since ~G is proved by assuming G.  Nothing
-- when there is no FOF conjecture.
conjectureHypotheses :: [T.Unit] -> Maybe ([Clause], [Clause])
conjectureHypotheses units = listToMaybe
  [ (cjHyps c, cjNegated c) | Right c <- map readConjecture (fofConjectures units) ]
-- A unit the prover introduced itself, like E's introduced(definition).
isIntroducedSrc :: Map.Map String T.Unit -> String -> Bool
isIntroducedSrc unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ _ (Just (T.Introduced _ _, _))) -> True
  _                                              -> False
-- An input formula, either sourced from a file or carrying no source at all.
-- E and Vampire always annotate, but a hand-written or TPTP-tool proof may
-- state its axioms bare, and a unit that was not derived is an input.
isFileSrc :: Map.Map String T.Unit -> String -> Bool
isFileSrc unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ _ (Just (T.File _ _, _))) -> True
  Just (T.Unit _ _ Nothing)                -> True
  _                                         -> False
lookupDecl :: Map.Map String T.Unit -> String -> Maybe T.Declaration
lookupDecl unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ d _) -> Just d
  _                   -> Nothing

-- The step that negates the conjecture.  Vampire calls it negated_conjecture,
-- E assume_negation, Twee negate_conjecture and TPTP's own tools negate.
-- Source tracing stops there, or a negated goal clause resolves to the
-- conjecture itself.
isNegationRule :: Text.Text -> Bool
isNegationRule r = r `elem` map Text.pack ["negated_conjecture", "negate", "negate_conjecture", "assume_negation"]

-- A source with the negation step at its top or nested in a simplification,
-- as E's fof_simplification(assume_negation(c)), so tracing stops at that unit
sourceNegates :: T.Source -> Bool
sourceNegates (T.Inference (T.Atom rule) _ ps) =
  isNegationRule rule || or [ sourceNegates s | T.Parent s _ <- ps ]
sourceNegates _ = False

-- Trace back only through copy steps, meaning bare unit references and
-- single-parent preprocessing such as cnf_transformation.  Unlike
-- resolveSourceName a genuine inference stops the trace, since its conclusion
-- is a new clause.  Decides whether a derived clause is only a renamed axiom
-- and so not a lemma candidate.
resolveCopySource :: Map.Map String T.Unit -> String -> String
resolveCopySource unitMap = go
  where
    go name = case Map.lookup name unitMap of
      Just (T.Unit _ _ (Just (T.UnitSource parentName, _))) ->
        go (unitNameStr parentName)
      -- a step's one parent, where a Skolemization also cites the Skolem
      -- definition it introduced, which does not count
      Just (T.Unit _ _ (Just (src@(T.Inference (T.Atom rule) _ ps), _)))
        | not (Set.member rule coreInferenceNames)
        , not (sourceNegates src)
        , [pn] <- filter (\n -> not (isSkolemStep rule && isIntroducedSrc unitMap n)) (concatMap flatParents ps)
        -> go pn
      _ -> name
    flatParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    flatParents (T.Parent (T.Inference _ _ ps) _) = concatMap flatParents ps
    flatParents _                                  = []
    isSkolemStep r = Text.pack "skolem" `Text.isInfixOf` r

-- Trace back to the original file unit.  Stop at the negation step and at
-- Twee's rewriting steps, which create new equations by completion
resolveSourceName :: Map.Map String T.Unit -> String -> String
resolveSourceName unitMap = go
  where
    go name = case Map.lookup name unitMap of
      -- trace through bare UnitSource references (E copies axioms this way)
      Just (T.Unit _ _ (Just (T.UnitSource parentName, _))) ->
        go (unitNameStr parentName)
      Just (T.Unit _ _ (Just (src@(T.Inference (T.Atom rule) _ parents), _)))
        | not (sourceNegates src)
        , rule /= Text.pack "rewriting"        -- Twee creates new equations here
        , rule /= Text.pack "proved_conjecture" -- Twee's terminal step
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
-- A goal clause is all negative, where a disequality counts as a negative
-- equation, so s != t | ~p(s) states the goals s = t and p(s).
extractGoalLits (T.Formula _ (T.CNF (T.Clause lits))) = mapM goalOf (toList lits)
  where
    goalOf (T.Negative, lit)                       = Just lit
    goalOf (T.Positive, T.Equality l T.Negative r) = Just (T.Equality l T.Positive r)
    goalOf _                                       = Nothing
extractGoalLits (T.Formula _ (T.FOF f)) = extractFOF f
  where
    extractFOF (T.Quantified T.Forall _ body)          = extractFOF body
    extractFOF (T.Negated body)                        = extractConj body
    extractFOF (T.Atomic (T.Equality l T.Negative r)) = Just [T.Equality l T.Positive r]
    -- A clause with a positive literal is a hypothesis and never a goal
    -- source, since Vampire labels every input negated_conjecture when proving
    -- the negation.  Only an all-negative clause states negated goals.  The
    -- scan is local because a disequality must count as negative here, and
    -- changing posLitsOfDisjFOF for headLitOf alters premise matching
    -- elsewhere, as the goldens show.
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
-- A goal atom the prover introduced as an abbreviation, like E's definitional
-- predicate in "~epred <=> ! [X] ~E(f(X),0)", stands for the atom it
-- abbreviates, and that atom is the reader's goal.  Other atoms are returned
-- unchanged.
unfoldDefinition :: Map.Map String T.Unit -> T.Literal -> [T.Literal]
unfoldDefinition unitMap lit@(T.Predicate (T.Defined (T.Atom pname)) []) =
  case [ body | T.Unit _ (T.Formula _ (T.FOF f)) (Just (T.Introduced _ _, _)) <- Map.elems unitMap
              , Just body <- [definitionBody f] ] of
    (body : _) -> body
    []         -> [lit]
  where
    isAtom (T.Atomic (T.Predicate (T.Defined (T.Atom n)) [])) = n == pname
    isAtom _ = False
    -- the atoms of phi in "p <=> phi" or "~p <=> ~phi" with quantifiers stripped
    definitionBody (T.Connected l T.Equivalence r)
      | isAtom l = atomsOf r
      | isAtom r = atomsOf l
      | T.Negated l' <- l, isAtom l' = atomsOf (negatedOf r)
      | T.Negated r' <- r, isAtom r' = atomsOf (negatedOf l)
    definitionBody (T.Quantified _ _ body) = definitionBody body
    definitionBody _ = Nothing
    -- the negation pushed inward, so ~(~a | ~b) is the conjunction a & b
    negatedOf (T.Quantified q vs body)          = T.Quantified q vs (negatedOf body)
    negatedOf (T.Negated body)                  = body
    negatedOf (T.Connected l T.Disjunction r)   = T.Connected (negatedOf l) T.Conjunction (negatedOf r)
    negatedOf body                              = T.Negated body
    atomsOf (T.Quantified _ _ body) = atomsOf body
    atomsOf (T.Atomic a)            = Just [a]
    atomsOf (T.Connected l T.Conjunction r) = (++) <$> atomsOf l <*> atomsOf r
    atomsOf _ = Nothing
unfoldDefinition _ lit = [lit]
-- more reliable than the negated conjecture since E may split or simplify it
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
    -- a negated conclusion has no goal atoms, and the clause that closed the
    -- refutation supplies them instead.  Twee writes a clausal conjecture as
    -- a cnf unit, read as the disjunction of its literals.
    extractConjLits (T.Formula _ (T.CNF (T.Clause lits))) = goalsOf (clauseFormula (toList lits))
    extractConjLits (T.Formula _ (T.FOF f))               = goalsOf f
    extractConjLits _                                      = Nothing
    goalsOf f = case readConjecture f of
      Right c | not (null (cjGoals c)) -> Just (cjGoals c)
      _                                -> Nothing
-- for each PTLeaf position, the chain of demodulation steps before it was
-- consumed, outermost first
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
    go pos (PTNode n nd rule [l, r]) seenElec seenInner
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
      -- a superposition of a unit equation into the head of a clause is a
      -- demodulation of that clause, in the direction that yields the
      -- derived head
      | isSuperpositionRule rule, Just (eqT, clT, eqPos, clPos, dir) <- superpositionInto nd l r =
          let eqName = resolveName (treeName eqT)
              (se',  si',  eMap) = go (pos ++ eqPos) eqT seenElec seenInner
              (se'', si'', cMap) = go (pos ++ clPos) clT se' si'
              si''' = if n /= "?" then Set.insert n si'' else si''
          in  (se'', si''', Map.union eMap (Map.map ((eqName, dir) :) cMap))
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
    -- definition_unfolding has three uses, so track it only when rewriting a predicate unit.
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
    isSuperpositionRule r = r `elem` map Text.pack ["superposition", "paramodulation", "spm", "pm"]
    unitEquation t = isPositiveUnitFormula (ptDecl t)
                     && case headLitOf (ptDecl t) of { Just (T.Equality {}) -> True; _ -> False }
    superpositionInto nd l r
      | unitEquation l, not (isPositiveUnitFormula (ptDecl r)), Just d <- headRewrite nd l r = Just (l, r, "0", "1", d)
      | unitEquation r, not (isPositiveUnitFormula (ptDecl l)), Just d <- headRewrite nd r l = Just (r, l, "1", "0", d)
      | otherwise = Nothing
    -- the direction in which the equation, unified with a subterm of the
    -- clause's head, turns that head into the derived clause's head
    headRewrite nd eqT clT = do
      eqL    <- convertLit <$> headLitOf (ptDecl eqT)
      (a, b) <- case eqL of { Eq x y -> Just (x, y); _ -> Nothing }
      h      <- convertLit <$> headLitOf (ptDecl clT)
      target <- convertLit <$> headLitOf nd
      listToMaybe
        [ d | (d, from, to) <- [(LR, a, b), (RL, b, a)]
            , (sub, rebuild) <- litSubtermCtxs h
            , Just σ <- [unifyTerms sub from []]
            , let h' = applySubst σ (rebuild (applySubstTerm σ to))
            , isJust (matchLit h' target), isJust (matchLit target h') ]
    treeName (PTLeaf n _)     = n
    treeName (PTNode n _ _ _) = n
demodRuleNames :: Set.Set Text.Text
demodRuleNames = Set.fromList $ map Text.pack
  [ "forward_demodulation", "backward_demodulation"
  , "rw", "definition_unfolding" ]
  -- Twee's "rewriting" is not here because it creates new equations
unitNameStr :: T.UnitName -> String
unitNameStr (Left (T.Atom t)) = Text.unpack t
unitNameStr (Right n)         = show n
coreInferenceNames :: Set.Set Text.Text
coreInferenceNames = Set.fromList $ map Text.pack
  [ "resolution", "resolve", "superposition", "paramodulation"
  , "equality_resolution"
  , "forward_subsumption_resolution", "backward_subsumption_resolution"
  , "condensation"
  , "definition_unfolding", "trivial_inequality_removal"
  , "forward_demodulation", "backward_demodulation"
  , "duplicate_literal_removal", "subsumption_resolution"
  , "spm", "sr", "csr", "er", "rw", "cn", "pm"
  , "proved_conjecture"
  , "rewriting" ]  -- Twee's rewriting creates new equations and expands into the tree
-- The calculus of the paper is resolution with subsumption resolution and
-- duplicate literal elimination, superposition, demodulation and equality
-- resolution.  These rules are outside it, and a step by any other rule not
-- listed above that combines several premises is a genuine inference too, so
-- both are refused by name rather than read as copies of a premise.
outsideCalculus :: Text.Text -> Bool
outsideCalculus r = Set.member r outside || Text.pack "avatar_" `Text.isPrefixOf` r
  where
    outside = Set.fromList $ map Text.pack
      [ "factoring", "equality_factoring", "ef"   -- factoring, for non-Horn clauses
      , "ar"                                       -- E's AC resolution
      , "cdclpropres"                              -- E's propositional SAT refutation
      , "unit_resulting_resolution", "global_subsumption" ]
calculusViolation :: Map.Map String T.Unit -> String -> Maybe String
calculusViolation unitMap root = go Set.empty [root]
  where
    go _ [] = Nothing
    go seen (n : rest)
      | Set.member n seen = go seen rest
      | otherwise = case Map.lookup n unitMap of
          Just (T.Unit _ _ (Just (src, _))) -> case check src of
            Just bad -> Just ("unsupported proof, step " ++ n ++ " uses " ++ bad
                              ++ ", an inference outside the supported calculus of resolution, "
                              ++ "superposition, demodulation and equality resolution")
            Nothing  -> go (Set.insert n seen) (names src ++ rest)
          _ -> go (Set.insert n seen) rest
    check (T.Inference (T.Atom rule) _ ps)
      | outsideCalculus rule = Just (Text.unpack rule)
      | not (Set.member rule coreInferenceNames), not (isNegationRule rule)
      , length (filter premise ps) > 1 = Just (Text.unpack rule ++ " on several premises")
      | otherwise = listToMaybe (catMaybes [ check s | T.Parent s _ <- ps ])
    check _ = Nothing
    -- a Skolemization or definition step also cites the definition it used
    premise (T.Parent (T.UnitSource pn) _) = not (isIntroducedSrc unitMap (unitNameStr pn))
    premise (T.Parent (T.Inference {}) _)  = True
    premise _                              = False
    names (T.UnitSource pn)    = [unitNameStr pn]
    names (T.Inference _ _ ps) = concat [ names s | T.Parent s _ <- ps ]
    names _                    = []
coreParentNames :: T.Unit -> Maybe [String]
coreParentNames (T.Unit _ decl (Just (T.Inference (T.Atom rule) _ parents, _)))
  | Set.member rule coreInferenceNames = Just (concatMap extractName parents)
  | isPredicateRewriting rule decl     = Just (concatMap extractName parents)
  where
    extractName (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    extractName (T.Parent (T.Inference _ _ ps) _) = concatMap extractName ps
    extractName (T.Parent _ _)                    = []  -- unknown source is skipped
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
-- A clause with more than one positive literal.  A disequality counts as
-- negative, and a formula that is not a clause at all is not reported here.
isNonHorn :: T.Declaration -> Bool
isNonHorn d = case d of
  T.Formula _ (T.CNF (T.Clause lits)) -> heads (toList lits) > 1
  T.Formula _ (T.FOF f)               -> maybe False ((> 1) . heads) (collectDisjuncts f)
  _                                   -> False
  where
    heads ls = length [ () | (T.Positive, l) <- ls, not (isReservedTLit l), not (negEq l) ]
    negEq (T.Equality _ T.Negative _) = True
    negEq _                           = False
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
  -- the paper's order puts the provider, whose atom is consumed, at p0 and
  -- the consumer at p1
  Just True  -> False
  Just False -> True
  Nothing    -> case (posHead d1, posHead d2) of
    (Just h1, _)       -> not (headInDecl h1 result)
    (Nothing, Just h2) -> headInDecl h2 result
    (Nothing, Nothing) -> True  -- both non-unit, keep the original order
  where
    -- Like headLitOf, but a disequality atom (s != t) counts as a negative
    -- literal.  headLitOf treats it as positive, which hid the true head of
    -- clauses like g(X) != X | q(X).  Both heads came back Nothing, the order
    -- was kept, and the provider could land right of its consumer, forcing a
    -- skip and retry during translation.
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
-- Which premise of a binary resolution consumes.  Its head is what the
-- resolvent's head instantiates, and all but one of its body literals reappear,
-- the missing one resolved against the other head.  Nothing when a clause is
-- unavailable or both or neither qualify, and the caller then guesses by name.
-- This gives the paper's tree order with the provider at p0.
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
