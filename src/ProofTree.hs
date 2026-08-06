-- Extract all information needed by the algorithm from a flat TSTP unit list.
-- Nodes are assigned bit-string positions: root ⊥ is ε, left child gets suffix
-- "0", right child gets suffix "1".  Leaves at smaller positions are available
-- as electrons for nuclei at larger positions.
module ProofTree
  ( LeafRole(..)
  , LeafEntry(..)
  , ProofInfo(..)
  , buildProofInfo
  , headLitOf
  , unitNameStr
  , demodRuleNames
  ) where

import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Data.List (sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Ord (comparing)
import Types (Dir(..))

data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)

data LeafRole
  = OrigAxiom     -- file-sourced clause (not the negated conjecture)
  | NegConjecture -- the negated conjecture / goal
  | Derived       -- derived via inference (includes Twee rewriting steps)
  deriving (Show, Eq)

data LeafEntry = LeafEntry
  { lePos     :: String          -- bit-string position in the expanded tree
  , leName    :: String          -- resolved source name
  , leDecl    :: T.Declaration   -- raw TPTP declaration (for clause conversion)
  , leSrcDecl :: T.Declaration   -- source (original axiom) declaration; equals leDecl for Derived/NegConj
  , leRole    :: LeafRole
  , leSimpl   :: [(String, Dir)] -- Simpl[pos]: demod/rewriting chain, outermost-first
  } deriving (Show)

-- Everything the algorithm needs, extracted once from the proof tree.
data ProofInfo = ProofInfo
  { piElectrons :: [LeafEntry]  -- positive unit nodes (leaf + inner), DFS position order
  , piNonUnits  :: [LeafEntry]  -- non-positive-unit nodes (incl. NegConjecture), position order
  , piGoalLits  :: [T.Literal]  -- goal literals from the negated conjecture
  } deriving (Show)

buildProofInfo :: [T.Unit] -> Maybe ProofInfo
buildProofInfo allUnits = do
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
      nonUnits  = byPos $
                    [e | e <- lEs, not (isPositiveUnitFormula (leDecl e))] ++
                    [e | e <- iEs, not (isPositiveUnitFormula (leDecl e))]

  -- prefer the original Conjecture unit: provers may split/simplify before refutation
  goalLits <- case extractConjectureGoals allUnits of
    Just lits -> Just lits
    Nothing   -> do
      goalEntry <- listToMaybe [e | e <- nonUnits, leRole e == NegConjecture]
      let goalDecl = fromMaybe (leDecl goalEntry) (lookupDecl unitMap (leName goalEntry))
      extractGoalLits goalDecl
  return ProofInfo
    { piElectrons = electrons
    , piNonUnits  = nonUnits
    , piGoalLits  = goalLits
    }

buildProofTree :: [T.Unit] -> Maybe ProofTree
buildProofTree allUnits =
  case findRoot allUnits of
    Nothing   -> Nothing
    Just root -> Just (expand root)
  where
    unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]

    expand name = case Map.lookup name unitMap of
      Nothing             -> error ("buildProofTree: unit not found: " ++ name)
      Just u@(T.Unit _ decl _) ->
        case coreParentNames u of
          Nothing      -> PTLeaf name decl
          Just parents ->
            let rule = fromMaybe Text.empty (inferenceRuleName u)
            in PTNode name decl rule (orderedChildren decl rule parents)
      Just _ -> error "buildProofTree: unexpected non-formula unit"

    orderedChildren decl rule parents = case parents of
      [p1n, p2n] ->
        let d1 = declOf p1n; d2 = declOf p2n
            (ln, rn) = if firstParentIsLeft rule decl d1 d2
                       then (p1n, p2n) else (p2n, p1n)
        in [expand ln, expand rn]
      (p0:p1:p2:rest) ->
        let eqs  = p1:p2:rest
            inner = foldl (\r eq -> PTNode "?" decl rule [expand eq, r])
                          (expand p0) (init eqs)
            lastIsProvider = isPositiveUnitFormula (declOf (last eqs))
        in if lastIsProvider
           then [expand (last eqs), inner]
           else [inner, expand (last eqs)]
      _ -> map expand parents

    declOf n = case Map.lookup n unitMap of
      Just (T.Unit _ d _) -> d
      _                   -> T.Formula (T.Standard T.Plain)
                               (T.CNF (T.Clause (pure (T.Positive,
                                 T.Predicate (T.Defined (T.Atom (Text.pack "unknown"))) []))))

-- DAG-shared nodes appear at each position they're referenced from
gatherLeaves :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherLeaves pos (PTLeaf n d)         = [(pos, n, d)]
gatherLeaves pos (PTNode _ _ _ [k])   = gatherLeaves (pos ++ "1") k
gatherLeaves pos (PTNode _ _ _ [l,r]) = gatherLeaves (pos ++ "0") l
                                     ++ gatherLeaves (pos ++ "1") r
gatherLeaves pos (PTNode _ _ _ kids)  =
  concat [gatherLeaves (pos ++ [c]) kid | (c, kid) <- zip ['0'..] kids]

gatherInner :: String -> ProofTree -> [(String, String, T.Declaration)]
gatherInner _   (PTLeaf _ _)              = []
gatherInner pos (PTNode n d rule [k])     =
  gatherInner (pos ++ "1") k ++ keepNode pos n d rule
gatherInner pos (PTNode n d rule [l,r])   =
  gatherInner (pos ++ "0") l ++ gatherInner (pos ++ "1") r ++ keepNode pos n d rule
gatherInner pos (PTNode n d rule kids)    =
  concat [gatherInner (pos ++ [c]) kid | (c, kid) <- zip ['0'..] kids]
  ++ keepNode pos n d rule

keepNode :: String -> String -> T.Declaration -> Text.Text -> [(String, String, T.Declaration)]
keepNode pos n d rule
  | rule == Text.pack "proved_conjecture" = []
  | otherwise                             = [(pos, n, d)]

classifyRole :: Map.Map String T.Unit -> String -> T.Declaration -> LeafRole
classifyRole unitMap name decl
  -- positive-unit file clauses are axioms even if labeled negated_conjecture
  -- (Vampire's "prove the negation" mode does this for all input clauses)
  | isPositiveUnitFormula decl && isFileSrc unitMap name     = OrigAxiom
  | isPositiveUnitFormula decl && isFileSrc unitMap resolvedNm = OrigAxiom
  | isNegConj decl                                           = NegConjecture
  | maybe False isNegConj (lookupDecl unitMap resolvedNm)    = NegConjecture
  | isFileSrc unitMap name                                    = OrigAxiom
  | isFileSrc unitMap resolvedNm                              = OrigAxiom
  | otherwise                                                 = Derived
  where
    resolvedNm = resolveSourceName unitMap name

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
resolveSourceName :: Map.Map String T.Unit -> String -> String
resolveSourceName unitMap = go
  where
    go name = case Map.lookup name unitMap of
      Just (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ parents, _)))
        | rule /= Text.pack "negated_conjecture" ->
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
    extractFOF _                                       = Nothing

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
demodChainsForLeaves resolveName = go ""
  where
    go pos (PTLeaf _ _) = Map.singleton pos []
    go pos (PTNode _ _ rule [l, r])
      | isDemodRule rule && isDemodApplicationTo rule r =
          let eqName = resolveName (treeName l)
              dir    = if rule `elem` map Text.pack
                            ["forward_demodulation", "rw", "definition_unfolding"]
                       then LR else RL
              lMap   = go (pos ++ "0") l
              rMap   = go (pos ++ "1") r
          in Map.union lMap (Map.map ((eqName, dir) :) rMap)
      | otherwise =
          Map.union (go (pos ++ "0") l) (go (pos ++ "1") r)
    go pos (PTNode _ _ _ [k])  = go (pos ++ "1") k
    go pos (PTNode _ _ _ kids) =
      Map.unions [go (pos ++ [c]) kid | (c, kid) <- zip ['0'..] kids]

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
  , "rw", "definition_unfolding", "rewriting" ]

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
  , "spm", "sr", "csr", "er", "ef", "rw", "cn", "pm"
  , "proved_conjecture" ]

coreParentNames :: T.Unit -> Maybe [String]
coreParentNames (T.Unit _ decl (Just (T.Inference (T.Atom rule) _ parents, _)))
  | Set.member rule coreInferenceNames = Just (concatMap extractName parents)
  | isPredicateRewriting rule decl     = Just (concatMap extractName parents)
  where
    extractName (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    extractName (T.Parent (T.Inference _ _ ps) _) = concatMap extractName ps
    extractName (T.Parent src _) =
      error ("buildProofTree: unexpected parent source: " ++ show src)
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
firstParentIsLeft _ result d1 d2 = case (headLitOf d1, headLitOf d2) of
  (Just h1, _)       -> not (headInDecl h1 result)
  (Nothing, Just h2) -> headInDecl h2 result
  (Nothing, Nothing) ->
    error "firstParentIsLeft: both parents have no positive head"
