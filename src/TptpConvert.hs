module TptpConvert
  ( bodyLitsOf
  , bodyLitsOfFOF
  , convertTerm
  , convertLit
  , convertDeclToClause
  , clauseToDecl
  , mkClause
  , isNEq
  , isReservedTLit
  , convertFOFToClause
  , collectDisjuncts
  , collectDisjunct
  , eraseSorts
  , declSymbols
  ) where

import Data.List (partition)
import Data.List.NonEmpty (NonEmpty (..), toList)
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types

-- The function and predicate symbols of a declaration, in any formula form.
declSymbols :: T.Declaration -> ([String], [String])
declSymbols (T.Formula _ (T.CNF (T.Clause lits))) = both [ l | (_, l) <- toList lits ]
declSymbols (T.Formula _ (T.FOF f))               = both (atoms f)
declSymbols (T.Formula _ (T.TFF0 f))              = both (atoms f)
declSymbols _                                     = ([], [])

atoms :: T.FirstOrder s -> [T.Literal]
atoms (T.Atomic l)         = [l]
atoms (T.Negated f)        = atoms f
atoms (T.Connected l _ r)  = atoms l ++ atoms r
atoms (T.Quantified _ _ f) = atoms f

both :: [T.Literal] -> ([String], [String])
both ls = (concatMap funcs ls, [ Text.unpack p | T.Predicate (T.Defined (T.Atom p)) _ <- ls ])
  where
    funcs (T.Predicate _ ts) = concatMap termF ts
    funcs (T.Equality l _ r) = termF l ++ termF r
    termF (T.Function (T.Defined (T.Atom f)) ts) = Text.unpack f : concatMap termF ts
    termF (T.Function _ ts)                      = concatMap termF ts
    termF _                                      = []

-- A monomorphic typed proof read as an untyped one.  The sorts only restrict
-- which terms a variable ranges over, and every step of the proof already
-- respects them, so dropping the quantifier sorts and the type declarations
-- leaves the same derivation.  Polymorphic formulae are kept as they are.
eraseSorts :: T.TSTP -> T.TSTP
eraseSorts (T.TSTP szs units) = T.TSTP szs (concatMap erase units)
  where
    erase (T.Unit _ (T.Typing _ _) _) = []
    erase (T.Unit _ (T.Sort _ _) _)   = []
    erase (T.Unit n (T.Formula r (T.TFF0 f)) a) = [T.Unit n (T.Formula r (T.FOF (untyped f))) a]
    erase u = [u]
    untyped (T.Atomic l)            = T.Atomic l
    untyped (T.Negated f)           = T.Negated (untyped f)
    untyped (T.Connected l c r)     = T.Connected (untyped l) c (untyped r)
    untyped (T.Quantified q vs f)   = T.Quantified q (fmap (\(v, _) -> (v, T.Unsorted ())) vs) (untyped f)

-- The body of a Horn clause, its negative literals in positive form.  For
-- ~p(X) \/ q(X) this is [p(X)].
bodyLitsOf :: T.Declaration -> [T.Literal]
bodyLitsOf (T.Formula _ (T.CNF (T.Clause lits))) =
  [l | (T.Negative, l) <- toList lits]
bodyLitsOf (T.Formula _ (T.FOF f)) = bodyLitsOfFOF f
bodyLitsOf _ = []

-- Body and head literals of an FOF Horn clause, written as a quantified
-- disjunction, an implication or with negated equalities.  Both go through
-- collectDisjuncts so they agree with convertDeclToClause.  A dropped body
-- literal would turn an axiom into a false unit.
bodyLitsOfFOF :: T.UnsortedFirstOrder -> [T.Literal]
bodyLitsOfFOF f = [ l | Just pairs <- [collectDisjuncts f], (T.Negative, l) <- pairs ]

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
      -- Reserved literals $true and $false carry no content and convertLit has
      -- no case for them, so they are dropped from both sides.
      bodyLits = [convertLit l | (T.Negative, l) <- ls, not (isReservedTLit l)]
      headLits = [convertLit l | (T.Positive, l) <- ls, not (isReservedTLit l)]
  in mkClause bodyLits headLits
convertDeclToClause (T.Formula _ (T.FOF f)) = convertFOFToClause f
convertDeclToClause _ = Nothing

-- The converse, as a CNF declaration (an empty clause is $false).
clauseToDecl :: Clause -> T.Declaration
clauseToDecl (Clause bs mh) = T.Formula (T.Standard T.Plain) (T.CNF (T.Clause lits))
  where
    lits = case [ (T.Negative, toTLit l) | l <- bs ] ++ [ (T.Positive, toTLit h) | Just h <- [mh] ] of
      []       -> pure (T.Positive, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])
      (x : xs) -> x :| xs
    toTLit (Rel n ts)  = T.Predicate (T.Defined (T.Atom (Text.pack n))) (map toTTerm ts)
    toTLit (NRel n ts) = T.Predicate (T.Defined (T.Atom (Text.pack n))) (map toTTerm ts)
    toTLit (Eq l r)    = T.Equality (toTTerm l) T.Positive (toTTerm r)
    toTLit (NEq l r)   = T.Equality (toTTerm l) T.Negative (toTTerm r)
    toTTerm (Var v)    = T.Variable (T.Var (Text.pack v))
    toTTerm (Const c)  = T.Function (T.Defined (T.Atom (Text.pack c))) []
    toTTerm (App f ts) = T.Function (T.Defined (T.Atom (Text.pack f))) (map toTTerm ts)

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
    let bodyLits = [convertLit l | (T.Negative, l) <- pairs, not (isReservedTLit l)]
        headLits = [convertLit l | (T.Positive, l) <- pairs, not (isReservedTLit l)]
    in mkClause bodyLits headLits

collectDisjuncts :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
collectDisjuncts (T.Quantified T.Forall _ body) = collectDisjuncts body
collectDisjuncts (T.Atomic lit)                  = Just [(T.Positive, lit)]
-- ~(a != b) is the positive literal a = b
collectDisjuncts (T.Negated (T.Atomic (T.Equality l T.Negative r))) =
  Just [(T.Positive, T.Equality l T.Positive r)]
collectDisjuncts (T.Negated (T.Atomic lit))      = Just [(T.Negative, lit)]
-- ~(A & B) is ~A | ~B, ~ ? X F is ! X ~F, and a double negation cancels
collectDisjuncts (T.Negated (T.Connected l T.Conjunction r)) =
  (++) <$> collectDisjuncts (T.Negated l) <*> collectDisjuncts (T.Negated r)
collectDisjuncts (T.Negated (T.Quantified T.Exists _ body)) = collectDisjuncts (T.Negated body)
collectDisjuncts (T.Negated (T.Negated f))       = collectDisjuncts f
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
