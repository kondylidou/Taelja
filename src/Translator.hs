module Translator where

import qualified Data.TPTP as T
import Data.List (partition)
import Data.List.NonEmpty (toList)
import qualified Data.Text as Text
import Control.Monad.State

import Types

data TransState = TransState
  { tsUnits      :: [UnitEntry]
  , tsLemmaCount :: Int
  , tsLemmas     :: [(String, Literal, ProofBlock)]
  }

type TransM a = State TransState a

translate :: T.TSTP -> StructuredProof
translate (T.TSTP _ units) =
  let (_axUnits, _axNonUnits, _goalLit) = classifyAxioms units
  in error "translate: TODO"

-- Separate TSTP units into positive unit axioms, non-unit Horn axioms, and the goal.
-- Axioms come as FOF units in E's output; the negated conjecture comes as CNF.
classifyAxioms :: [T.Unit]
               -> ([(String, Literal)], [(Maybe String, Clause, Subst)], Literal)
classifyAxioms units =
  let fofAxioms = [ (unitNameToString n, f)
                  | T.Unit n (T.Formula (T.Standard T.Axiom) (T.FOF f)) _ <- units ]
      negConj   = [ cl
                  | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.CNF cl))
                              (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                  , rule == Text.pack "split_conjunct" -- E's rule for negating the conjecture
                  , not (isFalsum cl) ]
      (unitFOFs, nonUnitFOFs) = partition (isPositiveUnitFOF . snd) fofAxioms
      axUnits    = [ (n, extractUnitFOF f)      | (n, f) <- unitFOFs    ]
      axNonUnits = [ (Just n, fofToClause f, []) | (n, f) <- nonUnitFOFs ]
      goalLit    = case negConj of
                     [cl] -> negateGoal cl
                     _    -> error "classifyAxioms: expected exactly one negated conjecture"
  in (axUnits, axNonUnits, goalLit)

isPositiveUnitFOF :: T.UnsortedFirstOrder -> Bool
isPositiveUnitFOF (T.Atomic _)                   = True
isPositiveUnitFOF (T.Quantified T.Forall _ body) = isPositiveUnitFOF body
isPositiveUnitFOF _                              = False

extractUnitFOF :: T.UnsortedFirstOrder -> Literal
extractUnitFOF (T.Atomic lit)                  = convertLit lit
extractUnitFOF (T.Quantified T.Forall _ body)  = extractUnitFOF body
extractUnitFOF _                               = error "extractUnitFOF: not a positive unit"

-- Convert a FOF Horn clause ∀x̄. P₁ ∧ … ∧ Pₙ → H to our Clause type.
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

isFalsum :: T.Clause -> Bool
isFalsum (T.Clause lits) = case toList lits of
  [(_, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])] -> True
  _ -> False

negateGoal :: T.Clause -> Literal
negateGoal (T.Clause lits) = case toList lits of
  [(T.Negative, lit)]                       -> convertLit lit
  [(T.Positive, T.Equality l T.Negative r)] -> Eq (convertTerm l) (convertTerm r)
  _ -> error "negateGoal: unexpected negated conjecture shape"

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

-- TODO
topoSort :: [(Maybe String, Clause, Subst)] -> [T.Unit] -> [(Maybe String, Clause, Subst)]
topoSort _ _ = error "TODO"

translatePureEquational :: Literal -> TransM ProofBlock
translatePureEquational _ = error "TODO"

translateNonUnits :: [(Maybe String, Clause, Subst)] -> Literal -> TransM ProofBlock
translateNonUnits _ _ = error "TODO"

processNonUnit :: Maybe String -> Clause -> Subst -> Literal -> TransM (Maybe ProofBlock)
processNonUnit _ _ _ _ = error "TODO"

ensureNamed :: Literal -> TransM String
ensureNamed _ = error "TODO"

makeBlock :: UnitEntry -> [(String, (Term, Term), Dir)] -> TransM ProofBlock
makeBlock _ _ = error "TODO"

rwChainTo :: Term -> Term -> TransM (Term, [(RwStep, Term)])
rwChainTo _ _ = error "TODO"

freshLemmaNum :: TransM Int
freshLemmaNum = error "TODO"

emitLemma :: String -> Literal -> ProofBlock -> TransM ()
emitLemma _ _ _ = error "TODO"

modifyUnit :: Literal -> UnitEntry -> TransM ()
modifyUnit _ _ = error "TODO"

addToUnits :: UnitEntry -> TransM ()
addToUnits _ = error "TODO"

findUnitByLit :: Literal -> [UnitEntry] -> Maybe UnitEntry
findUnitByLit _ _ = error "TODO"

applySubst :: Subst -> Literal -> Literal
applySubst _ _ = error "TODO"

rewrite :: Term -> Term -> Term -> Term
rewrite _ _ _ = error "TODO"
