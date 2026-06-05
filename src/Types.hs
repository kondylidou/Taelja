module Types where

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

-- at most one positive literal (the head)
data Clause = Clause
  { body :: [Literal]       -- negative literals
  , hd   :: Maybe Literal   -- positive literal; Nothing for a goal clause
  } deriving (Eq, Show)

-- variable name → term
type Subst = [(String, Term)]

data Dir = LR | RL deriving (Eq, Show)

data RwStep = RwStep
  { rwName :: String
  , rwEq   :: (Term, Term)
  , rwDir  :: Dir
  } deriving (Show)

-- entry in the Units set; ueDeriv holds the proof block for unnamed intermediates
data UnitEntry = UnitEntry
  { ueName  :: Maybe String
  , ueUnit  :: Literal
  , ueDeriv :: Maybe ProofBlock
  } deriving (Show)

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
  = ByAxiom String             -- by axiom/lemma N
  | ByRw    String (Maybe Dir) -- by rw name [R->L]
  deriving (Show)

data StructuredProof = StructuredProof
  { axioms :: [(String, Literal)]
  , lemmas :: [(String, Literal, ProofBlock)]
  , goal   :: (Literal, ProofBlock)
  } deriving (Show)
