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
  ) where

import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Data.List (sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Ord (comparing)
import Types

data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)

maxProofUnits :: Int
maxProofUnits = 2000

buildProofInfo :: [T.Unit] -> Maybe ProofInfo
buildProofInfo allUnits
  | length allUnits > maxProofUnits = Nothing
  | otherwise = do
  tree <- buildProofTree allUnits
  let unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      resolve = resolveSourceName unitMap
      chains  = demodChainsForLeaves resolve tree

      leafRows  = gatherLeaves "" tree
      innerRows = gatherInner  "" tree

      mkLeaf (pos, name, decl) =
        let srcName = if isNegConj decl then name else resolve name
            srcDecl = case Map.lookup srcName unitMap of
                        Just (T.Unit _ d _) -> d
                        _                   -> decl
        in LeafEntry
        { lePos     = pos
        , leName    = srcName
        , leDecl    = decl
        , leSrcDecl = srcDecl
        , leRole    = classifyRole unitMap name decl
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
  goalLits <- case extractConjectureGoals allUnits of
    Just lits -> Just lits
    Nothing   -> listToMaybe $
      [ lits
      | e <- nuclei, leRole e == NegConjecture
      , let goalDecl = fromMaybe (leDecl e) (lookupDecl unitMap (leName e))
      , Just lits <- [extractGoalLits goalDecl]
      ] ++
      -- UEQ problems: the negated conjecture is a disequality axiom (no negated_conjecture role)
      [ lits
      | e <- nuclei, leRole e == OrigAxiom
      , Just lits <- [extractGoalLits (leDecl e)]
      ]
  return ProofInfo
    { piElectrons = electrons
    , piNuclei    = nuclei
    , piGoalLits  = goalLits
    }

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
        let eqs  = p1:p2:rest
            lastIsProvider = isPositiveUnitFormula (declOf (last eqs))
            -- When the outer node derives ⊥ and the final sibling is a
            -- negative unit (~L), the synthetic intermediate derives L.
            -- Without this, "?" inherits $false and never becomes an electron.
            innerDecl
              | declIsBottom decl, not lastIsProvider
              = fromMaybe decl (posUnitOf (declOf (last eqs)))
              | otherwise = decl
            inner = foldl (\r eq -> PTNode "?" innerDecl rule [expandMemo eq, r])
                          (expandMemo p0) (init eqs)
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

-- Gather leaves with two-level deduplication to prevent exponential traversal
-- of DAG-shared nodes in the memoised proof tree:
--
--  seenElec  – names of positive-unit (electron) leaves already recorded;
--              each such leaf is recorded at most once (first/shallowest DFS
--              position).
--
--  seenInner – Map from inner-node name → non-unit leaves collected during
--              that node's first traversal, stored as (relative_pos, name, decl).
--              On a second encounter of the same PTNode at a new absolute
--              position, those non-unit leaves are re-emitted at new absolute
--              positions (new_pos ++ relative_pos) rather than re-traversing
--              the whole subtree.  Positive-unit leaves are NOT re-emitted
--              (they are already in seenElec and deduplicated globally).
--
-- This gives O(N) traversal while allowing non-unit leaves (rule clauses) to
-- appear at every logically distinct position: each occurrence is a separate
-- rule application that may use different available electrons.
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


classifyRole :: Map.Map String T.Unit -> String -> T.Declaration -> LeafRole
classifyRole unitMap name decl
  -- positive-unit file clauses are axioms even if labeled negated_conjecture
  -- (Vampire's "prove the negation" mode does this for all input clauses)
  | isPositiveUnitFormula decl && isFileSrc unitMap name     = OrigAxiom
  | isPositiveUnitFormula decl && isFileSrc unitMap resolvedNm = OrigAxiom
  | isNegConj decl                                           = NegConjecture
  | maybe False isNegConj (lookupDecl unitMap resolvedNm)    = NegConjecture
  -- A clause whose source traces back to a file-sourced *conjecture* is part
  -- of the negation chain (e.g. FOF clausification: plain → clausify → negate_conjecture → conjecture)
  | maybe False isConjDecl (lookupDecl unitMap resolvedNm)   = NegConjecture
  | isFileSrc unitMap name                                    = OrigAxiom
  | isFileSrc unitMap resolvedNm                              = OrigAxiom
  | otherwise                                                 = Derived
  where
    resolvedNm = resolveSourceName unitMap name
    isConjDecl (T.Formula (T.Standard T.Conjecture) _) = True
    isConjDecl _                                        = False

isNegConj :: T.Declaration -> Bool
isNegConj (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegConj _                                              = False

isFileSrc :: Map.Map String T.Unit -> String -> Bool
isFileSrc unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ _ (Just (T.File _ _, _))) -> True
  _                                         -> False

lookupDecl :: Map.Map String T.Unit -> String -> Maybe T.Declaration
lookupDecl unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ d _) -> Just d
  _                   -> Nothing

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
    extractFOF g =
      let posLits = posLitsOfDisjFOF g
          negLits = negLitsOfDisjFOF g
      in case posLits of
        [lit] -> Just [lit]   -- Horn clause A ∨ ¬B₁ ∨ … with single positive head
        []    -> if null negLits then Nothing
                 else Just negLits  -- all-negative clause: each negated atom is a goal
        _     -> Nothing

    extractConj (T.Atomic lit)                   = Just [lit]
    extractConj (T.Connected l T.Conjunction r)  = do
      ls <- extractConj l
      rs <- extractConj r
      return (ls ++ rs)
    extractConj _                                = Nothing
extractGoalLits _ = Nothing

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

-- atoms under negation in a disjunction (for all-negative clauses like ~P | ~Q)
negLitsOfDisjFOF :: T.UnsortedFirstOrder -> [T.Literal]
negLitsOfDisjFOF (T.Negated (T.Atomic lit))       = [lit]
negLitsOfDisjFOF (T.Atomic _)                     = []
negLitsOfDisjFOF (T.Connected l T.Disjunction r)  =
  negLitsOfDisjFOF l ++ negLitsOfDisjFOF r
negLitsOfDisjFOF _                                = []

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
firstParentIsLeft _ result d1 d2 = case (headLitOf d1, headLitOf d2) of
  (Just h1, _)       -> not (headInDecl h1 result)
  (Nothing, Just h2) -> headInDecl h2 result
  (Nothing, Nothing) -> True  -- both non-unit: keep original order
