-- Reading TPTP syntax into Taelja's terms, literals and Horn clauses, and
-- writing a clause back as a TPTP declaration.
module TptpConvert
  ( unitNameStr
  , bodyLitsOf
  , convertLit
  , convertDeclToClause
  , clauseToDecl
  , isReservedTLit
  , convertFOFToClause
  , collectDisjuncts
  , stripForall
  , parseTptp
  , parseProof
  , tptpSymbol
  , isLowerWord
  , topLevelArgs
  , eraseSorts
  , dedupLiterals
  , declSymbols
  , usesDistinctObjects
  , isPositiveUnitFormula
  , headLitOf
  , predicateSymbols
  , isDerivedUnit
  , hasAxiomRole
  , lookupDecl
  , isFileUnit
  , sourceRules
  , sourceParents
  , parentUnits
  , isIntroducedSrc
  , declIsBottom
  , posLitsOfDisjFOF
  , isTDisequality
  , isHornLiterals
  , tptpTerm
  , tptpLiteral
  , unitParents
  , isConjectureDecl
  , isFileSourced
  , splitAtClosing
  , tptpLitVars
  , unitNameOf
  , resolutionSource
  , premiseUses
  ) where

import Data.Attoparsec.Text (eitherResult, feed)
import Data.Char (isAsciiLower, isAsciiUpper, isDigit)
import Data.List (intercalate, isInfixOf, isPrefixOf, nub, partition, tails)
import Data.List.NonEmpty (NonEmpty (..), toList)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import Data.TPTP.Parse.Text (parseTSTP)

import Types
import Helpers (capitalize, quoted)

-- A unit's name as written, a word or a number.
unitNameStr :: T.UnitName -> String
unitNameStr (Left (T.Atom t)) = Text.unpack t
unitNameStr (Right n)         = show n

-- A unit name from its text.
unitNameOf :: String -> T.UnitName
unitNameOf nm = Left (T.Atom (Text.pack nm))

-- The source of a resolution between two named units.
resolutionSource :: [T.Info] -> String -> String -> T.Source
resolutionSource info l r =
  T.Inference (T.Atom (Text.pack "resolution")) info [ T.Parent (T.UnitSource (unitNameOf p)) [] | p <- [l, r] ]

-- The function and predicate symbols of a cnf, fof or tff declaration.
declSymbols :: T.Declaration -> ([String], [String])
declSymbols (T.Formula _ (T.CNF (T.Clause lits))) = literalSymbols [ l | (_, l) <- toList lits ]
declSymbols (T.Formula _ (T.FOF f))               = literalSymbols (atoms f)
declSymbols (T.Formula _ (T.TFF0 f))              = literalSymbols (atoms f)
declSymbols _                                     = ([], [])

-- The atoms of a formula, in order.
atoms :: T.FirstOrder s -> [T.Literal]
atoms (T.Atomic l)         = [l]
atoms (T.Negated f)        = atoms f
atoms (T.Connected l _ r)  = atoms l ++ atoms r
atoms (T.Quantified _ _ f) = atoms f

-- The function and predicate symbols of a list of atoms.
literalSymbols :: [T.Literal] -> ([String], [String])
literalSymbols ls = (concatMap funcs ls, [ Text.unpack p | T.Predicate (T.Defined (T.Atom p)) _ <- ls ])
  where
    funcs (T.Predicate _ ts) = concatMap termF ts
    funcs (T.Equality l _ r) = termF l ++ termF r
    termF (T.Function (T.Defined (T.Atom f)) ts) = Text.unpack f : concatMap termF ts
    termF (T.Function _ ts)                      = concatMap termF ts
    termF _                                      = []

-- Reads a monomorphic typed problem or proof as an untyped one. Every proof
-- step already respects the sorts, so dropping type declarations and
-- quantifier sorts leaves the same derivation. Polymorphic formulas are left
-- alone.
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

-- Whether a declaration uses distinct objects, a "quoted" term or $distinct.
-- Their inequality is a theory fact, not an inference of the calculus.
usesDistinctObjects :: T.Declaration -> Bool
usesDistinctObjects d = case d of
  T.Formula _ (T.CNF (T.Clause lits)) -> any (litHas . snd) (toList lits)
  T.Formula _ (T.FOF f)               -> formulaHas f
  T.Formula _ (T.TFF0 f)              -> formulaHas f
  _                                   -> False
  where
    formulaHas (T.Atomic l)         = litHas l
    formulaHas (T.Negated g)        = formulaHas g
    formulaHas (T.Connected l _ r)  = formulaHas l || formulaHas r
    formulaHas (T.Quantified _ _ b) = formulaHas b
    litHas (T.Predicate (T.Reserved (T.Standard T.Distinct)) _) = True
    litHas (T.Predicate _ ts) = any termHas ts
    litHas (T.Equality a _ b) = termHas a || termHas b
    termHas (T.DistinctTerm _) = True
    termHas (T.Function _ ts)  = any termHas ts
    termHas _                  = False

-- Removes repeated literals from a clause. Provers may print p | p before
-- removing the copy (SYN046+1), and the unit and Horn checks count literals.
-- A fof clause is rebuilt as a disjunction under its quantifier prefix, and
-- any other unit is left alone.
dedupLiterals :: T.Unit -> T.Unit
dedupLiterals u@(T.Unit n d a) = case d of
  T.Formula r (T.CNF (T.Clause lits))
    | ls <- toList lits, ls' <- nub ls, length ls' < length ls
    , (x : xs) <- ls' -> T.Unit n (T.Formula r (T.CNF (T.Clause (x :| xs)))) a
  T.Formula r (T.FOF f)
    | Just pairs <- collectDisjuncts f, pairs' <- nub pairs, length pairs' < length pairs ->
        T.Unit n (T.Formula r (T.FOF (prefix f (foldr1 (`T.Connected` T.Disjunction) (map lit pairs'))))) a
  _ -> u
  where
    prefix (T.Quantified q vs b) g = T.Quantified q vs (prefix b g)
    prefix _ g                     = g
    lit (T.Positive, l) = T.Atomic l
    lit (T.Negative, l) = T.Negated (T.Atomic l)
dedupLiterals u = u

-- The negative literals of a clause in positive form, [p(X)] for ~p(X) | q(X).
-- A fof clause is read through collectDisjuncts as convertDeclToClause reads
-- it, since a missed body literal would let a Horn clause pass for a unit
-- lemma.
bodyLitsOf :: T.Declaration -> [T.Literal]
bodyLitsOf (T.Formula _ (T.CNF (T.Clause lits))) =
  [l | (T.Negative, l) <- toList lits]
bodyLitsOf (T.Formula _ (T.FOF f)) =
  [ l | Just pairs <- [collectDisjuncts f], (T.Negative, l) <- pairs ]
bodyLitsOf _ = []

-- A TPTP term as a Taelja term. An integer becomes a constant.
convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) [])   = Const (Text.unpack f)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = App (Text.unpack f) (map convertTerm args)
convertTerm (T.Number (T.IntegerConstant n))          = Const (show n)
convertTerm t = error ("convertTerm: unsupported: " ++ show t)

-- The variables of a TPTP literal in order, with repeats.
tptpLitVars :: T.Literal -> [T.Var]
tptpLitVars l = case l of
    T.Predicate _ ts -> concatMap termVars ts
    T.Equality a _ b -> termVars a ++ termVars b
  where
    termVars (T.Variable v)    = [v]
    termVars (T.Function _ ts) = concatMap termVars ts
    termVars _                 = []

-- A TPTP atom as a positive literal, or a disequality as an NEq.
convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit t = error ("convertLit: unsupported: " ++ show t)

-- A cnf or fof declaration as a Horn clause, Nothing when it is not one.
convertDeclToClause :: T.Declaration -> Maybe Clause
convertDeclToClause (T.Formula _ (T.CNF (T.Clause lits))) = signedToClause (toList lits)
convertDeclToClause (T.Formula _ (T.FOF f)) = convertFOFToClause f
convertDeclToClause _ = Nothing

-- A clause as a cnf declaration, $false when empty.
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
    toTTerm (Fresh v)  = T.Variable (T.Var (Text.pack v))
    toTTerm (Const c)  = T.Function (T.Defined (T.Atom (Text.pack c))) []
    toTTerm (App f ts) = T.Function (T.Defined (T.Atom (Text.pack f))) (map toTTerm ts)

-- A Horn clause from its body and positive literals. A disequality moves to the
-- body as an equation, and more than one other literal gives Nothing.
hornClause :: [Literal] -> [Literal] -> Maybe Clause
hornClause body hs =
  let (neqs, others) = partition isNEq hs
      body'          = body ++ [Eq s t | NEq s t <- neqs]
  in case others of
       []  -> Just (Clause body' Nothing)
       [h] -> Just (Clause body' (Just h))
       _   -> Nothing

-- Whether a literal is a disequality.
isNEq :: Literal -> Bool
isNEq (NEq _ _) = True
isNEq _         = False

-- Whether a TPTP literal is a disequality s != t.
isTDisequality :: T.Literal -> Bool
isTDisequality (T.Equality _ T.Negative _) = True
isTDisequality _                           = False

-- Whether signed TPTP literals form a Horn clause, with at most one positive
-- literal. A disequality counts as negative and a truth constant as none.
isHornLiterals :: [(T.Sign, T.Literal)] -> Bool
isHornLiterals ls = length [ () | (T.Positive, l) <- ls, not (isReservedTLit l), not (isTDisequality l) ] <= 1

-- Whether a TPTP atom has a reserved predicate such as $true or $false.
isReservedTLit :: T.Literal -> Bool
isReservedTLit (T.Predicate (T.Reserved _) _) = True
isReservedTLit _                              = False

-- A fof formula as a Horn clause, Nothing when it is not one.
convertFOFToClause :: T.UnsortedFirstOrder -> Maybe Clause
convertFOFToClause fof = collectDisjuncts fof >>= signedToClause

-- A disjunction of signed literals as a Horn clause. False literals ($false,
-- ~$true) are dropped. A true literal makes the clause a tautology, and other
-- reserved predicates are not interpreted, so both give Nothing.
signedToClause :: [(T.Sign, T.Literal)] -> Maybe Clause
signedToClause ls
  | any isTrue ls = Nothing
  | any (isReservedTLit . snd) rest = Nothing
  | otherwise = hornClause [ convertLit l | (T.Negative, l) <- rest ] [ convertLit l | (T.Positive, l) <- rest ]
  where
    rest = filter (not . isFalse) ls
    isTrue (T.Positive, l)  = l == truth T.Tautology
    isTrue (T.Negative, l)  = l == truth T.Falsum
    isFalse (T.Positive, l) = l == truth T.Falsum
    isFalse (T.Negative, l) = l == truth T.Tautology
    truth c = T.Predicate (T.Reserved (T.Standard c)) []

-- The signed literals of a formula read as one clause under its universal
-- prefix. Nothing when it is not a clause.
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
  (++) <$> disjunctLiterals l <*> disjunctLiterals r
collectDisjuncts (T.Connected body T.Implication hd) =
  (++) <$> collectImplBody body <*> collectDisjuncts hd
  where
    -- an antecedent s != t is the positive literal s = t of the clause
    collectImplBody (T.Atomic (T.Equality l T.Negative r)) = Just [(T.Positive, T.Equality l T.Positive r)]
    collectImplBody (T.Atomic lit)              = Just [(T.Negative, lit)]
    collectImplBody (T.Connected l T.Conjunction r) =
      (++) <$> collectImplBody l <*> collectImplBody r
    -- Anything else is read as its negation. ! [X] : p(X) has no reading,
    -- since ~p(X) | q would state the stronger (? [X] : p(X)) => q.
    collectImplBody f = collectDisjuncts (T.Negated f)
collectDisjuncts _ = Nothing

-- The signed literals of one disjunct. A disequality s != t here is the
-- negative literal of s = t.
disjunctLiterals :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
disjunctLiterals (T.Atomic (T.Equality l T.Negative r)) =
  Just [(T.Negative, T.Equality l T.Positive r)]
disjunctLiterals f = collectDisjuncts f

-- A formula without its leading universal quantifiers.
stripForall :: T.UnsortedFirstOrder -> T.UnsortedFirstOrder
stripForall (T.Quantified T.Forall _ b) = stripForall b
stripForall g                           = g

-- A TPTP lower word, which needs no quotes. A digit string is not one, so a
-- constant such as E's '0' stays quoted and is not read as a number.
isLowerWord :: String -> Bool
isLowerWord (c : cs) = isAsciiLower c && all (\x -> isAsciiLower x || isAsciiUpper x || isDigit x || x == '_') cs
isLowerWord []       = False

-- A symbol in TPTP syntax. Lower words and defined symbols such as $false
-- stay bare, and anything else is quoted, as in '+'.
tptpSymbol :: String -> String
tptpSymbol s@('$' : _) = s
tptpSymbol s
  | isLowerWord s = s
  | otherwise     = quoted s

-- A term in TPTP syntax. A variable starts upper case, as TPTP requires.
tptpTerm :: Term -> String
tptpTerm (Var v)    = capitalize v
tptpTerm (Fresh v)  = capitalize v
tptpTerm (Const c)  = tptpSymbol c
tptpTerm (App f []) = tptpSymbol f
tptpTerm (App f ts) = tptpSymbol f ++ "(" ++ intercalate "," (map tptpTerm ts) ++ ")"

-- A literal in TPTP syntax. A predicate is written like a function symbol, so
-- one that is no lower word, as '>=', is quoted.
tptpLiteral :: Literal -> String
tptpLiteral (Eq l r)    = tptpTerm l ++ " = " ++ tptpTerm r
tptpLiteral (NEq l r)   = tptpTerm l ++ " != " ++ tptpTerm r
tptpLiteral (Rel n ts)  = tptpTerm (App n ts)
tptpLiteral (NRel n ts) = "~ " ++ tptpTerm (App n ts)

-- Parses TPTP text, marking its end so the parser does not wait for more.
parseTptp :: Text.Text -> Either String T.TSTP
parseTptp t = eitherResult (feed (parseTSTP t) mempty)

-- Parse the proof in a prover's output.
parseProof :: String -> Either String T.TSTP
parseProof = parseTptp . Text.pack . extractSzsBlock

-- Cut prover output to its SZS output block, since provers such as Twee
-- surround it with text that is not TSTP, and rewrite the forms the parser
-- cannot read. Text without markers is kept whole.
extractSzsBlock :: String -> String
extractSzsBlock txt = dropIntroducedParents $ typedClausesAsFormulas $ quoteDollarTypings $ dropDistinctTypings $
  case break isStart (lines txt) of
    (_, [])        -> txt
    (_, startLine : rest) ->
      let (body, restEnd) = break isEnd rest
          endLine = take 1 restEnd
      in if any isUnit body
           then unlines (startLine : body ++ endLine)
           -- A TPTP solution file has its only SZS markers in a commented
           -- copy of the raw output below the proof, so it is kept whole.
           else txt
  where
    isStart l = "SZS output start" `isInfixOf` l
    isEnd   l = "SZS output end"   `isInfixOf` l
    isUnit  l = any (`isPrefixOf` dropWhile (== ' ') l) ["cnf(", "fof(", "tff(", "tcf("]

-- Drop E's type declarations of distinct objects, such as
-- tff(d, type, "Apple": $i). The parser rejects them and they are not needed.
dropDistinctTypings :: String -> String
dropDistinctTypings = unlines . filter (not . distinctTyping) . lines
  where
    distinctTyping l = "tff(" `isPrefixOf` l && ", type, \"" `isInfixOf` l

-- Quote a declared name that E writes as a dollar word, as in
-- tff(d, type, $ki_local_world: '$ki_world'). The parser reads a declared name
-- only as a plain or quoted word, and the rest of the proof quotes it.
quoteDollarTypings :: String -> String
quoteDollarTypings = unlines . map fix . lines
  where
    key = ", type, $"
    fix l = case [ i | (i, t) <- zip [0 ..] (tails l), key `isPrefixOf` t ] of
      (i : _) | "tff(" `isPrefixOf` l ->
        let (before, rest) = splitAt (i + length key - 1) l
            (nm, after)    = break (`elem` ": ") rest
        in before ++ "'" ++ nm ++ "'" ++ after
      _ -> l

-- Read E's tcf units, which the parser does not know, as tff. A tcf is a tff
-- whose formula is a clause.
typedClausesAsFormulas :: String -> String
typedClausesAsFormulas = unlines . map fix . lines
  where
    fix l | "tcf(" `isPrefixOf` l = "tff(" ++ drop 4 l
          | otherwise             = l

-- The parser reads only introduced(kind, [info]), so drop the third argument,
-- a list of parents, that Vampire and current TPTP add.
dropIntroducedParents :: String -> String
dropIntroducedParents = go
  where
    key = "introduced("
    go [] = []
    go s@(c : cs)
      | key `isPrefixOf` s =
          let (inner, rest) = splitAtClosing (drop (length key) s)
          in key ++ intercalate "," (take 2 (topLevelArgs inner)) ++ ")" ++ go rest
      | otherwise = c : go cs

-- The text up to the parenthesis that closes an open one, and the text after it.
splitAtClosing :: String -> (String, String)
splitAtClosing = walk (0 :: Int)
  where
    walk _ [] = ([], [])
    walk d (x : xs)
      | x == ')' && d == 0 = ([], xs)
      | x `elem` "([" = first (x :) (walk (d + 1) xs)
      | x `elem` ")]" = first (x :) (walk (d - 1) xs)
      | otherwise     = first (x :) (walk d xs)
    first f (a, b) = (f a, b)

-- The arguments of a term's text, split at the commas outside brackets.
topLevelArgs :: String -> [String]
topLevelArgs = walk (0 :: Int) []
  where
    walk _ acc [] = [reverse acc]
    walk d acc (x : xs)
      | x == ',' && d == 0 = reverse acc : walk d [] xs
      | x `elem` "([" = walk (d + 1) (x : acc) xs
      | x `elem` ")]" = walk (d - 1) (x : acc) xs
      | otherwise     = walk d (x : acc) xs

-- Whether a declaration is a positive unit, which the tree reads as an
-- electron. A disequality or truth constant is none.
isPositiveUnitFormula :: T.Declaration -> Bool
isPositiveUnitFormula (T.Formula _ (T.FOF f))  = isPosAtomFOF f
isPositiveUnitFormula (T.Formula _ (T.CNF cl)) = isPosAtomCNF cl
isPositiveUnitFormula _                        = False

-- Whether a formula is a positive atom or equation under universal quantifiers.
isPosAtomFOF :: T.UnsortedFirstOrder -> Bool
isPosAtomFOF (T.Quantified T.Forall _ body)           = isPosAtomFOF body
isPosAtomFOF (T.Atomic (T.Equality _ T.Positive _))   = True
isPosAtomFOF (T.Atomic (T.Predicate (T.Defined _) _)) = True
isPosAtomFOF _                                         = False

-- Whether a clause is a single positive atom or equation.
isPosAtomCNF :: T.Clause -> Bool
isPosAtomCNF (T.Clause lits) = case toList lits of
  [(T.Positive, T.Equality _ T.Positive _)]   -> True
  [(T.Positive, T.Predicate (T.Defined _) _)] -> True
  _                                           -> False

-- The head of a clause or formula, its only positive literal. A disequality
-- counts as positive here.
headLitOf :: T.Declaration -> Maybe T.Literal
headLitOf (T.Formula _ (T.CNF (T.Clause lits))) =
  case [l | (T.Positive, l) <- toList lits] of
    [l] -> Just l
    _   -> Nothing
headLitOf (T.Formula _ (T.FOF f)) = headLitOfFOF f
headLitOf _ = Nothing

-- headLitOf for a formula. The head is the atom itself, the atomic consequent
-- of an implication or the only positive disjunct.
headLitOfFOF :: T.UnsortedFirstOrder -> Maybe T.Literal
headLitOfFOF (T.Quantified T.Forall _ body)               = headLitOfFOF body
headLitOfFOF (T.Atomic lit)                               = Just lit
headLitOfFOF (T.Connected _ T.Implication (T.Atomic lit)) = Just lit
headLitOfFOF f = case posLitsOfDisjFOF f of
  [lit] -> Just lit
  _     -> Nothing

-- The positive literals of a disjunction, where a disequality counts as
-- positive.
posLitsOfDisjFOF :: T.UnsortedFirstOrder -> [T.Literal]
posLitsOfDisjFOF (T.Atomic lit)                   = [lit]
posLitsOfDisjFOF (T.Negated _)                    = []
posLitsOfDisjFOF (T.Connected l T.Disjunction r)  =
  posLitsOfDisjFOF l ++ posLitsOfDisjFOF r
posLitsOfDisjFOF _                                = []

-- Whether a declaration states $false, also written as ~$true.
declIsBottom :: T.Declaration -> Bool
declIsBottom (T.Formula _ (T.CNF cl)) = isFalsum cl
declIsBottom (T.Formula _ (T.FOF (T.Atomic
  (T.Predicate (T.Reserved (T.Standard T.Falsum)) [])))) = True
declIsBottom (T.Formula _ (T.FOF (T.Negated (T.Atomic
  (T.Predicate (T.Reserved (T.Standard T.Tautology)) []))))) = True
declIsBottom _ = False

-- Whether a clause is $false.
isFalsum :: T.Clause -> Bool
isFalsum (T.Clause lits) = case toList lits of
  [(T.Positive, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])] -> True
  _ -> False

-- The predicate symbols of all units.
predicateSymbols :: [T.Unit] -> Set.Set String
predicateSymbols units = Set.fromList [ p | T.Unit _ d _ <- units, p <- snd (declSymbols d) ]

-- Whether a unit was derived by an inference.
isDerivedUnit :: T.Unit -> Bool
isDerivedUnit (T.Unit _ _ (Just (T.Inference {}, _))) = True
isDerivedUnit _                                           = False

-- Whether a declaration has the axiom or hypothesis role.
hasAxiomRole :: T.Declaration -> Bool
hasAxiomRole (T.Formula (T.Standard T.Axiom)      _) = True
hasAxiomRole (T.Formula (T.Standard T.Hypothesis) _) = True
hasAxiomRole _                                        = False

-- The declaration of a named unit.
lookupDecl :: Map.Map String T.Unit -> String -> Maybe T.Declaration
lookupDecl unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ d _) -> Just d
  _                   -> Nothing

-- An input unit, sourced from a file or with no source at all. Hand-written
-- and TPTP-tool proofs may state axioms without one.
isFileUnit :: Map.Map String T.Unit -> String -> Bool
isFileUnit unitMap name = maybe False isFileSourced (Map.lookup name unitMap)

-- Whether a unit comes from the problem file or is stated with no source.
isFileSourced :: T.Unit -> Bool
isFileSourced (T.Unit _ _ Nothing)                = True
isFileSourced (T.Unit _ _ (Just (T.File _ _, _))) = True
isFileSourced _                                   = False

-- A unit the prover introduced itself, like E's introduced(definition).
isIntroducedSrc :: Map.Map String T.Unit -> String -> Bool
isIntroducedSrc unitMap name = case Map.lookup name unitMap of
  Just (T.Unit _ _ (Just (T.Introduced _ _, _))) -> True
  _                                              -> False

-- The rules of an inference, the outer one first.
sourceRules :: T.Source -> [Text.Text]
sourceRules (T.Inference (T.Atom r) _ ps) = r : concat [ sourceRules i | T.Parent i@(T.Inference {}) _ <- ps ]
sourceRules _                             = []

-- The units an inference rests on, in the order a nested inference uses them.
sourceParents :: T.Source -> [String]
sourceParents (T.Inference _ _ ps) = concatMap parentUnits ps
sourceParents _ = []

-- The units a parent names, through nested inferences.
parentUnits :: T.Parent -> [String]
parentUnits (T.Parent (T.UnitSource pn) _)  = [unitNameStr pn]
parentUnits (T.Parent i@(T.Inference {}) _) = sourceParents i
parentUnits _                               = []

-- How often each unit is a premise, counting every occurrence in every
-- inference, so a premise a step uses twice counts twice.
premiseUses :: [T.Unit] -> Map.Map String Int
premiseUses units = Map.fromListWith (+)
  [ (p, 1) | T.Unit _ _ (Just (T.Inference _ _ ps, _)) <- units, p <- concatMap parentUnits ps ]

-- The names of the units a unit's source cites, through nested inferences.
unitParents :: T.Unit -> [String]
unitParents (T.Unit _ _ (Just (src, _))) = parentUnits (T.Parent src [])
unitParents _ = []

-- Whether a declaration has the conjecture role.
isConjectureDecl :: T.Declaration -> Bool
isConjectureDecl (T.Formula (T.Standard T.Conjecture) _) = True
isConjectureDecl _                                       = False
