-- Reads a TSTP proof into the tree the algorithm works on, with positions as
-- binary strings, ⊥ at ε, each inference's provider at child 0 and its
-- consumer at child 1. It also traces clauses to their sources, reads the
-- equation steps, and refuses a proof outside the Horn fragment or calculus.
module ProofTree
  ( buildProofInfo
  , classifyRole
  , inlineAtomCongruences
  , resolveCopySource
  , equationSteps
  , equationRuleNames
  , coreInferenceNames
  , RuleReading (..)
  , inferenceReading
  , findRoot
  , reachedNames
  ) where
import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Control.Applicative ((<|>))
import Control.Monad (forM, guard, when)
import Data.List (inits, nub, sortBy, tails)
import Data.List.NonEmpty (toList)
import Data.Maybe (catMaybes, fromMaybe, isJust, listToMaybe)
import Data.Ord (comparing)
import Data.TPTP.Pretty ()
import Types
import Helpers (applySubstLit, applySubstTerm, clauseInstance, variantKey, flipLit, litSubtermCtxs,
                mapLiteralTerms, matchLit, matchLitWith, matchTerm, notVar, picks, polLits, replaceAllTerm,
                rewritesFrom, suffixVarsLit, unifyTerms, instClause, resolveHead, suffixVarsClause)
import Conjecture
import TptpConvert

-- The refutation as a tree of named clauses. A node holds its rule and
-- premises. A node named "?" is a clause inside a nested inference, which the
-- proof never prints.
data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)

-- The electrons, nuclei and goal atoms of a proof, with the clause, unit and
-- rule at each position. A proof outside the Horn fragment or the calculus is
-- refused with a message.
buildProofInfo :: [T.Unit] -> Either String ProofInfo
buildProofInfo allUnits = do
  root <- maybe (Left "the proof never derives $false") Right (findRoot allUnits)
  let unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
  mapM_ (\n -> Left ("incomplete proof, it cites " ++ n ++ ", which it does not contain"))
        (take 1 [ n | n <- reachedNames unitMap root, Map.notMember n unitMap ])
  let tree    = buildProofTree allUnits root
      resolve = resolveCopySource unitMap
      -- the clauses the conjecture grants as hypotheses
      granted = maybe [] (uncurry (++)) (conjectureHypotheses allUnits)
      leafRows  = gatherLeaves "" tree
      innerRows = gatherInner  "" tree
      mkLeaf (pos, name, decl) =
        let srcName = if isNegConj decl then name
                      else let r = resolve name
                           -- a clause from an introduced definition keeps its
                           -- own name, as the equivalence behind it is not Horn
                           in if isIntroducedSrc unitMap r && r /= name then name else r
            -- The leaf states its source formula when that is a single Horn
            -- clause, and its own clause otherwise. The negated conjecture
            -- always keeps its source, which the goal reading expects.
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
        , leHyp     = isNegationHypothesis granted unitMap name decl
        }
      mkInner (pos, name, decl) = LeafEntry
        { lePos     = pos
        , leUnit    = name
        , leName    = name
        , leDecl    = decl
        , leSrcDecl = decl   -- a derived clause is its own source
        , leRole    = Derived
        , leHyp     = False
        }
      byPos  = sortBy (comparing lePos)
      leafEntries    = map mkLeaf  leafRows
      innerEntries    = map mkInner innerRows
      electrons = byPos $
                    [e | e <- leafEntries, isPositiveUnitFormula (leDecl e)] ++
                    [e | e <- innerEntries, isPositiveUnitFormula (leDecl e)]
      nuclei    = byPos $
                    [e | e <- leafEntries, not (isPositiveUnitFormula (leDecl e))] ++
                    [e | e <- innerEntries, not (isPositiveUnitFormula (leDecl e))]
  -- Only the clauses the refutation uses have to be Horn.
  mapM_ (\n -> Left ("unsupported proof, clause " ++ n ++ " is not Horn"))
        (take 1 [ n | (_, n, d) <- leafRows ++ innerRows, isNonHorn d ])
  mapM_ Left (calculusViolation unitMap root)
  mapM_ (\n -> Left ("unsupported proof, unit " ++ n
                     ++ " uses distinct objects, whose inequality is a theory fact outside the calculus"))
        (take 1 [ unitNameStr n | T.Unit n d _ <- allUnits, usesDistinctObjects d ])
  conjecture <- mapM readConjecture (listToMaybe (conjectureFormulas allUnits))
  -- if no leaf mentions a symbol, the prover refuted the conjecture by
  -- formula simplification, which no clause inference shows
  when (all (\(_, _, d) -> let (fs, ps) = declSymbols d in null fs && null ps) leafRows) $
    Left "unsupported proof, the prover reduced the conjecture to a truth constant by formula simplification, outside the supported calculus of resolution, superposition, demodulation and equality resolution"
  -- The goal atoms come from the conjecture unit, which provers do not split
  -- or simplify. Failing that, from the negated conjecture clause closest to
  -- the root, then an all-negative axiom, and for a negated conclusion the
  -- closest derived all-negative clause.
  let byDepth = sortBy (comparing (\e -> (length (lePos e), lePos e)))
      negatedConclusion = maybe False (\c -> null (cjGoals c) && not (null (cjNegated c))) conjecture
  rawGoalLits <- maybe (Left "no clause of the proof states the goal") Right
            $ case extractConjectureGoals allUnits of
    Just lits -> Just lits
    Nothing   -> listToMaybe $
      -- the source's statement, or the clause's own when the source is no
      -- negated conjunction of atoms, as with Twee's negate_conjecture
      [ lits
      | e <- byDepth [ e' | e' <- nuclei, leRole e' == NegConjecture ]
      , let goalDecl = fromMaybe (leDecl e) (lookupDecl unitMap (leName e))
      , Just lits <- [extractGoalLits goalDecl <|> extractGoalLits (leDecl e)]
      ] ++
      -- a UEQ problem states its negated conjecture as a disequality axiom
      -- without the negated_conjecture role
      [ lits
      | e <- nuclei, leRole e == OrigAxiom
      , Just lits <- [extractGoalLits (leDecl e)]
      ] ++
      [ lits
      | negatedConclusion
      , e <- byDepth [ e' | e' <- nuclei, leRole e' == Derived ]
      , Just lits <- [extractGoalLits (leDecl e)]
      ]
  -- A goal atom that abbreviates an introduced formula stands for its atoms.
  -- If that formula is no conjunction of atoms, the goal is not Horn.
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
  let -- every prefix of an entry position, plus the sibling of each prefix
      wanted = Set.toList $ Set.fromList $ concat
        [ p : [ init p ++ [sib] | not (null p), let sib = if last p == '0' then '1' else '0' ]
        | e <- electrons ++ nuclei
        , p <- inits (lePos e) ]
      nodes   = [ (p, t) | p <- wanted, Just t <- [nodeByPath tree p] ]
      declMap = Map.fromList [ (p, ptDeclOf t) | (p, t) <- nodes ]
      unitAt  = Map.fromList [ (p, ptNameOf t) | (p, t) <- nodes ]
      -- the rule that concludes each clause, for a nested inference the rule
      -- of its outermost step, so cn(rw(spm(A,B),C)) gives rw
      ruleAt  = Map.fromList
        [ (p, Text.unpack (lastStep n r)) | (p, PTNode n _ r _) <- nodes ]
      lastStep n r = case maybe [] unitStepRules (Map.lookup n unitMap) of
        rs@(_ : _) | n /= "?" -> last rs
        _                     -> r
  return ProofInfo
    { piElectrons = electrons
    , piNuclei    = nuclei
    , piGoalLits  = goalLits
    , piDeclAt    = declMap
    , piUnitAt    = unitAt
    , piRuleAt    = ruleAt
    }

-- Follows a position down the tree, numbering children as gatherLeaves and
-- gatherInner do. A unary node has its child at 1.
nodeByPath :: ProofTree -> String -> Maybe ProofTree
nodeByPath t [] = Just t
nodeByPath (PTLeaf _ _) _ = Nothing
nodeByPath (PTNode _ _ _ kids) (c : rest) =
  case kids of
    [k]  -> if c == '1' then nodeByPath k rest else Nothing
    _ -> let i = fromEnum c - fromEnum '0'
         in if i >= 0 && i < length kids then nodeByPath (kids !! i) rest else Nothing

-- The clause at a tree node.
ptDeclOf :: ProofTree -> T.Declaration
ptDeclOf (PTLeaf _ d)     = d
ptDeclOf (PTNode _ d _ _) = d

-- The unit name at a tree node.
ptNameOf :: ProofTree -> String
ptNameOf (PTLeaf n _)     = n
ptNameOf (PTNode n _ _ _) = n

-- The tree below the root, the last $false unit. A core inference is a node
-- with its provider first and its consumer second, and any other unit is a
-- leaf. Every unit the root reaches is in the proof, as buildProofInfo checks.
buildProofTree :: [T.Unit] -> String -> ProofTree
buildProofTree allUnits root = expandedNodes Map.! root
  where
    units = Map.fromList [(unitNameStr n, (d, u)) | u@(T.Unit n d _) <- allUnits]
    -- One node per unit, so a shared clause is built once. The strict map
    -- forces only to WHNF, so children stay lazy, and as the proof is acyclic
    -- forcing them terminates.
    expandedNodes :: Map.Map String ProofTree
    expandedNodes = Map.mapWithKey buildNode units
    expandMemo name = expandedNodes Map.! name
    buildNode name (decl, u) = case coreParentNames u of
      Nothing      -> PTLeaf name decl
      Just parents ->
        let rule = fromMaybe Text.empty (inferenceRuleName u)
        in PTNode name decl rule (orderedChildren decl rule (unitStepRules u) parents)
    orderedChildren decl rule steps parents = case parents of
      [p1n, p2n] ->
        let d1 = declOf p1n; d2 = declOf p2n
            (ln, rn) = if firstParentProvides rule decl d1 d2
                       then (p1n, p2n) else (p2n, p1n)
        in [expandMemo ln, expandMemo rn]
      (p0:p1:p2:rest) ->
        -- An inference of several steps, as E's cn(rw(spm(A,B),L)), where p0 and
        -- p1 combine first and each later premise simplifies. The clauses between
        -- are replayed into "?" nodes. Failing that, each is the complement of the
        -- last unit when the outer clause is ⊥, and the outer clause otherwise.
        let eqs  = p1:p2:rest
            -- The last premise is the provider when it is a positive unit, or
            -- when the binary-step test against the last replayed clause says
            -- so, as for c_0_37 in csr(spm(c_0_35,c_0_36),c_0_37) on ANA027-2.
            lastD = declOf (last eqs)
            lastIsProvider = isPositiveUnitFormula lastD
              || maybe False (\(_, ds) -> not (firstParentProvides (ruleOfStep (length eqs - 1)) decl (last ds) lastD)) replayed
            fallbackDecl
              | declIsBottom decl, not lastIsProvider
              = fromMaybe decl (complementOfNegUnit lastD)
              | declIsBottom decl
              = fromMaybe decl (complementOfPosUnit lastD)
              | otherwise = decl
            replayed = replayNested decl (declOf p0) (map declOf eqs)
            innerDecls = maybe (replicate (length eqs - 1) fallbackDecl) snd replayed
            p0Provides = maybe False fst replayed
            -- each step's own rule when the inference names one per step
            ruleOfStep j = if length steps == length eqs then steps !! j else rule
            first = PTNode "?" (head innerDecls) (ruleOfStep 0)
                      (if p0Provides then [expandMemo p0, expandMemo p1]
                                     else [expandMemo p1, expandMemo p0])
            inner = foldl (\r (j, (eq, d)) -> PTNode "?" d (ruleOfStep j) [expandMemo eq, r])
                          first (zip [1 ..] (zip (drop 1 (init eqs)) (drop 1 innerDecls)))
        in if lastIsProvider
           then [expandMemo (last eqs), inner]
           else [inner, expandMemo (last eqs)]
      _ -> map expandMemo parents
    declOf n = fst (units Map.! n)

-- The positive unit L of a negative unit ~L. It stands in for an unreplayed
-- "?" clause that ~L resolves to ⊥.
complementOfNegUnit :: T.Declaration -> Maybe T.Declaration
complementOfNegUnit (T.Formula _ (T.CNF (T.Clause lits))) =
  case toList lits of
    [(T.Negative, lit)] ->
      Just (T.Formula (T.Standard T.Plain) (T.CNF (T.Clause (pure (T.Positive, lit)))))
    _ -> Nothing
complementOfNegUnit _ = Nothing

-- The equation steps of the proof, each as its conclusion and two premises.
-- A nested or many-premise step is split at the clauses its replay finds, and
-- the positive units among them are returned under new names <unit>_stepK.
equationSteps :: [T.Unit] -> ([(String, String, String)], [(String, T.Declaration)])
equationSteps units = (concatMap fst found, concatMap snd found)
  where
    declOf = Map.fromList [ (unitNameStr n, d) | T.Unit n d _ <- units ]
    found = [ r | T.Unit n d (Just (src@(T.Inference {}), _)) <- units
                , Just r <- [stepsOf (unitNameStr n) d src] ]
    equation r = r `elem` equationRuleNames
    -- Every Twee rewriting step counts. An E or Vampire step counts only when
    -- it derives a positive unit from two, since the same rules also derive
    -- nuclei and resolve a nucleus with a unit.
    unit p = maybe False isPositiveUnitFormula (Map.lookup p declOf)
    stepsOf n d src = case sourceParents src of
      [p1, p2]
        | all equation (sourceRules src)
        , sourceRules src == [Text.pack "rewriting"] || (isPositiveUnitFormula d && unit p1 && unit p2)
        -> Just ([(n, p1, p2)], [])
      _ -> do
        (p0, (rule0, p1) : later@(_ : _)) <- inferenceSteps src
        ds <- mapM (`Map.lookup` declOf) (p0 : p1 : map snd later)
        (_, inner) <- replayNested d (head ds) (tail ds)
        if length inner /= length later then Nothing else do
          let name j = if j < length inner then n ++ "_step" ++ show (j + 1) else n
              concls = inner ++ [d]
              steps  = (rule0, p0, p1) : [ (r, name (j - 1), p) | (j, (r, p)) <- zip [1 ..] later ]
          let unitAt p = unit p || or [ isPositiveUnitFormula c | (j, c) <- zip [0 ..] inner, name j == p ]
          return ( [ (name j, a, b) | (j, (r, a, b)) <- zip [0 ..] steps
                                    , equation r, isPositiveUnitFormula (concls !! j), unitAt a, unitAt b ]
                 , [ (name j, c) | (j, c) <- zip [0 ..] inner, isPositiveUnitFormula c ] )

-- The rules whose steps are read as rewrites with their premises.
equationRuleNames :: [Text.Text]
equationRuleNames = map Text.pack
  [ "rewriting"                                                       -- Twee
  , "superposition", "forward_demodulation", "backward_demodulation"  -- Vampire
  , "definition_unfolding"
  , "spm", "pm", "rw", "cn" ]                                         -- E

-- An inference as a chain of binary steps. Returns the first premise and,
-- innermost first, the rule and other premise of each step. E nests steps, as
-- sr(rw(spm(A,B),C),D), where a one-premise rule like cn is no step. Vampire
-- lists them flat, as definition_unfolding [A,B,C].
inferenceSteps :: T.Source -> Maybe (String, [(Text.Text, String)])
inferenceSteps (T.Inference (T.Atom r) _ ps) = case ps of
  [T.Parent i@(T.Inference {}) _] -> inferenceSteps i
  [T.Parent i@(T.Inference {}) _, T.Parent (T.UnitSource c) _] ->
    fmap (++ [(r, unitNameStr c)]) <$> inferenceSteps i
  T.Parent (T.UnitSource a) _ : more@(_ : _)
    | Just cs <- mapM unitSource more -> Just (unitNameStr a, [ (r, c) | c <- cs ])
  _ -> Nothing
  where
    unitSource (T.Parent (T.UnitSource c) _) = Just (unitNameStr c)
    unitSource _                             = Nothing
inferenceSteps _ = Nothing

-- Replays a nested inference. Resolves or superposes c0 with c1, simplifies by
-- each later premise, and accepts a replay that ends in the printed clause.
-- Returns whether c0 provides in the first step, and the clauses between,
-- innermost first.
replayNested :: T.Declaration -> T.Declaration -> [T.Declaration] -> Maybe (Bool, [T.Declaration])
replayNested outerD d0 ds = do
  outer <- convertDeclToClause outerD
  c0    <- convertDeclToClause d0
  cs    <- mapM convertDeclToClause ds
  (c1, units0) <- case cs of { (x : xs) -> Just (x, xs); [] -> Nothing }
  -- each later premise is renamed apart, so a unit used twice, as c_0_8 on
  -- PHI011+1, shares no variables with conditions an earlier use brought in
  let units = [ Clause (map (suffixVarsLit sfx) bs) (fmap (suffixVarsLit sfx) mh)
              | (i, Clause bs mh) <- zip [1 :: Int ..] units0, let sfx = "_s" ++ show i ]
      steps = init units
      -- The first replay from clause r at step k to the printed clause.
      -- Different rewrites often reach the same clause, so a clause that
      -- failed at a step is not tried there again. Without this, ALG210+2
      -- takes minutes.
      walk failed k r
        | Set.member key failed = (Nothing, failed)
        | otherwise = case result of
            (Nothing, f) -> (Nothing, Set.insert key f)
            found        -> found
        where
          key = (k, variantKey r)
          result
            | k == length steps =
                ( listToMaybe [ ([r], σ) | final0 <- simplifyBy r (last units)
                                         , final <- final0 : eqResolutions final0
                                         , Just σ <- [matchClause final outer] ]
                , failed )
            -- an equality resolution the prover folded in, as E's er, may
            -- precede any simplification
            | otherwise = firstOf failed [ r' | r1 <- r : eqResolutions r, r' <- simplifyBy r1 (steps !! k) ]
          firstOf f [] = (Nothing, f)
          firstOf f (r' : rs) = case walk f (k + 1) r' of
            (Just (chain, σ), f') -> (Just (r : chain, σ), f')
            (Nothing, f')         -> firstOf f' rs
      tryFrom _ [] = Nothing
      tryFrom failed ((prov, r) : rest) = case walk failed (0 :: Int) r of
        (Just (chain, σ), _) -> Just (prov, map (clauseToDecl . instClause σ) chain)
        (Nothing, failed')   -> tryFrom failed' rest
  -- The resolvent is condensed before simplifying, since a premise may bring
  -- along a body atom the other clause already has. Removing one copy with a
  -- unit would leave the other behind, as on MGT006-1.
  tryFrom Set.empty [ (prov, condense r0) | (prov, r0) <- resolvents c0 c1 ]
  where
    eqResolutions (Clause bs mh) =
      [ instClause σ (Clause (before ++ after) mh)
      | (before, Eq s t : after) <- zip (inits bs) (tails bs)
      , Just σ <- [unifyTerms s t []] ]

-- Every resolvent and superposition of two clauses, renamed apart. The flag is
-- True when the first clause is the provider, the one whose head is used.
resolvents :: Clause -> Clause -> [(Bool, Clause)]
resolvents a b =
  [ (True, r) | r <- headInto a b' ] ++ [ (False, r) | r <- headInto b' a ]
  where
    b' = suffixVarsClause "_q" b
    headInto x y = resolveHead x y ++ case hd x of
      Nothing -> []
      Just h  ->
        -- superposition of an equation head into any literal, at one
        -- occurrence or at all of them, since a prover demodulating with the
        -- equation replaces them all, as on LAT263-2
        [ instClause σ (Clause (body x ++ bodyY') hdY')
           | Eq s t <- [h], (lhs, rhs) <- [(s, t), (t, s)], rewritesFrom lhs rhs
           , (i, lit) <- zip [0 :: Int ..] (polLits y)
           , (u, ctx) <- litSubtermCtxs (snd lit), notVar u
           , Just σ <- [unifyTerms lhs u []]
           , ys <- [ [ if j == i then (fst l, ctx rhs) else l
                     | (j, l) <- zip [0 :: Int ..] (polLits y) ]
                   , [ (sg, mapLiteralTerms (replaceAllTerm u rhs) m)
                     | (sg, m) <- polLits y ] ]
           , let bodyY' = [ l | (False, l) <- ys ]
                 hdY'   = listToMaybe [ l | (True, l) <- ys ] ]

-- One simplification step, as E's rw, sr, csr and cn perform it. A simplifier
-- with a head resolves away a body atom of the clause and adds its own body,
-- and a unit equation rewrites in either direction. The result is condensed
-- as cn does.
simplifyBy :: Clause -> Clause -> [Clause]
simplifyBy c u@(Clause _ (Just _)) =
  map condense $
    resolveHead u' c
    ++ [ c' | Clause [] (Just (Eq s t)) <- [u']
            , (lhs, rhs) <- [(s, t), (t, s)], rewritesFrom lhs rhs
            , c' <- rewriteOnce (lhs, rhs) c ]
  where
    u' = suffixVarsClause "_u" u
-- An all-negative simplifier with a literal matching the clause's head removes
-- that head and adds its other literals, instantiated, to the body, as E's csr
-- does. With one literal this is plain simplify-reflect.
simplifyBy c (Clause ls Nothing) =
    [ condense (Clause (body c ++ map (applySubstLit σ) rest) Nothing)
    | Just h <- [hd c]
    , (l, rest) <- picks (map (suffixVarsLit "_u") ls)
    , l' <- [l, flipLit l]
    , Just σ <- [matchLit l' h] ]

-- One demodulation step, rewriting a single redex at that occurrence or at
-- every occurrence of the same subterm. Provers record each application as
-- its own rw step, so nothing is iterated. No term ordering is needed, and a
-- permutative equation like u(X,X,Y) = u(Y,X,X) stays usable.
rewriteOnce :: (Term, Term) -> Clause -> [Clause]
rewriteOnce (lhs, rhs) (Clause bs mh) =
  [ Clause [ l | (False, l) <- ls' ] (listToMaybe [ l | (True, l) <- ls' ])
  | let ls = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]
  , (i, (_, lit)) <- zip [0 :: Int ..] ls
  , (u, ctx) <- litSubtermCtxs lit
  , notVar u
  , Just s <- [matchTerm lhs u]
  , let r = applySubstTerm s rhs
  , ls' <- [ [ if j == i then (sg, ctx r) else (sg, m) | (j, (sg, m)) <- zip [0 :: Int ..] ls ]
           , [ (sg, mapLiteralTerms (replaceAllTerm u r) m) | (sg, m) <- ls ] ] ]

-- Condenses a clause by dropping duplicate body atoms and body equations t = t.
condense :: Clause -> Clause
condense (Clause bs mh) = Clause (nub [ l | l <- bs, not (trivial l) ]) mh
  where
    trivial (Eq s t) = s == t
    trivial _        = False

-- A substitution that turns the replayed clause into the printed one. Each
-- replayed literal matches a printed literal of the same sign and every
-- printed literal is hit. Two replayed literals may hit the same one, as when
-- E's csr brings in a condition the clause already has.
matchClause :: Clause -> Clause -> Maybe Subst
matchClause final outer
  | isJust (hd final) /= isJust (hd outer) = Nothing
  | otherwise = listToMaybe (go (polLits final') [] [])
  where
    ren = suffixVarsLit "_f"
    final' = Clause (map ren (body final)) (fmap ren (hd final))
    idxOuter = zip [0 :: Int ..] (polLits outer)
    go [] hit s
      | all ((`elem` hit) . fst) idxOuter = [s]
      | otherwise = []
    go ((b, l) : ls) hit s =
      [ s'' | (i, (b', p)) <- idxOuter, b == b'
            , s' <- catMaybes [matchLitWith l p s, matchLitWith (flipLit l) p s]
            , s'' <- go ls (i : hit) s' ]

-- The negative unit ~L of a positive atom L, the converse of complementOfNegUnit. An
-- equation has none, since a ⊥ reached by rewriting with it does not
-- determine the clause before it.
complementOfPosUnit :: T.Declaration -> Maybe T.Declaration
complementOfPosUnit (T.Formula _ (T.CNF (T.Clause lits))) =
  case toList lits of
    [(T.Positive, lit@(T.Predicate (T.Defined _) _))] ->
      Just (T.Formula (T.Standard T.Plain) (T.CNF (T.Clause (pure (T.Negative, lit)))))
    _ -> Nothing
complementOfPosUnit _ = Nothing

-- The leaves with their positions. An electron is kept once, at its first
-- position in depth-first order. A nucleus appears at every position, since
-- each occurrence may see different electrons, and a shared inner node
-- re-emits its nuclei at the new position without being walked again.
gatherLeaves :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherLeaves pos0 tree0 =
    let (_, _, res) = go pos0 tree0 Set.empty Map.empty in res
  where
    -- seenElec holds the electrons met, seenInner each inner node's nucleus
    -- leaves with positions relative to it.
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
              let reemit = [(pos ++ rel, nm, d) | (rel, nm, d) <- stored]
              in (seenElec, seenInner, reemit)
            Nothing ->
              let (se', si', res) = goKids pos kids seenElec seenInner
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

-- The inner nodes with their positions, each named unit once but every "?"
-- node, since each is a clause of its own. A named node met again re-emits
-- the "?" nodes below it without walking its subtree. Walking every path
-- would take 3 x 10^11 visits on BOO023-1.
gatherInner :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherInner pos0 tree0 = let (_, _, res) = go pos0 tree0 Set.empty Map.empty in res
  where
    go _ (PTLeaf _ _) seen memo = (seen, memo, [])
    go pos (PTNode n d rule kids) seen memo
      | n /= "?", Just rel <- Map.lookup n memo =
          (seen, memo, [ (pos ++ p, nm, dd) | (p, nm, dd) <- rel ])
      | otherwise =
          let (seen', memo', kidsRes) = goKids pos kids seen memo
              (seen'', inner)         = addNode pos n d rule seen'
              res   = kidsRes ++ inner
              memo'' | n /= "?"  = Map.insert n [ (drop (length pos) p, nm, dd) | (p, nm, dd) <- res, nm == "?" ] memo'
                     | otherwise = memo'
          in  (seen'', memo'', res)
    goKids pos [k] seen memo = go (pos ++ "1") k seen memo
    goKids pos [l, r] seen memo =
      let (seen',  memo',  ls) = go (pos ++ "0") l seen memo
          (seen'', memo'', rs) = go (pos ++ "1") r seen' memo'
      in  (seen'', memo'', ls ++ rs)
    goKids pos kids seen memo =
      foldl (\(s, m, acc) (c, kid) ->
               let (s', m', res) = go (pos ++ [c]) kid s m
               in  (s', m', acc ++ res))
            (seen, memo, []) (zip ['0'..] kids)
    addNode pos n d rule seen
      | rule == Text.pack "proved_conjecture" = (seen, [])
      | n == "?"               = (seen, [(pos, n, d)])
      | Set.member n seen      = (seen, [])
      | otherwise              = (Set.insert n seen, [(pos, n, d)])

-- The role of a leaf. Inputs, introduced definitions and the conjecture's
-- hypotheses are axioms, the rest of the negated conjecture is the goal, and
-- anything else is derived.
classifyRole :: [Clause] -> Map.Map String T.Unit -> String -> T.Declaration -> LeafRole
classifyRole granted unitMap name decl
  -- input positive units are axioms even when labeled negated_conjecture,
  -- as Vampire labels every input when proving the negation
  | isPositiveUnitFormula decl && isFileUnit unitMap name     = OrigAxiom
  | isPositiveUnitFormula decl && isFileUnit unitMap resolvedNm = OrigAxiom
  | isConjHypothesis granted unitMap name decl                = OrigAxiom
  | isNegConj decl                                           = NegConjecture
  | maybe False isNegConj (lookupDecl unitMap resolvedNm)    = NegConjecture
  -- a clause traced back to the conjecture is part of its negation
  | maybe False isConjectureDecl (lookupDecl unitMap resolvedNm)   = NegConjecture
  | isFileUnit unitMap name                                    = OrigAxiom
  | isFileUnit unitMap resolvedNm                              = OrigAxiom
  -- clauses from definitions the prover introduced, like E's epredN, count
  -- as axioms
  | isIntroducedSrc unitMap resolvedNm                        = OrigAxiom
  | otherwise                                                 = Derived
  where
    resolvedNm = resolveCopySource unitMap name

-- Whether a declaration has the negated_conjecture role.
isNegConj :: T.Declaration -> Bool
isNegConj (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegConj _                                              = False

-- A negated conjecture clause is a hypothesis when it has a head or the
-- conjecture grants it. Any other is the negated conclusion, the goal. The
-- clause may carry the negated_conjecture role itself or be a plain copy of a
-- unit that does, as TPTP's own tools write it.
isConjHypothesis :: [Clause] -> Map.Map String T.Unit -> String -> T.Declaration -> Bool
isConjHypothesis granted unitMap name decl =
  (hasHead || grantedClause)
  && (isNegConj decl || csNeg)
  && (Map.notMember cs unitMap || isFileUnit unitMap cs || csNeg)
  where
    cs    = resolveCopySource unitMap name
    csNeg = maybe False isNegConj (lookupDecl unitMap cs)
    -- a disequality is a negated goal, not a head
    clause  = convertDeclToClause decl
    hasHead = maybe False (isJust . hd) clause
    grantedClause = maybe False (\c -> any (`clauseInstance` c) granted) clause

-- A conjecture hypothesis that the prover obtained by negating the conjecture.
-- Negated conjecture clauses stated in the problem file are inputs instead.
isNegationHypothesis :: [Clause] -> Map.Map String T.Unit -> String -> T.Declaration -> Bool
isNegationHypothesis granted unitMap name decl =
  isConjHypothesis granted unitMap name decl
  && maybe False isNegConj (lookupDecl unitMap cs)
  && not (isFileUnit unitMap cs)
  where cs = resolveCopySource unitMap name

-- The rule that negates the conjecture, under the names Vampire, TPTP tools,
-- Twee and E use. Source tracing stops there, or a negated goal clause would
-- trace back to the conjecture itself.
isNegationRule :: Text.Text -> Bool
isNegationRule r = r `elem` map Text.pack ["negated_conjecture", "negate", "negate_conjecture", "assume_negation"]

-- Whether a source negates the conjecture, at its top or nested, as in E's
-- fof_simplification(assume_negation(c)).
sourceNegates :: T.Source -> Bool
sourceNegates (T.Inference (T.Atom rule) _ ps) =
  isNegationRule rule || or [ sourceNegates s | T.Parent s _ <- ps ]
sourceNegates _ = False

-- The unit a clause copies, traced back through unit references and steps
-- like cnf_transformation that copy one premise. A definition the step cites
-- is no premise, unless the step rests on it alone, as when E splits one. A
-- core inference or the negation step stops the trace, so a clause traces to
-- the input it copies or to itself.
resolveCopySource :: Map.Map String T.Unit -> String -> String
resolveCopySource unitMap = go
  where
    go name = case Map.lookup name unitMap of
      Just (T.Unit _ _ (Just (T.UnitSource parentName, _))) ->
        go (unitNameStr parentName)
      Just (T.Unit _ _ (Just (src@(T.Inference (T.Atom rule) _ ps), _)))
        | not (Set.member rule coreInferenceNames)
        , not (sourceNegates src)
        , let prems = concatMap parentUnits ps
        , [pn] <- case filter (not . isIntroducedSrc unitMap) prems of { [] -> prems; rest -> rest }
        -> go pn
      _ -> name

-- The rules whose steps become nodes of the proof tree. A unit derived by any
-- other rule is a leaf and is traced back as a copy of its premise.
coreInferenceNames :: Set.Set Text.Text
coreInferenceNames = Set.fromList $ map Text.pack
  [ "resolution", "resolve", "superposition", "paramodulation"
  , "equality_resolution"
  , "forward_subsumption_resolution", "backward_subsumption_resolution"
  , "condensation", "condense"   -- Vampire's and E's names for condensation
  , "definition_unfolding", "trivial_inequality_removal"
  , "forward_demodulation", "backward_demodulation"
  , "duplicate_literal_removal", "subsumption_resolution"
  , "spm", "sr", "csr", "er", "rw", "cn", "pm"
  , "proved_conjecture"
  -- E's propositional refutation, which PropRes expands into resolutions
  , "cdclpropres"
  , "rewriting" ]  -- Twee's rewriting creates new equations and expands into the tree

-- Rules outside the paper's calculus. calculusViolation refuses these, and
-- also any unlisted rule with several premises, rather than reading the step
-- as a copy of a premise.
outsideCalculus :: Text.Text -> Bool
outsideCalculus r = Set.member r outside || Text.pack "avatar_" `Text.isPrefixOf` r
  where
    outside = Set.fromList $ map Text.pack
      [ "factoring", "equality_factoring", "ef"   -- factoring, for non-Horn clauses
      , "ar"                                       -- E's AC resolution
      , "unit_resulting_resolution", "global_subsumption" ]

-- How the translation reads an inference, with the reason for a refusal.
data RuleReading = TreeStep | RewriteStep | Copy | Refused String

-- How the translation reads one inference. A rule outside the calculus, or an
-- unlisted rule on several premises, is refused. An equation rule is read as
-- rewrites, any other core rule becomes a tree node, and the rest copy their
-- premise.
inferenceReading :: Map.Map String T.Unit -> Text.Text -> [T.Parent] -> RuleReading
inferenceReading unitMap rule ps
  | outsideCalculus rule = Refused (Text.unpack rule)
  | not (Set.member rule coreInferenceNames), not (isNegationRule rule)
  , length (filter premise ps) > 1 = Refused (Text.unpack rule ++ " on several premises")
  | rule `elem` equationRuleNames = RewriteStep
  | Set.member rule coreInferenceNames = TreeStep
  | otherwise = Copy
  where
    -- a definition that a Skolemization or definition step cites is no premise
    premise (T.Parent (T.UnitSource pn) _) = not (isIntroducedSrc unitMap (unitNameStr pn))
    premise (T.Parent (T.Inference {}) _)  = True
    premise _                              = False

-- A refusal message for the first step the refutation reaches that uses a
-- rule outside the calculus or an unlisted rule on several premises.
calculusViolation :: Map.Map String T.Unit -> String -> Maybe String
calculusViolation unitMap root = listToMaybe
  [ "unsupported proof, step " ++ n ++ " uses " ++ bad
    ++ ", an inference outside the supported calculus of resolution, "
    ++ "superposition, demodulation and equality resolution"
  | n <- reachedNames unitMap root
  , Just (T.Unit _ _ (Just (src, _))) <- [Map.lookup n unitMap]
  , Just bad <- [check src] ]
  where
    check (T.Inference (T.Atom rule) _ ps) = case inferenceReading unitMap rule ps of
      Refused why -> Just why
      _           -> listToMaybe (catMaybes [ check s | T.Parent s _ <- ps ])
    check _ = Nothing

-- The names of the units the refutation reaches from its root, each once and
-- in depth-first order, with any it cites but does not contain.
reachedNames :: Map.Map String T.Unit -> String -> [String]
reachedNames unitMap root = go Set.empty [root]
  where
    go _ [] = []
    go seen (n : rest)
      | Set.member n seen = go seen rest
      | otherwise = n : go (Set.insert n seen) (maybe [] unitParents (Map.lookup n unitMap) ++ rest)

-- Twee treats predicates as functions, so it may derive an equation between
-- two atoms p(s) = p(t) by rewriting reflexivity with term equations. Every
-- citation of such an equation is replaced by those term equations, which
-- keeps the proof first-order.
inlineAtomCongruences :: [T.Unit] -> [T.Unit]
inlineAtomCongruences units
  | Map.null congr = units
  | otherwise      = map replaceIn units
  where
    unitMap = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n _ _) <- units ]
    nameOf  = Map.fromList [ (unitNameStr n, n) | T.Unit n _ _ <- units ]
    predSyms = predicateSymbols units
    ruleOf nm = Map.lookup nm unitMap >>= inferenceRuleName
    parentsOf (T.Unit _ _ (Just (T.Inference _ _ ps, _))) = [ unitNameStr n | T.Parent (T.UnitSource n) _ <- ps ]
    parentsOf _ = []
    isCongruenceEquation d = case headLitOf d of
      Just (T.Equality (T.Function (T.Defined (T.Atom f)) _) T.Positive (T.Function (T.Defined (T.Atom g)) _)) ->
        f == g && Set.member (Text.unpack f) predSyms && isPositiveUnitFormula d
      _ -> False
    -- the term equations an atom equation was built from, in order
    congr = Map.fromList
      [ (nm, eqs) | (nm, u@(T.Unit _ d _)) <- Map.toList unitMap
                  , ruleOf nm == Just (Text.pack "rewriting"), isCongruenceEquation d
                  , Just eqs <- [built u] ]
    built u = do
      let ps = parentsOf u
      guard (any (\p -> ruleOf p == Just (Text.pack "reflexivity")) ps)
      return [ p | p <- ps, ruleOf p /= Just (Text.pack "reflexivity") ]
    replaceIn u@(T.Unit n d (Just (T.Inference r info ps, extra))) =
      let ps' = concatMap swap ps
      in if ps' == ps then u else T.Unit n d (Just (T.Inference r info ps', extra))
    replaceIn u = u
    swap p@(T.Parent (T.UnitSource n) _) = case Map.lookup (unitNameStr n) congr of
      Just eqs -> [ T.Parent (T.UnitSource e) [] | Just e <- map (`Map.lookup` nameOf) eqs ]
      Nothing  -> [p]
    swap p = [p]

-- The premises of a unit derived by a core inference, Nothing for any other.
coreParentNames :: T.Unit -> Maybe [String]
coreParentNames (T.Unit _ _ (Just (src@(T.Inference (T.Atom rule) _ _), _)))
  | Set.member rule coreInferenceNames = Just (sourceParents src)
coreParentNames _ = Nothing

-- The rule of each step of a unit's inference, the innermost first.
unitStepRules :: T.Unit -> [Text.Text]
unitStepRules (T.Unit _ _ (Just (src, _))) = maybe [] (map fst . snd) (inferenceSteps src)
unitStepRules _                            = []

-- The outer rule of a derived unit.
inferenceRuleName :: T.Unit -> Maybe Text.Text
inferenceRuleName (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ _, _))) = Just rule
inferenceRuleName _ = Nothing

-- The root of the refutation, the last unit that states $false.
findRoot :: [T.Unit] -> Maybe String
findRoot units =
  case [unitNameStr n | T.Unit n decl _ <- units, declIsBottom decl] of
    [] -> Nothing
    rs -> Just (last rs)

-- A clause with more than one positive literal, where a disequality counts as
-- negative. A formula that is not a clause is not reported here.
isNonHorn :: T.Declaration -> Bool
isNonHorn d = case d of
  T.Formula _ (T.CNF (T.Clause lits)) -> not (isHornLiterals (toList lits))
  T.Formula _ (T.FOF f)               -> maybe False (not . isHornLiterals) (collectDisjuncts f)
  _                                   -> False

-- Whether a positive literal of a declaration has the needle's predicate, or
-- is an equation when the needle is one.
hasPositivePredicateOf :: T.Literal -> T.Declaration -> Bool
hasPositivePredicateOf needle (T.Formula _ (T.CNF (T.Clause lits))) =
  any (samePredicate needle) [l | (T.Positive, l) <- toList lits]
hasPositivePredicateOf needle (T.Formula _ (T.FOF f)) = fofHasPositivePredicateOf needle f
hasPositivePredicateOf _ _ = False

-- hasPositivePredicateOf for a formula. It looks at the consequent of an implication and
-- at both sides of any other connective.
fofHasPositivePredicateOf :: T.Literal -> T.UnsortedFirstOrder -> Bool
fofHasPositivePredicateOf needle (T.Quantified T.Forall _ body)    = fofHasPositivePredicateOf needle body
fofHasPositivePredicateOf needle (T.Atomic lit)                    = samePredicate needle lit
fofHasPositivePredicateOf needle (T.Connected _ T.Implication r)   = fofHasPositivePredicateOf needle r
fofHasPositivePredicateOf needle (T.Connected l _ r)               =
  fofHasPositivePredicateOf needle l || fofHasPositivePredicateOf needle r
fofHasPositivePredicateOf _ _                                      = False

-- Whether two literals have the same predicate or are both equations.
samePredicate :: T.Literal -> T.Literal -> Bool
samePredicate (T.Predicate n1 _) (T.Predicate n2 _) = n1 == n2
samePredicate (T.Equality {})    (T.Equality {})     = True
samePredicate _ _                                    = False

-- Rules that rewrite one premise with the other. Nearly every step lists the
-- clause rewritten first, but superposition and Twee's rewriting do not always.
rewriteRules :: Set.Set Text.Text
rewriteRules = Set.fromList $ map Text.pack
  [ "superposition", "paramodulation", "spm"
  , "forward_demodulation", "backward_demodulation"
  , "rw", "definition_unfolding", "rewriting" ]

-- Whether the first premise of a binary step is the provider, at child 0. A
-- rewriting step is read as its replay shows, and when the replay cannot tell,
-- the clause rewritten is taken to come first. Otherwise a unit provides to a
-- nucleus and an equation to an atom, and the replayed resolvent decides
-- between nuclei.
firstParentProvides :: Text.Text -> T.Declaration -> T.Declaration -> T.Declaration -> Bool
firstParentProvides rule result d1 d2
  | Set.member rule rewriteRules = maybe False not (consumerIsFirst result d1 d2)
firstParentProvides _ _ d1 d2
  | isPositiveUnitFormula d1 && not (isPositiveUnitFormula d2) = True
  | isPositiveUnitFormula d2 && not (isPositiveUnitFormula d1) = False
  | isPositiveUnitFormula d1 && isPositiveUnitFormula d2 =
      let isEqLitOf d = case headLitOf d of { Just (T.Equality {}) -> True; _ -> False }
      in case (isEqLitOf d1, isEqLitOf d2) of
           (True,  False) -> True
           (False, True ) -> False
           _              -> True
firstParentProvides _ result d1 d2 = case consumerIsFirst result d1 d2 of
  -- the provider goes at p0 and the consumer at p1
  Just True  -> False
  Just False -> True
  -- Otherwise only a premise with a head can provide. When both have one,
  -- the first provides unless the result still has its head predicate.
  Nothing    -> case (posHead d1, posHead d2) of
    (Just h1, Just _)  -> not (hasPositivePredicateOf h1 result)
    (Just _, Nothing)  -> True
    (Nothing, Just _)  -> False
    (Nothing, Nothing) -> True  -- neither has a head, keep the given order
  where
    -- Like headLitOf, but a disequality counts as negative, so
    -- g(X) != X | q(X) has the head q(X).
    posHead (T.Formula _ (T.CNF (T.Clause lits))) =
      single [ l | (T.Positive, l) <- toList lits, not (isTDisequality l) ]
    posHead (T.Formula _ (T.FOF f)) = fofHead (stripForall f)
    posHead _ = Nothing
    fofHead (T.Connected _ T.Implication (T.Atomic l))
      | not (isTDisequality l) = Just l
    fofHead f = single (filter (not . isTDisequality) (posLitsOfDisjFOF f))
    single [l] = Just l
    single _   = Nothing

-- Whether the first premise of a binary resolution is the consumer, the one
-- whose body atom the other's head resolves. If only one direction resolves,
-- that decides it, and otherwise the direction whose resolvent matches the
-- printed clause. Nothing when a premise is not Horn or the test is ambiguous.
consumerIsFirst :: T.Declaration -> T.Declaration -> T.Declaration -> Maybe Bool
consumerIsFirst result d1 d2 =
  case (convertDeclToClause result, convertDeclToClause d1, convertDeclToClause d2) of
    (Just r, Just c1, Just c2) ->
      let readings = resolvents c1 c2
          fits firstProvides = any (\(p, res) -> p == firstProvides && isJust (matchClause (condense res) r)) readings
      in case nub (map fst readings) of
           [firstProvides] -> Just (not firstProvides)
           _ -> case (fits True, fits False) of
                  (True, False) -> Just False
                  (False, True) -> Just True
                  _             -> Nothing
    _ -> Nothing

