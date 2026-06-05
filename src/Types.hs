module Types where

-- | A term: either a variable, a constant, or a function application.
data Term
  = Var  String
  | Const String
  | App  String [Term]
  deriving (Eq, Ord, Show)

-- | A literal: equational or relational, positive or negative.
data Literal
  = Eq    Term Term   -- s = t
  | NEq   Term Term   -- s ≠ t
  | Rel   String [Term]   -- P(t̄)
  | NRel  String [Term]   -- ¬P(t̄)
  deriving (Eq, Ord, Show)

-- | A Horn clause: at most one positive literal.
data Clause = Clause
  { body :: [Literal]   -- negative literals (body)
  , hd   :: Maybe Literal  -- positive literal (head), Nothing for goal clause
  } deriving (Show)

-- | A substitution: variable name to term.
type Subst = [(String, Term)]

-- | Direction of a rewrite step.
data Dir = LR | RL deriving (Eq, Show)

-- | A single rewrite step using a named equation.
data RwStep = RwStep
  { rwName :: String
  , rwEq   :: (Term, Term)
  , rwDir  :: Dir
  } deriving (Show)

-- | Entry in the Units set.
data UnitEntry = UnitEntry
  { ueName   :: Maybe String  -- Nothing if unnamed/intermediate
  , ueUnit   :: Literal
  , ueStored :: Maybe ProofBlock  -- stored derivation if unnamed
  } deriving (Show)

-- | A block of proof lines (have/hence or equational chain).
data ProofBlock
  = HaveHence [ProofLine]
  | EqChain   Term [(RwStep, Term)]
  deriving (Show)

-- | A single line in a have/hence proof.
data ProofLine
  = Have    Literal String      -- have L by name
  | And     Literal String      -- and  L by name
  | Hence   Literal Justification
  deriving (Show)

data Justification
  = ByAxiom  String             -- by axiom/lemma N
  | ByRw     String (Maybe Dir) -- by rw name [R->L]
  deriving (Show)

-- | A complete structured proof.
data StructuredProof = StructuredProof
  { axioms :: [(String, Literal)]
  , lemmas :: [(String, Literal, ProofBlock)]
  , goal   :: (Literal, ProofBlock)
  } deriving (Show)
