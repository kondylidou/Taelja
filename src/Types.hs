module Types where

import Data.Maybe (fromMaybe)

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

data AxiomEntry
  = AUnit    String Literal
  | ANonUnit String Clause
  deriving (Show)

data StructuredProof = StructuredProof
  { axioms :: [AxiomEntry]
  , lemmas :: [(String, Literal, ProofBlock)]
  , goals  :: [(Literal, ProofBlock)]
  } deriving (Show)

-- Variable extraction
termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

litVars :: Literal -> [String]
litVars (Eq l r)    = termVars l ++ termVars r
litVars (NEq l r)   = termVars l ++ termVars r
litVars (Rel _ ts)  = concatMap termVars ts
litVars (NRel _ ts) = concatMap termVars ts

-- Size (for BFS pruning)
termSize :: Term -> Int
termSize (Var _)    = 1
termSize (Const _)  = 1
termSize (App _ ts) = 1 + sum (map termSize ts)

litSize :: Literal -> Int
litSize (Eq l r)    = termSize l + termSize r
litSize (NEq l r)   = termSize l + termSize r
litSize (Rel _ ts)  = sum (map termSize ts)
litSize (NRel _ ts) = sum (map termSize ts)

-- Substitution
applySubstTerm :: Subst -> Term -> Term
applySubstTerm subst (Var x)    = fromMaybe (Var x) (lookup x subst)
applySubstTerm _     (Const c)  = Const c
applySubstTerm subst (App f ts) = App f (map (applySubstTerm subst) ts)

applySubst :: Subst -> Literal -> Literal
applySubst subst (Eq l r)    = Eq  (applySubstTerm subst l) (applySubstTerm subst r)
applySubst subst (NEq l r)   = NEq (applySubstTerm subst l) (applySubstTerm subst r)
applySubst subst (Rel n ts)  = Rel n  (map (applySubstTerm subst) ts)
applySubst subst (NRel n ts) = NRel n (map (applySubstTerm subst) ts)

applySubstLine :: Subst -> ProofLine -> ProofLine
applySubstLine subst (Have  lit nm) = Have  (applySubst subst lit) nm
applySubstLine subst (And   lit nm) = And   (applySubst subst lit) nm
applySubstLine subst (Hence lit j)  = Hence (applySubst subst lit) j

applySubstBlock :: Subst -> ProofBlock -> ProofBlock
applySubstBlock subst (HaveHence ls)    = HaveHence (map (applySubstLine subst) ls)
applySubstBlock subst (EqChain s steps) =
  EqChain (applySubstTerm subst s) (map applyStep steps)
  where
    applyStep (RwStep nm (l, r) d, cur) =
      (RwStep nm (applySubstTerm subst l, applySubstTerm subst r) d, applySubstTerm subst cur)

-- Variable renaming (for pretty-printing)
renameTerm :: [(String, String)] -> Term -> Term
renameTerm r (Var x)    = maybe (Var x) Var (lookup x r)
renameTerm _ (Const c)  = Const c
renameTerm r (App f ts) = App f (map (renameTerm r) ts)

renameLit :: [(String, String)] -> Literal -> Literal
renameLit r (Eq l ri)   = Eq  (renameTerm r l) (renameTerm r ri)
renameLit r (NEq l ri)  = NEq (renameTerm r l) (renameTerm r ri)
renameLit r (Rel n ts)  = Rel n  (map (renameTerm r) ts)
renameLit r (NRel n ts) = NRel n (map (renameTerm r) ts)
