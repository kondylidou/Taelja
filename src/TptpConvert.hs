module TptpConvert
  ( bodyLitsOf
  , bodyLitsOfFOF
  , negLitsOfFOF
  , headLitsOfFOF
  , convertTerm
  , convertLit
  , convertDeclToClause
  , mkClause
  , isNEq
  , isReservedTLit
  , convertFOFToClause
  , collectDisjuncts
  , collectDisjunct
  ) where

import Data.List (partition)
import Data.List.NonEmpty (toList)
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types

-- Negative literals in a Horn clause (CNF or FOF) — the body of the implication.
-- E.g. for ~p(X) \/ q(X), returns [p(X)] (positive form of the body literal).
bodyLitsOf :: T.Declaration -> [T.Literal]
bodyLitsOf (T.Formula _ (T.CNF (T.Clause lits))) =
  [l | (T.Negative, l) <- toList lits]
bodyLitsOf (T.Formula _ (T.FOF f)) = bodyLitsOfFOF f
bodyLitsOf _ = []

bodyLitsOfFOF :: T.UnsortedFirstOrder -> [T.Literal]
bodyLitsOfFOF (T.Quantified T.Forall _ body) = bodyLitsOfFOF body
bodyLitsOfFOF (T.Connected l T.Disjunction r) =
  negLitsOfFOF l ++ negLitsOfFOF r
bodyLitsOfFOF _ = []

negLitsOfFOF :: T.UnsortedFirstOrder -> [T.Literal]
negLitsOfFOF (T.Negated (T.Atomic lit))       = [lit]
negLitsOfFOF (T.Connected l T.Disjunction r)  = negLitsOfFOF l ++ negLitsOfFOF r
negLitsOfFOF _                                = []

-- Collect positive literals from a FOF disjunction (ignores negated atoms).
headLitsOfFOF :: T.UnsortedFirstOrder -> [T.Literal]
headLitsOfFOF (T.Quantified T.Forall _ body) = headLitsOfFOF body
headLitsOfFOF (T.Atomic lit)                 = [lit]
headLitsOfFOF (T.Connected l T.Disjunction r) = headLitsOfFOF l ++ headLitsOfFOF r
headLitsOfFOF _                              = []

convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) [])   = Const (Text.unpack f)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = App (Text.unpack f) (map convertTerm args)
convertTerm (T.Number (T.IntegerConstant n))          = Const (show n)
convertTerm t = error ("convertTerm: unsupported: " ++ show t)

convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit t = error ("convertLit: unsupported: " ++ show t)

convertDeclToClause :: T.Declaration -> Maybe Clause
convertDeclToClause (T.Formula _ (T.CNF (T.Clause lits))) =
  let ls       = toList lits
      bodyLits = [convertLit l | (T.Negative, l) <- ls]
      headLits = [convertLit l | (T.Positive, l) <- ls, not (isReservedTLit l)]
  in mkClause bodyLits headLits
convertDeclToClause (T.Formula _ (T.FOF f)) = convertFOFToClause f
convertDeclToClause _ = Nothing

mkClause :: [Literal] -> [Literal] -> Maybe Clause
mkClause body hs =
  let (neqs, others) = partition isNEq hs
      body'          = body ++ [Eq s t | NEq s t <- neqs]
  in case others of
       []  -> Just (Clause body' Nothing)
       [h] -> Just (Clause body' (Just h))
       _   -> Nothing

isNEq :: Literal -> Bool
isNEq (NEq _ _) = True
isNEq _         = False

isReservedTLit :: T.Literal -> Bool
isReservedTLit (T.Predicate (T.Reserved _) _) = True
isReservedTLit _                              = False

convertFOFToClause :: T.UnsortedFirstOrder -> Maybe Clause
convertFOFToClause fof = case collectDisjuncts fof of
  Nothing   -> Nothing
  Just pairs ->
    let bodyLits = [convertLit l | (T.Negative, l) <- pairs]
        headLits = [convertLit l | (T.Positive, l) <- pairs, not (isReservedTLit l)]
    in mkClause bodyLits headLits

collectDisjuncts :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
collectDisjuncts (T.Quantified T.Forall _ body) = collectDisjuncts body
collectDisjuncts (T.Atomic lit)                  = Just [(T.Positive, lit)]
collectDisjuncts (T.Negated (T.Atomic lit))      = Just [(T.Negative, lit)]
collectDisjuncts (T.Connected l T.Disjunction r) =
  (++) <$> collectDisjunct l <*> collectDisjunct r
collectDisjuncts (T.Connected body T.Implication hd) =
  (++) <$> collectImplBody body <*> collectDisjuncts hd
  where
    collectImplBody (T.Quantified T.Forall _ b) = collectImplBody b
    collectImplBody (T.Atomic lit)              = Just [(T.Negative, lit)]
    collectImplBody (T.Connected l T.Conjunction r) =
      (++) <$> collectImplBody l <*> collectImplBody r
    collectImplBody f = collectDisjuncts (T.Negated f)
collectDisjuncts _ = Nothing

collectDisjunct :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
collectDisjunct (T.Atomic (T.Equality l T.Negative r)) =
  Just [(T.Negative, T.Equality l T.Positive r)]
collectDisjunct f = collectDisjuncts f
