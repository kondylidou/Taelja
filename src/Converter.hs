module Converter where

import qualified Data.TPTP as T
import Data.List (nub, foldl', sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (catMaybes)
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text

import Types
import Helpers
import ProofTree (buildProofTree, leafPositions, isFalsum)

-- Splits the TSTP unit list into four buckets: axiom entries for output,
-- unit axioms pre-loaded into the working set, non-unit clauses for proof search,
-- and goal literals from the negated conjecture.
-- Handles both E (split_conjunct / CNF) and Vampire (negated_conjecture / FOF).
classifyAxioms :: [T.Unit]
               -> ([Axiom], [UnitEntry], [(String, Clause)], [Literal])
classifyAxioms units =
  let fofAxioms = [ (unitNameToString n, f)
                  | T.Unit n (T.Formula (T.Standard T.Axiom) (T.FOF f)) _ <- units ]
      negConjCNF = [ cl
                   | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.CNF cl))
                               (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                   , rule == Text.pack "split_conjunct"
                   , not (isFalsum cl) ]
      negConjFOF = [ f
                   | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.FOF f))
                               (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                   , rule == Text.pack "negated_conjecture" ]
      goalLits   = case (negConjCNF, negConjFOF) of
                     ([cl], []) -> [negateGoal cl]
                     ([], [f])  -> negateGoalFOF f
                     _          -> error "classifyAxioms: expected exactly one negated conjecture"
      classify (i, (origName, f))
        | isPositiveUnitFOF f =
            let lit = extractUnitFOF f
                nm  = "axiom " ++ show i
            in (AUnit nm lit, Just (UnitEntry (Just nm) lit Nothing), Nothing)
        | isHornImplicationFOF f =
            let nm = "axiom " ++ show i
                cl = fofToClause f
            in (ANonUnit nm cl, Nothing, Just (nm, freshenClause cl))
        | otherwise =
            error ("input is not in the Horn fragment: " ++ origName
                   ++ "\n  formula: " ++ show f)
      classified             = zipWith (curry classify) [(1::Int)..] fofAxioms
      (axEntries, maybeUnits, maybeNonUnits) = unzip3 classified
      rawNonUnits            = catMaybes maybeNonUnits
      -- Maps each original FOF axiom name to its Taelja display name ("axiom N"),
      -- but only for non-unit axioms. The ancestry map uses the original names internally.
      displayNames           = Map.fromList
        [ (origName, "axiom " ++ show i)
        | (i, (origName, f)) <- zip [(1::Int)..] fofAxioms
        , isHornImplicationFOF f ]
      -- Sort non-unit clauses by their position in the TSTP proof tree so
      -- the translator can process them in a single ordered pass.
      nonUnitNames    = map fst rawNonUnits
      orderedNames    = proofTreeOrder units displayNames nonUnitNames
      nonUnitMap      = Map.fromList rawNonUnits
      orderedNonUnits = [ (n, c) | n <- orderedNames
                                 , Just c <- [Map.lookup n nonUnitMap] ]
  in (axEntries, catMaybes maybeUnits, orderedNonUnits, goalLits)

-- Accepts ∀X₁…∀Xₙ. L where L is atomic — a positive unit clause.
isPositiveUnitFOF :: T.UnsortedFirstOrder -> Bool
isPositiveUnitFOF (T.Atomic _)                   = True
isPositiveUnitFOF (T.Quantified T.Forall _ body) = isPositiveUnitFOF body
isPositiveUnitFOF _                              = False

-- Accepts ∀X₁…∀Xₙ. (A₁ ∧ … ∧ Aₙ) → H where each Aᵢ and H are atomic.
-- Together with isPositiveUnitFOF this covers the full Horn fragment.
isHornImplicationFOF :: T.UnsortedFirstOrder -> Bool
isHornImplicationFOF (T.Quantified T.Forall _ body) = isHornImplicationFOF body
isHornImplicationFOF (T.Connected ante T.Implication cons) =
  isHornBodyFOF ante && isAtomicFOF cons
isHornImplicationFOF _ = False

isAtomicFOF :: T.UnsortedFirstOrder -> Bool
isAtomicFOF (T.Atomic _) = True
isAtomicFOF _            = False

isHornBodyFOF :: T.UnsortedFirstOrder -> Bool
isHornBodyFOF (T.Connected l T.Conjunction r) = isHornBodyFOF l && isHornBodyFOF r
isHornBodyFOF (T.Atomic _)                    = True
isHornBodyFOF _                               = False

extractUnitFOF :: T.UnsortedFirstOrder -> Literal
extractUnitFOF (T.Atomic lit)                 = convertLit lit
extractUnitFOF (T.Quantified T.Forall _ body) = extractUnitFOF body
extractUnitFOF _                              = error "extractUnitFOF: not a positive unit"

fofToClause :: T.UnsortedFirstOrder -> Clause
fofToClause = go
  where
    go (T.Quantified T.Forall _ body)        = go body
    go (T.Connected ante T.Implication cons) =
      Clause { body = collectLits ante, hd = Just (convertLit (atomLit cons)) }
    go _                                     = error "fofToClause: unexpected formula shape"

    collectLits (T.Connected l T.Conjunction r) = collectLits l ++ collectLits r
    collectLits (T.Atomic lit)                  = [convertLit lit]
    collectLits _                               = error "fofToClause: unexpected body shape"

    atomLit (T.Atomic lit) = lit
    atomLit _              = error "fofToClause: head is not atomic"

-- The negated conjecture is the negation of the goal, so we negate it back.
negateGoal :: T.Clause -> Literal
negateGoal (T.Clause lits) = case toList lits of
  [(T.Negative, lit)]                       -> convertLit lit
  [(T.Positive, T.Equality l T.Negative r)] -> Eq (convertTerm l) (convertTerm r)
  _ -> error "negateGoal: unexpected negated conjecture shape"

-- Same as negateGoal but for FOF negated conjectures (Vampire style), which may
-- be a conjunction of goals.
negateGoalFOF :: T.UnsortedFirstOrder -> [Literal]
negateGoalFOF (T.Negated f) = collectConjuncts f
  where
    collectConjuncts (T.Connected l T.Conjunction r) =
      collectConjuncts l ++ collectConjuncts r
    collectConjuncts (T.Atomic lit) = [convertLit lit]
    collectConjuncts _ = error "negateGoalFOF: unexpected conjunct shape"
negateGoalFOF _ = error "negateGoalFOF: unexpected negated conjecture shape"

convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit _                                         = error "convertLit: unsupported literal form"

convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = case args of
  [] -> Const (Text.unpack f)
  _  -> App   (Text.unpack f) (map convertTerm args)
convertTerm _ = error "convertTerm: unsupported term form"

unitNameToString :: T.UnitName -> String
unitNameToString (Left (T.Atom t)) = Text.unpack t
unitNameToString (Right n)         = show n

-- Order non-unit axiom names by lexicographic leaf-position order.
-- Builds the refutation proof tree, assigns binary position strings to leaves
-- (left child "0", right child "1"), then sorts each non-unit axiom by the
-- minimum leaf position across all its occurrences in the tree.
proofTreeOrder :: [T.Unit] -> Map.Map String String -> [String] -> [String]
proofTreeOrder allUnits displayNames nonUnitNames =
  case buildProofTree allUnits of
    Nothing   -> nonUnitNames
    Just tree ->
      let ancestryMap = buildAncestryMap allUnits
          posMap      = leafPositions tree
          firstPos    = Map.foldlWithKey'
            (\acc leafName pos ->
              let ancestorAxioms = Map.findWithDefault Set.empty leafName ancestryMap
                  matchingNames  = [nm | a <- Set.toList ancestorAxioms, Just nm <- [Map.lookup a displayNames]]
              in foldl' (\m nm -> Map.insertWith min nm pos m) acc matchingNames)
            Map.empty posMap
          withOrder   = [(n, Map.findWithDefault "2" n firstPos) | n <- nonUnitNames]
      in map fst (sortBy (comparing snd) withOrder)

-- Maps each TSTP unit name to the set of original FOF axiom names in its ancestry.
buildAncestryMap :: [T.Unit] -> Map.Map String (Set.Set String)
buildAncestryMap = foldl' addUnit Map.empty
  where
    addUnit acc (T.Unit name formula msource) =
      let n       = unitNameToString name
          selfSet = case formula of
            T.Formula (T.Standard T.Axiom) _ -> Set.singleton n
            _                                -> Set.empty
          parentSet = case msource of
            Just (T.Inference _ _ parents, _) ->
              Set.unions (map (parentAncestry acc) parents)
            Just (T.UnitSource pname, _) ->
              Map.findWithDefault Set.empty (unitNameToString pname) acc
            _ -> Set.empty
          combined = Set.union selfSet parentSet
      in if Set.null combined then acc else Map.insert n combined acc
    addUnit acc _ = acc  -- T.Include and other non-formula units

    parentAncestry acc (T.Parent (T.UnitSource n) _) =
      Map.findWithDefault Set.empty (unitNameToString n) acc
    parentAncestry acc (T.Parent (T.Inference _ _ ps) _) =
      Set.unions (map (parentAncestry acc) ps)
    parentAncestry _ _ = Set.empty

-- Prefixes every clause variable with "c" so it can never collide with unit
-- variables, which are uppercase-initial per the TPTP standard.
-- unifyBodyLit relies on this invariant to split the combined substitution.
freshenClause :: Clause -> Clause
freshenClause (Clause bs mh) =
  let allVs = nub (concatMap litVars bs ++ maybe [] litVars mh)
      sub   = [(v, Var ("c" ++ v)) | v <- allVs]
  in Clause (map (applySubst sub) bs) (fmap (applySubst sub) mh)

