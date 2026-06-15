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

-- At most one positive literal. A Nothing head marks this as the goal clause.
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

-- An entry in the working unit set. Named entries are lemmas; unnamed entries
-- carry their derivation block so they can be promoted to a lemma on demand.
data UnitEntry = UnitEntry
  { ueName  :: Maybe String
  , ueUnit  :: Literal
  , ueDeriv :: Maybe ProofBlock
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

-- The fully translated proof: axioms in input order, intermediate lemmas, and goal proofs.
data StructuredProof = StructuredProof
  { axioms :: [Axiom]
  , lemmas :: [(String, Literal, ProofBlock)]
  , goals  :: [(Literal, ProofBlock)]
  } deriving (Show)

-- Result of matching a body literal against the unit set.
data BodyMatch = BodyMatch
  { bmEntry     :: UnitEntry
  , bmUnitSubst :: Subst               -- Applied to the stored proof block.
  , bmRewrites  :: [(RwStep, Literal)]
  , bmClauseUpd :: Subst               -- Appended to the running clause substitution.
  }
