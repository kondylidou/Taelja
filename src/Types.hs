-- The data types all modules share, from terms, literals and Horn clauses to
-- proof blocks, the translated proof and the state of the translation.
module Types where

import Control.DeepSeq (NFData)
import GHC.Generics (Generic)
import qualified Data.Map.Strict as Map
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
  } deriving (Eq, Show, Generic)

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

-- An electron of the working set, with its name once it has one, its
-- literal, its proof if derived, and its position in the proof tree.
data UnitEntry = UnitEntry
  { ueName  :: Maybe String
  , ueUnit  :: Literal
  , ueProof :: Maybe ProofBlock
  , uePos   :: Maybe String
  } deriving (Show)

-- A proof as have/hence lines or as an equality chain. A chain proves an
-- equation, or an atom by rewriting it to true.
data ProofBlock
  = HaveHence [ProofLine]
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
data StructuredProof = StructuredProof
  { axioms  :: [Axiom]
  , lemmas  :: [(String, Literal, ProofBlock)]
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
  , stUnits      :: [UnitEntry]
  , stLemmas     :: [(String, Literal, ProofBlock)]
  , stGoals      :: [(Literal, ProofBlock)]
  , stGoalFor    :: [Literal]  -- the conjunct each goal in stGoals was proved for
  , stCounter    :: Int
  , stAxNuclei   :: [(String, Clause)] -- axiom nuclei with a display name, with their clauses
  , stNameToPos  :: Map.Map String String        -- TSTP unit name to the tree position of its electron
  , stEquationSteps  :: [(String, String, String)]  -- equation steps as (conclusion, premise, premise), a clause inside a nested step named <unit>_stepK
  , stUnitLitByName :: Map.Map String Literal  -- the literal of each positive unit, by its name in stEquationSteps
  , stPremiseUses :: Map.Map String Int  -- TSTP unit name to how often it is a premise
  , stLiteralRewrites :: Map.Map String [(Literal, [(String, Dir, (Term, Term), Literal)])]  -- nucleus position to the rewrites the proof makes to each body atom
  , stHeadRewrites :: Map.Map String (Literal, [(String, Dir, (Term, Term), Literal)])  -- nucleus position to its head under θ and the rewrites made to it before the clause is a unit
  , stReadableUnits :: Set.Set String  -- units whose whole derivation can be read step by step (see readableUnits)
  , stPredicates :: Set.Set String  -- predicate symbols, so an equation between atoms is never a lemma (see isAtomEquation)
  , stUnreadSteps :: Set.Set (String, (Term, Term))  -- premise steps that failed to read, kept when a failed attempt is undone
  , stReadSteps :: Map.Map (String, (Term, Term)) (Term, [(UnitEntry, Dir, Term)])  -- premise steps already read, with their chains
  , stGoalTemplate :: [Literal]  -- the goal literals, whose shared variables every proved goal must ground consistently
  , stNegationConj :: Bool  -- the conjecture concludes a negation, proved by deriving $false
  , stClosing :: Maybe ProofBlock  -- for such a conjecture, the derivation of $false that closes the proof
  }

-- Where a clause of the proof tree comes from.
data LeafRole
  = OrigAxiom     -- an input clause, a conjecture hypothesis or a prover definition
  | NegConjecture -- a clause of the negated conjecture, the goal
  | Derived       -- the conclusion of an inference
  deriving (Show, Eq)

-- A clause of the proof tree, a leaf or an inner node.
data LeafEntry = LeafEntry
  { lePos     :: String          -- its position in the tree, a string of child indices
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
  , piDeclAt    :: Map.Map String T.Declaration
      -- the clause at each ancestor of an entry and its sibling, for tracing θ
  , piUnitAt    :: Map.Map String String
      -- the unit at each of those positions, also at repeat uses that have no entry
  , piRuleAt    :: Map.Map String String
      -- the rule of the step that concludes the clause at each of them
  } deriving (Show)
