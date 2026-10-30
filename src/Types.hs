-- The data types all modules share, from terms, literals and Horn clauses to
-- proof blocks, the translated proof and the state of the translation.
module Types where

import Control.DeepSeq (NFData)
import GHC.Generics (Generic)
import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.TPTP as T

-- A first-order term, a variable, a constant or a function application. A
-- fresh constant of Theorem 1 stands for the variable it is named after, and
-- no match can instantiate it.
data Term
  = Var   String
  | Const String
  | App   String [Term]
  | Fresh String
  deriving (Eq, Ord, Show, Generic)

-- A literal, an equation or a predicate atom, either positive or negated.
data Literal
  = Eq   Term Term       -- s = t
  | NEq  Term Term       -- s ≠ t
  | Rel  String [Term]   -- P(t̄)
  | NRel String [Term]   -- ¬P(t̄)
  deriving (Eq, Ord, Show, Generic)

-- A Horn clause L1 ∧ ... ∧ Ln → L0. The head is Nothing for a goal clause.
data Clause = Clause
  { body :: [Literal]
  , hd   :: Maybe Literal
  } deriving (Eq, Ord, Show, Generic)

-- A substitution, binding variable names to terms.
type Subst = [(String, Term)]

-- Direction of an equation used as a rewrite rule.
data Dir = LR | RL deriving (Eq, Show, Generic)

-- One rewrite step, with the name of the equation, the equation and its direction.
data RwStep = RwStep
  { rwName :: String
  , rwEq   :: (Term, Term)
  , rwDir  :: Dir
  } deriving (Show, Generic)

-- A position in the proof tree, the path from the root as the labels of the
-- children taken. Positions share their parent, so a deep tree costs no more
-- than its nodes. The key numbers the positions in preorder, which orders
-- them as their paths do, and is even for a node of the tree, so that an odd
-- key fits in after a subtree (see posAfter).
data Pos = Pos
  { posKey    :: !Int
  , posDepth  :: !Int
  , posLabel  :: !Char   -- the label at the parent, '/' at the root
  , posParent :: Maybe Pos
  }

instance Eq Pos where
  a == b = posKey a == posKey b

instance Ord Pos where
  compare a b = compare (posKey a) (posKey b)

instance Show Pos where
  show = posString

-- The path of a position as its string of labels.
posString :: Pos -> String
posString p = maybe "" (\q -> posString q ++ [posLabel p]) (posParent p)

-- The position that sorts after every position of the tree, for a nucleus
-- without a head, which may use every unit.
posLast :: Pos
posLast = Pos maxBound 0 'z' Nothing

-- The tree's nodes by key, each with its children by label and the last key
-- of its subtree, so a subtree is the key range from the node to it.
data PosTree = PosTree
  { ptChildren :: IntMap.IntMap [(Char, Pos)]
  , ptEnd      :: IntMap.IntMap Int
  } deriving (Show)

-- The child of a position with a label, when the tree has it.
posChild :: PosTree -> Pos -> Char -> Maybe Pos
posChild t p c = lookup c (IntMap.findWithDefault [] (posKey p) (ptChildren t))

-- The other premise of the step a position is a premise of, the sibling at
-- the other label, when the tree has it.
posSibling :: PosTree -> Pos -> Maybe Pos
posSibling t p = do
  q <- posParent p
  posChild t q (if posLabel p == '0' then '1' else '0')

-- A position that sorts right after the subtree of p, as a child labelled
-- 2 would, for a unit stored once every nucleus under p is done.
posAfter :: PosTree -> Pos -> Pos
posAfter t p = Pos (IntMap.findWithDefault (posKey p) (posKey p) (ptEnd t) + 1) (posDepth p + 1) '2' (Just p)

-- An electron of the working set, with its name once it has one, its
-- literal, its proof if derived, and its position in the proof tree.
data UnitEntry = UnitEntry
  { ueName  :: Maybe String
  , ueUnit  :: Literal
  , ueProof :: Maybe ProofBlock
  , uePos   :: Maybe Pos
  } deriving (Show)

-- A proof as have/hence lines or as an equality chain. A chain proves an
-- equation, or an atom by rewriting it to true.
data ProofBlock
  = HaveHence (Seq.Seq ProofLine)
  | EqChain   Term [(RwStep, Term)]
  deriving (Show, Generic)

-- One line of a have/hence proof, a literal and what it follows from.
data ProofLine
  = Have  Literal String        -- have L  by name
  | And   Literal String        --  and L  by name
  | Hence Literal Justification -- hence L by ...
  deriving (Show, Generic)

-- Why a hence line holds, with the direction a rewrite uses its equation in.
data Justification
  = ByAxiom String
  | ByRw    String Dir
  | ByContradiction         -- the conclusion follows from a derived $false
  deriving (Show, Generic)

-- An input axiom under its display name, a unit fact or a nucleus clause.
data Axiom
  = AUnit    String Literal
  | ANucleus String Clause
  deriving (Show, Generic)

-- Forcing a proof fully makes an error inside it surface where it is caught,
-- not later when the proof is printed.
instance NFData Term
instance NFData Literal
instance NFData Clause
instance NFData Dir
instance NFData RwStep
instance NFData ProofBlock
instance NFData ProofLine
instance NFData Justification
instance NFData Axiom

-- The translated proof, with axioms in input order, lemmas and goal proofs.
-- A lemma is a Horn clause, a unit for most, whose proof assumes its body.
data StructuredProof = StructuredProof
  { axioms  :: [Axiom]
  , lemmas  :: [(String, Clause, ProofBlock)]
  , goals   :: [(Literal, ProofBlock)]
  , spInput :: ProofInput
  } deriving (Show)

-- The input problem behind a proof, kept for the TPTP output.
data ProofInput = ProofInput
  { inAxiomUnits :: Map.Map String T.Unit  -- axiom display name to its source unit
  , inHypotheses :: Map.Map String String  -- hypothesis display name to its clause's unit
  , inConjecture :: Maybe T.Unit
  , inAxiomLeaves :: Map.Map String String  -- axiom display name to its clause's unit
  , inGeneralized :: [(String, Term)]       -- goal variable to the Skolem term it replaced
  , inNegated     :: [String]  -- hypotheses from a negated conclusion, whose negation is the goal
  , inUnits      :: [T.Unit]  -- every unit of the proof, after preprocessing
  , inTyped      :: [T.Unit]  -- the units as read if the proof is typed, else empty
  } deriving (Show)

-- A proof input with nothing recorded.
emptyInput :: ProofInput
emptyInput = ProofInput Map.empty Map.empty Nothing Map.empty [] [] [] []

-- The state the translation threads through the algorithm.
data AlgState = AlgState
  { stDebug      :: Bool  -- whether debug traces are printed
  , stUnits      :: Seq.Seq UnitEntry
  , stLemmas     :: [(String, Clause, ProofBlock)]
  , stGoals      :: [(Literal, ProofBlock)]
  , stGoalFor    :: [Literal]  -- the conjunct each goal in stGoals was proved for
  , stCounter    :: Int
  , stAxNuclei   :: [(String, Clause)] -- axiom nuclei with a display name, with their clauses
  , stNameToPos  :: Map.Map String Pos           -- TSTP unit name to the tree position of its electron
  , stEquationSteps  :: [(String, String, String)]  -- equation steps as (conclusion, premise, premise), a clause inside a nested step named <unit>_stepK
  , stUnitLitByName :: Map.Map String Literal  -- the literal of each positive unit, by its name in stEquationSteps
  , stPremiseUses :: Map.Map String Int  -- TSTP unit name to how often it is a premise
  , stLiteralRewrites :: Map.Map Pos [(Literal, [(String, Dir, (Term, Term), Literal)])]  -- nucleus position to the rewrites the proof makes to each body atom
  , stHeadRewrites :: Map.Map Pos (Literal, [(String, Dir, (Term, Term), Literal)])  -- nucleus position to its head under θ and the rewrites made to it before the clause is a unit
  , stUnitRewrites :: [(Pos, Literal, [(String, Dir, (Term, Term), Literal)])]  -- units conditional equations rewrite and heads that wait, by the position they are stored before, not yet stored
  , stResolvedUnits :: Map.Map String (Clause, String)  -- units the proof derives by resolving a clause with one body atom against a unit, by name
  , stReadableUnits :: Set.Set String  -- units whose whole derivation can be read step by step (see readableUnits)
  , stPredicates :: Set.Set String  -- predicate symbols, so an equation between atoms is never a lemma (see isAtomEquation)
  , stUnreadSteps :: Set.Set (String, (Term, Term))  -- premise steps that failed to read, kept when a failed attempt is undone
  , stReadSteps :: Map.Map (String, (Term, Term)) (Term, [(UnitEntry, Dir, Term)])  -- premise steps already read, with their chains
  , stGoalTemplate :: [Literal]  -- the goal literals, whose shared variables every proved goal must ground consistently
  , stNegationConj :: Bool  -- the conjecture concludes a negation, proved by deriving $false
  , stClosing :: Maybe ProofBlock  -- for such a conjecture, the derivation of $false that closes the proof
  , stPosTree :: PosTree  -- the proof tree's positions, for the sibling of a nucleus
  , stUnitsAt :: IntMap.IntMap [(Int, UnitEntry)]  -- the units by the key of their position, -1 for none, each with its number in the order stored
  , stUnitsByLit :: Map.Map Clause [UnitEntry]  -- the units by the variant form of their literal, for the check against storing one twice
  , stUnitCount :: Int  -- how many units have been stored
  }

-- Where a clause of the proof tree comes from.
data LeafRole
  = OrigAxiom     -- an input clause, a conjecture hypothesis or a prover definition
  | NegConjecture -- a clause of the negated conjecture, the goal
  | Derived       -- the conclusion of an inference
  deriving (Show, Eq)

-- A clause of the proof tree, a leaf or an inner node.
data LeafEntry = LeafEntry
  { lePos     :: Pos             -- its position in the tree
  , leUnit    :: String          -- the unit's own name
  , leName    :: String          -- its source unit's name, its own when derived or a negated conjecture
  , leDecl    :: T.Declaration   -- the clause as the proof prints it
  , leSrcDecl :: T.Declaration   -- the source's statement if Horn or the negated conjecture, else leDecl
  , leRole    :: LeafRole
  , leHyp     :: Bool            -- a hypothesis of the conjecture
  } deriving (Show)

-- Everything the algorithm needs, extracted once from the proof tree.
data ProofInfo = ProofInfo
  { piElectrons :: [LeafEntry]  -- the positive unit clauses, leaves and inner nodes, by position
  , piNuclei    :: [LeafEntry]  -- every other clause, the negated conjecture included, by position
  , piGoalLits  :: [T.Literal]  -- the goal literals, from the conjecture or else from a clause stating its negation
  , piDeclAt    :: Map.Map Pos T.Declaration
      -- the clause at each ancestor of an entry and its sibling, for tracing θ
  , piUnitAt    :: Map.Map Pos String
      -- the unit at each of those positions, also at repeat uses that have no entry
  , piRuleAt    :: Map.Map Pos String
      -- the rule of the step that concludes the clause at each of them
  , piPosTree   :: PosTree       -- the children and subtrees of those positions
  } deriving (Show)
