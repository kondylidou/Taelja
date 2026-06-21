-- Phase 0: build the refutation proof tree from a flat TSTP unit list.
-- Nodes are assigned bit-string positions: root ⊥ is ε, and each inference
-- step extends the parent's position:
--   unary premise              → parent ++ "1"
--   resolution positive provider (C1∨A1) → parent ++ "0"
--   resolution negative consumer (C2∨¬A2) → parent ++ "1"
--   superposition equation (C1∨s≈s')  → parent ++ "0"
--   superposition into-clause (C2∨L[t]) → parent ++ "1"
-- leafPositions returns leaf positions in lexicographic (left-first DFS) order.
module ProofTree
  ( ProofTree(..)
  , buildProofTree
  , leafPositions
  , leafList
  , isFalsum
  , isPositiveUnitFormula
  , headLitOf
  , unitNameStr
  ) where

import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe)

-- The refutation proof tree with ⊥ at the root.
--
-- PTLeaf: a node whose inference rule is not a core proof step — either an
--   original input clause or a preprocessing result (CNF conversion, etc.).
--   These are the axiom instances at the tips of the tree.
--
-- PTNode: a core proof step (resolution, superposition, equality_resolution, …).
--   Binary nodes have children ordered [leftChild, rightChild]: the positive
--   provider goes LEFT (position p0) and the negative consumer goes RIGHT (p1).
--   Unary nodes have their single premise as the right child (position p1).
data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)

-- Build the refutation proof tree from a flat TSTP unit list.
-- Returns Nothing when no ⊥ unit is present.
-- DAG nodes that appear as premises of multiple steps are fully expanded
-- (the tree may therefore contain repeated subtrees).
buildProofTree :: [T.Unit] -> Maybe ProofTree
buildProofTree allUnits =
  case findRoot allUnits of
    Nothing   -> Nothing
    Just root -> Just (expand root)
  where
    unitMap = Map.fromList
      [ (unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits ]

    expand name = case Map.lookup name unitMap of
      Nothing ->
        error ("buildProofTree: unit not found: " ++ name)
      Just u@(T.Unit _ decl _) ->
        case coreParentNames u of
          Nothing      -> PTLeaf name decl
          Just parents ->
            let rule = fromMaybe Text.empty (inferenceRuleName u)
            in PTNode name decl rule (orderedChildren decl rule parents)
      Just _ ->
        error "buildProofTree: unexpected non-formula unit"

    orderedChildren decl rule parents = case parents of
      [p1n, p2n] ->
        let d1          = declOf p1n decl
            d2          = declOf p2n decl
            (leftN, rightN) =
              if firstParentIsLeft rule decl d1 d2 then (p1n, p2n) else (p2n, p1n)
        in [expand leftN, expand rightN]
      (p0:p1:p2:rest) ->
        -- 3+ parents: fold into nested binary steps to keep the tree binary.
        -- If the last parent is a positive unit it is a provider → goes LEFT.
        -- Otherwise it is the negative consumer → goes RIGHT, so that unit
        -- electrons at smaller positions satisfy q ≺ p.
        let eqs      = p1:p2:rest
            innerKids = foldl (\r eq -> PTNode "?" decl rule [expand eq, r])
                               (expand p0)
                               (init eqs)
            lastIsProvider = isPositiveUnitFormula (declOf (last eqs) decl)
        in if lastIsProvider
           then [expand (last eqs), innerKids]   -- unit provider goes LEFT
           else [innerKids, expand (last eqs)]   -- consumer goes RIGHT
      _ -> map expand parents

    declOf n fallback = case Map.lookup n unitMap of
      Just (T.Unit _ d _) -> d
      _                   -> fallback

-- Helpers --------------------------------------------------------------------

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
  -- E prover
  , "spm", "sr", "csr", "er", "ef", "rw", "cn", "pm" ]

isCoreInference :: Text.Text -> Bool
isCoreInference name = Set.member name coreInferenceNames

coreParentNames :: T.Unit -> Maybe [String]
coreParentNames (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ parents, _)))
  | isCoreInference rule = Just (concatMap extractName parents)
  where
    extractName (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    extractName (T.Parent (T.Inference _ _ ps) _) = concatMap extractName ps
    extractName (T.Parent src _)                  =
      error ("buildProofTree: unexpected parent source in core inference: " ++ show src)
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
declIsBottom (T.Formula _ (T.FOF (T.Atomic (T.Predicate (T.Reserved (T.Standard T.Falsum)) [])))) = True
-- ¬$true is logically equivalent to $false; some provers use this form.
declIsBottom (T.Formula _ (T.FOF (T.Negated (T.Atomic (T.Predicate (T.Reserved (T.Standard T.Tautology)) []))))) = True
declIsBottom _ = False

findRoot :: [T.Unit] -> Maybe String
findRoot units =
  -- TSTP output is topologically sorted (parents before children), so the
  -- actual refutation root is always the LAST bottom unit in the file.
  -- When E-prover splitting produces intermediate empty clauses, they appear
  -- before the final root, so `last` correctly selects the true root.
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

-- Extract the unique positive literal from a Horn clause (CNF or FOF).
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

-- Collect positive literal atoms from a disjunctive FOF formula (¬A₁ ∨ … ∨ L).
posLitsOfDisjFOF :: T.UnsortedFirstOrder -> [T.Literal]
posLitsOfDisjFOF (T.Atomic lit)                   = [lit]
posLitsOfDisjFOF (T.Negated _)                    = []
posLitsOfDisjFOF (T.Connected l T.Disjunction r)  = posLitsOfDisjFOF l ++ posLitsOfDisjFOF r
posLitsOfDisjFOF _                                = []

-- True if a POSITIVE literal with the same predicate/functor head appears in the declaration.
-- Only positive literals matter: resolution removes the provider's positive head literal,
-- so we check whether it still appears positively in the resolvent.
headInDecl :: T.Literal -> T.Declaration -> Bool
headInDecl needle (T.Formula _ (T.CNF (T.Clause lits))) =
  any (litSameHead needle) [l | (T.Positive, l) <- toList lits]
headInDecl needle (T.Formula _ (T.FOF f)) = headInFOF needle f
headInDecl _ _ = False

headInFOF :: T.Literal -> T.UnsortedFirstOrder -> Bool
headInFOF needle (T.Quantified T.Forall _ body) = headInFOF needle body
headInFOF needle (T.Atomic lit)                 = litSameHead needle lit
headInFOF needle (T.Connected _ T.Implication r) = headInFOF needle r
headInFOF needle (T.Connected l _ r)            = headInFOF needle l || headInFOF needle r
headInFOF _ _                                   = False

litSameHead :: T.Literal -> T.Literal -> Bool
litSameHead (T.Predicate n1 _) (T.Predicate n2 _) = n1 == n2
litSameHead (T.Equality {}) (T.Equality {}) = True
litSameHead _ _                                    = False

-- DFS assignment of binary position strings to leaf nodes.
-- Left child gets suffix "0", right child gets suffix "1".
-- When a TSTP unit appears in multiple branches (DAG sharing), it gets
-- multiple positions; the minimum (leftmost in DFS order) is kept via
-- Map.unions with left-bias on a left-to-right traversal.
leafPositions :: ProofTree -> Map.Map String String
leafPositions = go ""
  where
    go pos (PTLeaf n _)          = Map.singleton n pos
    go pos (PTNode _ _ _ [k])    = go (pos ++ "1") k
    go pos (PTNode _ _ _ [l, r]) = Map.union (go (pos ++ "0") l) (go (pos ++ "1") r)
    go pos (PTNode _ _ _ kids)   = Map.unions
      [go (pos ++ [c]) kid | (c, kid) <- zip ['0'..] kids]

-- All leaf nodes in left-first DFS order: (position, name, declaration).
-- Unlike leafPositions, duplicates are preserved — a clause reused at two
-- positions in the expanded tree appears twice.
leafList :: ProofTree -> [(String, String, T.Declaration)]
leafList = go ""
  where
    go pos (PTLeaf n d)          = [(pos, n, d)]
    go pos (PTNode _ _ _ [k])    = go (pos ++ "1") k
    go pos (PTNode _ _ _ [l, r]) = go (pos ++ "0") l ++ go (pos ++ "1") r
    go pos (PTNode _ _ _ kids)   = concat
      [go (pos ++ [c]) kid | (c, kid) <- zip ['0'..] kids]

-- True when Vampire's parent1 should be the LEFT (positive provider) child.
-- Superposition: Vampire lists [into_clause, equation]; the equation is the provider.
--   d1 = into_clause (consumer, goes RIGHT), d2 = equation (provider, goes LEFT).
--   We always return False regardless of whether into_clause is a unit formula.
-- Resolution with one positive unit: the positive unit is the provider.
-- Resolution with two non-units: the parent whose head is absent from the result
--   provided the positive literal that got resolved away.
superpositionRules :: Set.Set Text.Text
superpositionRules = Set.fromList (map Text.pack
  [ "superposition", "paramodulation", "spm"
  , "forward_demodulation", "backward_demodulation" ])

firstParentIsLeft :: Text.Text -> T.Declaration -> T.Declaration -> T.Declaration -> Bool
firstParentIsLeft rule _ _ _
  | Set.member rule superpositionRules =
      False  -- equation (d2) is always the LEFT provider; into-clause (d1) goes RIGHT
firstParentIsLeft _ _ d1 d2
  | isPositiveUnitFormula d1 && not (isPositiveUnitFormula d2) = True
  | isPositiveUnitFormula d2 && not (isPositiveUnitFormula d1) = False
  | isPositiveUnitFormula d1 && isPositiveUnitFormula d2 =
      -- Both are positive units.  Treat like superposition: if one is a pure
      -- equation and the other a predicate, the equation goes LEFT.  If both
      -- are equations (or both predicates), keep TSTP order (first goes LEFT).
      let isEqLitOf d = case headLitOf d of { Just (T.Equality {}) -> True; _ -> False }
      in case (isEqLitOf d1, isEqLitOf d2) of
           (True,  False) -> True   -- d1 is equation, d2 is predicate → d1 LEFT
           (False, True ) -> False  -- d2 is equation, d1 is predicate → d2 LEFT
           _              -> True   -- both equations or both predicates → TSTP order
firstParentIsLeft _ result d1 d2 = case (headLitOf d1, headLitOf d2) of
  (Just h1, _)       -> not (headInDecl h1 result)  -- d1's head absent → d1 is the provider
  (Nothing, Just h2) -> headInDecl h2 result         -- d2's head survives → d2 is the consumer → d1 is left
  (Nothing, Nothing) -> error "firstParentIsLeft: both parents have no positive head literal (non-Horn clause in proof?)"
