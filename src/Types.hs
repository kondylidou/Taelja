module Types where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T

data Term
  = Var   String
  | Const String
  | App   String [Term]
  deriving (Eq, Ord, Show)

data Literal
  = Eq   Term Term       -- s = t
  | NEq  Term Term       -- s ≠ t
  | Rel  String [Term]   -- P(t̄)
  | NRel String [Term]   -- ¬P(t̄)
  deriving (Eq, Ord, Show)

-- A Horn clause ¬L1 ∨ ... ∨ ¬Ln ∨ L0.  The body holds L1 to Ln with their signs
-- stripped, and the head is Just L0, or Nothing for a goal clause.
data Clause = Clause
  { body :: [Literal]
  , hd   :: Maybe Literal
  } deriving (Eq, Show)

type Subst = [(String, Term)]

-- Direction of an equation used as a rewrite rule.
data Dir = LR | RL deriving (Eq, Show)

-- One rewrite step, with the equation used, its direction and the result.
data RwStep = RwStep
  { rwName :: String
  , rwEq   :: (Term, Term)
  , rwDir  :: Dir
  } deriving (Show)

-- An entry in the working unit set, with its name if assigned, literal, stored proof and position.
data UnitEntry = UnitEntry
  { ueName  :: Maybe String
  , ueUnit  :: Literal
  , ueProof :: Maybe ProofBlock
  , uePos   :: Maybe String
  } deriving (Show)

-- A Horn axiom as encoded for Twee with ifeq and pair.  haCnfId is its name in
-- the CNF file sent to Twee, haDispName its name in the emitted proof, haHead
-- its relational head and haBodies its body, empty for a unit.
data HornAxiomEntry = HornAxiomEntry
  { haCnfId    :: String
  , haDispName :: Maybe String
  , haHead     :: Literal
  , haBodies   :: [Literal]
  } deriving (Show)

-- EqChain is only for pure equational goals. Everything else uses HaveHence.
data ProofBlock
  = HaveHence [ProofLine]
  | EqChain   Term [(RwStep, Term)]
  deriving (Show)

data ProofLine
  = Have  Literal String        -- have L  by name
  | And   Literal String        --  and L  by name
  | Hence Literal Justification -- hence L by ...
  deriving (Show)

data Justification
  = ByAxiom String
  | ByRw    String (Maybe Dir)
  | ByContradiction         -- the conclusion follows from a derived $false
  deriving (Show)

data Axiom
  = AUnit    String Literal
  | ANucleus String Clause
  deriving (Show)

-- The translated proof, with axioms in input order, lemmas and goal proofs.
data StructuredProof = StructuredProof
  { axioms  :: [Axiom]
  , lemmas  :: [(String, Literal, ProofBlock)]
  , goals   :: [(Literal, ProofBlock)]
  , spInput :: ProofInput
  } deriving (Show)

-- The input problem behind a proof, kept for the TPTP output.  Axiom display
-- names map to the input units they came from, the hypotheses an implication
-- conjecture assumed map to the clause that states them, and the conjecture
-- is its input unit.
data ProofInput = ProofInput
  { inAxiomUnits :: Map.Map String T.Unit
  , inHypotheses :: Map.Map String String
  , inConjecture :: Maybe T.Unit
  , inAxiomLeaves :: Map.Map String String  -- axiom display name to its clause's unit
  , inGeneralized :: [(String, Term)]       -- goal variable to the Skolem term it replaced
  , inNegated     :: [String]  -- hypotheses from a negated conclusion, so the goal is their negation
  , inUnits      :: [T.Unit]  -- every unit of the input proof
  , inTyped      :: [T.Unit]  -- the units as read when the proof is typed, else empty
  } deriving (Show)

emptyInput :: ProofInput
emptyInput = ProofInput Map.empty Map.empty Nothing Map.empty [] [] [] []

data AlgState = AlgState
  { stDebug      :: Bool  -- gate for per-goal warnings (a stage's result may be superseded)
  , stProverAllowed :: Bool  -- whether find_elec may call a prover, false during the cheap phase
  , stUnits      :: [UnitEntry]
  , stHornAxioms :: [HornAxiomEntry]  -- original Horn axioms for Twee fallback calls
  , stLemmas     :: [(String, Literal, ProofBlock)]
  , stGoals      :: [(Literal, ProofBlock)]
  , stCounter    :: Int
  , stAxNuclei   :: [(String, Clause)] -- original axiom nuclei (name, clause) for goal justification search
  , stReprove    :: String -> IO (Maybe (Literal, ProofBlock, [(String, Literal, ProofBlock)], [Axiom]))
    -- Axioms a re-proof had to state that the input tree never used, given
    -- outer numbers as they arrive and appended to the emitted axiom list.
  , stExtraAxioms :: [Axiom]
    -- The emitted axiom list as fixed before the algorithm ran.  Numbering the
    -- extras consults it so the two never collide.
  , stBaseAxioms  :: [Axiom]
  , stNameToPos  :: Map.Map String String        -- TSTP unit name -> tree position of its electron
  , stEqByName   :: Map.Map String (Term, Term)  -- TSTP unit name -> its unit equation
  , stTweeSteps  :: [(String, String, String)]  -- a Twee rewriting step: its conclusion and its two premises, as TSTP names
  , stUnreadSteps :: Set.Set String  -- Twee steps that could not be read, kept when a failed attempt is undone
  , stReadSteps :: Map.Map String (Term, [(UnitEntry, Dir, Term)])  -- Twee steps read, each its chain from its own left side
  , stGoalTemplate :: [Literal]  -- the conjecture's own goal literals (shared free variables across conjuncts), consulted by emitGoalProof
  , stCandLemmas :: Map.Map String [(String, Literal, ProofBlock)]  -- a candidate lemma's display name -> its entries, sub-lemmas first
  , stNegationConj :: Bool  -- the conjecture concludes a negation, proved by deriving $false
  , stClosing :: Maybe ProofBlock  -- the derivation of $false from the goal nucleus's premises, for such a conjecture
      -- stReprove re-proves the derived unit at a tree position from its
      -- ancestry.  Only top-level runs use it, and it returns Nothing elsewhere.
  }

data LeafRole
  = OrigAxiom     -- file-sourced clause (not the negated conjecture)
  | NegConjecture -- the negated conjecture / goal
  | Derived       -- derived via inference (includes Twee rewriting steps)
  deriving (Show, Eq)

data LeafEntry = LeafEntry
  { lePos     :: String          -- bit-string position in the expanded tree
  , leUnit    :: String          -- the unit's own name
  , leName    :: String          -- resolved source name
  , leDecl    :: T.Declaration   -- raw TPTP declaration (for clause conversion)
  , leSrcDecl :: T.Declaration   -- source declaration, the same as leDecl for Derived and NegConjecture
  , leRole    :: LeafRole
  , leHyp     :: Bool            -- an axiom that an implication conjecture assumed
  , leSimpl   :: [(String, Dir)] -- the demodulation chain at this position, outermost first
  } deriving (Show)

-- Everything the algorithm needs, extracted once from the proof tree.
data ProofInfo = ProofInfo
  { piElectrons :: [LeafEntry]  -- positive unit nodes (leaf + inner), DFS position order
  , piNuclei    :: [LeafEntry]  -- non-positive-unit nodes (incl. NegConjecture), position order
  , piGoalLits  :: [T.Literal]  -- goal literals from the negated conjecture
  , piDeclAt    :: Map.Map String T.Declaration
      -- the clause at each position on an entry's ancestor chain and at their
      -- siblings, read from the full tree and used to trace θ from the root
  } deriving (Show)
