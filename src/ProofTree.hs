module ProofTree
  ( ProofTree(..)
  , ptName
  , ptDecl
  , buildProofTree
  , leafPositions
  -- re-exported helpers used by Converter
  , isFalsum
  , isPositiveUnitFormula
  ) where

import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import Data.List.NonEmpty (toList)

-- The refutation proof tree with ⊥ at the root.
--
-- PTLeaf: a node whose inference rule is not a core proof step — either an
--   original input clause or a preprocessing result (CNF conversion, etc.).
--   These are the leaves in Waldmann's sense: the axiom instances at the tips.
--
-- PTNode: a core proof step (resolution, superposition, equality_resolution, …).
--   Binary nodes have children ordered [leftChild, rightChild]: the positive
--   provider goes LEFT (position p0) and the negative consumer goes RIGHT (p1),
--   matching Waldmann's position convention. Unary nodes have their single
--   premise as the right child (position p1).
data ProofTree
  = PTLeaf String T.Declaration
  | PTNode String T.Declaration Text.Text [ProofTree]
  deriving (Show)

ptName :: ProofTree -> String
ptName (PTLeaf n _)     = n
ptName (PTNode n _ _ _) = n

ptDecl :: ProofTree -> T.Declaration
ptDecl (PTLeaf _ d)     = d
ptDecl (PTNode _ d _ _) = d

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
            let rule = maybe Text.empty id (inferenceRuleName u)
            in PTNode name decl rule (orderedChildren decl rule parents)
      Just _ ->
        error "buildProofTree: unexpected non-formula unit"

    orderedChildren decl rule parents = case parents of
      [p1n, p2n] ->
        let d1          = declOf p1n decl
            d2          = declOf p2n decl
            (leftN, rightN) =
              if parent1IsLeft rule decl d1 d2 then (p1n, p2n) else (p2n, p1n)
        in [expand leftN, expand rightN]
      _ -> map expand parents

    declOf n fallback = case Map.lookup n unitMap of
      Just (T.Unit _ d _) -> d
      _                   -> fallback

-- Helpers --------------------------------------------------------------------

unitNameStr :: T.UnitName -> String
unitNameStr (Left (T.Atom t)) = Text.unpack t
unitNameStr (Right n)         = show n

isCoreInference :: Text.Text -> Bool
isCoreInference name = name `elem` map Text.pack
  [ "resolution", "superposition", "paramodulation"
  , "equality_resolution", "equality_factoring"
  , "forward_subsumption_resolution", "backward_subsumption_resolution"
  , "factoring", "condensation"
  , "definition_unfolding", "trivial_inequality_removal" ]

coreParentNames :: T.Unit -> Maybe [String]
coreParentNames (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ parents, _)))
  | isCoreInference rule = Just (concatMap extractName parents)
  where
    extractName (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    extractName (T.Parent (T.Inference _ _ ps) _) = concatMap extractName ps
    extractName _                                 = []
coreParentNames _ = Nothing

inferenceRuleName :: T.Unit -> Maybe Text.Text
inferenceRuleName (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ _, _))) = Just rule
inferenceRuleName _ = Nothing

isFalsum :: T.Clause -> Bool
isFalsum (T.Clause lits) = case toList lits of
  [(_, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])] -> True
  _ -> False

declIsBottom :: T.Declaration -> Bool
declIsBottom (T.Formula _ (T.CNF cl)) = isFalsum cl
declIsBottom (T.Formula _ (T.FOF (T.Atomic (T.Predicate (T.Reserved (T.Standard T.Falsum)) [])))) = True
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
isPosAtomFOF (T.Atomic (T.Equality _ T.Positive _)) = True
isPosAtomFOF (T.Atomic (T.Predicate _ _))           = True
isPosAtomFOF _                                      = False

isPosAtomCNF :: T.Clause -> Bool
isPosAtomCNF (T.Clause lits) = case toList lits of
  [(T.Positive, T.Equality _ T.Positive _)] -> True
  [(T.Positive, T.Predicate _ _)]           -> True
  _                                         -> False

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
headLitOfFOF _                                            = Nothing

-- True if a literal with the same predicate/functor head appears in the declaration.
headInDecl :: T.Literal -> T.Declaration -> Bool
headInDecl needle (T.Formula _ (T.CNF (T.Clause lits))) =
  any (litSameHead needle . snd) (toList lits)
headInDecl needle (T.Formula _ (T.FOF f)) = headInFOF needle f
headInDecl _ _ = False

headInFOF :: T.Literal -> T.UnsortedFirstOrder -> Bool
headInFOF needle (T.Quantified T.Forall _ body) = headInFOF needle body
headInFOF needle (T.Atomic lit)                 = litSameHead needle lit
headInFOF needle (T.Connected l _ r)            = headInFOF needle l || headInFOF needle r
headInFOF needle (T.Negated f)                  = headInFOF needle f
headInFOF _ _                                   = False

litSameHead :: T.Literal -> T.Literal -> Bool
litSameHead (T.Predicate n1 _) (T.Predicate n2 _) = n1 == n2
litSameHead (T.Equality _ _ _) (T.Equality _ _ _) = True
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
      [go (pos ++ [c]) kid | (c, kid) <- zip "01" kids]

-- True when Vampire's parent1 should be the LEFT (positive provider) child.
-- Superposition: Vampire lists [into_clause, equation]; the equation is the provider.
-- Resolution with one positive unit: the positive unit is the provider.
-- Resolution with two non-units: the parent whose head is absent from the result
--   provided the positive literal that got resolved away.
parent1IsLeft :: Text.Text -> T.Declaration -> T.Declaration -> T.Declaration -> Bool
parent1IsLeft rule _ d1 _
  | rule `elem` map Text.pack ["superposition", "paramodulation"] =
      isPositiveUnitFormula d1   -- equation is positive unit; into-clause is not
parent1IsLeft _ _ d1 d2
  | isPositiveUnitFormula d1 && not (isPositiveUnitFormula d2) = True
  | isPositiveUnitFormula d2 && not (isPositiveUnitFormula d1) = False
parent1IsLeft _ result d1 d2 = case (headLitOf d1, headLitOf d2) of
  (Just h1, _)       -> not (headInDecl h1 result)  -- d1's head absent → d1 is the provider
  (Nothing, Just h2) -> headInDecl h2 result         -- d2's head survives → d2 is the consumer → d1 is left
  (Nothing, Nothing) -> True
