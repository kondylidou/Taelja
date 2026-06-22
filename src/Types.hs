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

-- Non-unit Horn clause C = ¬L1 ∨ ... ∨ ¬Ln ∨ L0.
-- body = [L1,...,Ln]: the POSITIVE contents of the negative literals (sign stripped).
-- hd   = Just L0 (unique positive head), or Nothing (⊥, goal clause).
data Clause = Clause
  { body :: [Literal]
  , hd   :: Maybe Literal
  } deriving (Eq, Show)

type Subst = [(String, Term)]

-- Direction of an equation used as a rewrite rule.
data Dir = LR | RL deriving (Eq, Show)

-- One step in a rewrite sequence: the equation used, which direction, and the result.
data RwStep = RwStep
  { rwName :: String
  , rwEq   :: (Term, Term)
  , rwDir  :: Dir
  } deriving (Show)

-- Entry in the working unit set: name (if assigned), unit literal, stored proof, position.
data UnitEntry = UnitEntry
  { ueName  :: Maybe String
  , ueUnit  :: Literal
  , ueProof :: Maybe ProofBlock
  , uePos   :: Maybe String
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
  deriving (Show)

data Axiom
  = AUnit    String Literal
  | ANonUnit String Clause
  deriving (Show)

-- The fully translated proof: axioms in input order, intermediate lemmas, goal proofs.
data StructuredProof = StructuredProof
  { axioms :: [Axiom]
  , lemmas :: [(String, Literal, ProofBlock)]
  , goals  :: [(Literal, ProofBlock)]
  } deriving (Show)

-- Working state threaded through the algorithm (Phases 1–3).
data AlgState = AlgState
  { stUnits   :: [UnitEntry]
  , stLemmas  :: [(String, Literal, ProofBlock)]
  , stGoals   :: [(Literal, ProofBlock)]
  , stCounter :: Int
  }
