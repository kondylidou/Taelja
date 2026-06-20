module Translate (translate, phaseOne) where

import Data.List.NonEmpty (toList)
import Data.Maybe (listToMaybe)
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import ProofTree
  ( ProofTree, buildProofTree, leafList
  , isPositiveUnitFormula, headLitOf, unitNameStr
  )

-- Top-level entry: build the proof tree, run the algorithm, return the structured proof.
translate :: Bool -> T.TSTP -> StructuredProof
translate _ (T.TSTP _ units) =
  case buildProofTree units of
    Nothing   -> error "translate: no refutation found"
    Just tree ->
      case phaseOne tree units of
        Nothing                          -> error "translate: no goal found"
        Just (initUnits, nonUnits, goal) ->
          runAlgorithm initUnits nonUnits goal

-- Phase 1: classify leaf clauses into electrons (Units) and nuclei (NonUnits).
-- Leaves are visited in ≺-increasing (left-first DFS) position order.
-- The goal is a list of literals (conjunction); usually one, but can be more
-- when the conjecture is a conjunction (e.g. G1 ∧ G2).
-- Electron names are resolved to their original problem-file names (ax1, goal, …).
phaseOne :: ProofTree -> [T.Unit] -> Maybe ([UnitEntry], [(String, String, T.Declaration)], [Literal])
phaseOne tree units =
  case findGoal units of
    Nothing      -> Nothing
    Just rawGoal ->
      let goal    = map convertLit rawGoal
          unitMap = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n _ _) <- units ]
          resolve = resolveSourceName unitMap
          ls      = leafList tree
          us      = [ UnitEntry (Just (resolve name)) (convertLit lit) Nothing (Just pos)
                    | (pos, name, decl) <- ls
                    , isPositiveUnitFormula decl
                    , Just lit <- [headLitOf decl] ]
          nus     = [ (pos, name, decl)
                    | (pos, name, decl) <- ls
                    , not (isPositiveUnitFormula decl) ]
      in Just (us, nus, goal)

-- Conversion from TPTP terms/literals to our working types.
convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) [])   = Const (Text.unpack f)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = App (Text.unpack f) (map convertTerm args)
convertTerm (T.Number (T.IntegerConstant n))          = Const (show n)
convertTerm t = error ("convertTerm: unsupported term: " ++ show t)

convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit t = error ("convertLit: unsupported literal: " ++ show t)

-- Follow the annotation chain to recover the original problem-file name for a unit.
-- Vampire and E rename/split clauses during preprocessing; this traces those steps
-- back to the unit that was read directly from the input file.
resolveSourceName :: Map.Map String T.Unit -> String -> String
resolveSourceName unitMap = go
  where
    go name = case Map.lookup name unitMap of
      Just (T.Unit _ _ (Just (T.Inference _ _ parents, _))) ->
        case concatMap flatParents parents of
          (p:_) -> go p
          []    -> name
      _ -> name

    flatParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    flatParents (T.Parent (T.Inference _ _ ps) _) = concatMap flatParents ps
    flatParents _                                  = []

-- Scan the TSTP unit list for the goal literals.
-- Primary: the Conjecture unit — extract all conjuncts (usually just one literal,
-- but conjunctions like G1 ∧ G2 give [G1, G2]).
-- Fallback: a NegatedConjecture given directly in the input file (E prover style).
findGoal :: [T.Unit] -> Maybe [T.Literal]
findGoal units =
  case listToMaybe [ lits | T.Unit _ decl _ <- units
                           , isConjecture decl
                           , Just lits <- [goalLiterals decl] ] of
    Just lits -> Just lits
    Nothing   -> listToMaybe
      [ lits | T.Unit _ decl (Just (T.File _ _, _)) <- units
             , isNegatedConjecture decl
             , Just lits <- [unnegateDecl decl] ]

-- Extract conjuncts from a conjecture declaration: single atom → [lit],
-- conjunction A ∧ B → [A, B], quantified ∀X.body → recurse into body.
goalLiterals :: T.Declaration -> Maybe [T.Literal]
goalLiterals decl = case headLitOf decl of
  Just lit -> Just [lit]
  Nothing  -> case decl of
    T.Formula _ (T.FOF f) -> conjunctLits f
    _                     -> Nothing

conjunctLits :: T.UnsortedFirstOrder -> Maybe [T.Literal]
conjunctLits (T.Quantified T.Forall _ body) = conjunctLits body
conjunctLits (T.Atomic lit)                 = Just [lit]
conjunctLits (T.Connected l T.Conjunction r) =
  (++) <$> conjunctLits l <*> conjunctLits r
conjunctLits _                              = Nothing

isConjecture :: T.Declaration -> Bool
isConjecture (T.Formula (T.Standard T.Conjecture) _) = True
isConjecture _                                       = False

isNegatedConjecture :: T.Declaration -> Bool
isNegatedConjecture (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegatedConjecture _                                              = False

-- Extract goal literals from a directly-given negated conjecture.
unnegateDecl :: T.Declaration -> Maybe [T.Literal]
unnegateDecl (T.Formula _ (T.CNF (T.Clause lits))) = case toList lits of
  [(T.Negative, lit)]                       -> Just [lit]
  [(T.Positive, T.Equality l T.Negative r)] -> Just [T.Equality l T.Positive r]
  _                                         -> Nothing
unnegateDecl (T.Formula _ (T.FOF f)) = fmap (:[]) (unnegateFOF f)
unnegateDecl _                       = Nothing

unnegateFOF :: T.UnsortedFirstOrder -> Maybe T.Literal
unnegateFOF (T.Quantified T.Forall _ body) = unnegateFOF body
unnegateFOF (T.Negated (T.Atomic lit))     = Just lit
unnegateFOF _                              = Nothing

-- Phases 2 & 3: not yet implemented.
runAlgorithm :: [UnitEntry] -> [(String, String, T.Declaration)] -> [Literal] -> StructuredProof
runAlgorithm _units _nonUnits _goal = StructuredProof [] [] []
