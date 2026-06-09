module Translator where

import qualified Data.TPTP as T
import Data.List (find, partition)
import Data.List.NonEmpty (toList)
import qualified Data.Text as Text
import Control.Applicative ((<|>))
import Control.Monad (foldM)
import Control.Monad.State
import Data.Maybe (fromMaybe, listToMaybe, maybeToList)

import Types

data TransState = TransState
  { tsUnits      :: [UnitEntry]
  , tsLemmaCount :: Int
  , tsLemmas     :: [(String, Literal, ProofBlock)]
  }

type TransM a = State TransState a

translate :: T.TSTP -> StructuredProof
translate (T.TSTP _ units) =
  let (axUnits, axNonUnits, goalLit) = classifyAxioms units
      numberedAxUnits = zipWith (\i (_, lit) -> ("axiom " ++ show i, lit)) [(1::Int)..] axUnits
      initUnits = [ UnitEntry (Just n) lit Nothing | (n, lit) <- numberedAxUnits ]
      initState = TransState { tsUnits = initUnits, tsLemmaCount = 0, tsLemmas = [] }
      (goalBlock, finalState) = runState (mainLoop axNonUnits goalLit) initState
  in StructuredProof
       { axioms = numberedAxUnits
       , lemmas = reverse (tsLemmas finalState)
       , goal   = (goalLit, goalBlock)
       }

mainLoop :: [(Maybe String, Clause, Subst)] -> Literal -> TransM ProofBlock
mainLoop []       goalLit = translateNonUnitsEmpty goalLit
mainLoop nonUnits goalLit = translateNonUnits nonUnits goalLit

-- Equational goals always produce an EqChain regardless of whether a unit
-- could match directly. The chain format is more readable for equations.
translateNonUnitsEmpty :: Literal -> TransM ProofBlock
translateNonUnitsEmpty goal = case goal of
  Eq s t -> do
    steps <- rwChainTo s t
    return (EqChain s steps)
  _ -> do
    units <- gets tsUnits
    case findMatchingUnit goal units of
      Just (ue, subst, rws) -> do
        let rwList = [ (rwEq rs, rwDir rs) | rs <- rws ]
        block <- makeBlock ue rwList
        return (applySubstBlock subst block)
      Nothing ->
        error ("translateNonUnitsEmpty: no unit matches goal: " ++ show goal)

findMatchingUnit :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, [RwStep])
findMatchingUnit goal units = listToMaybe
  [ (ue, subst, rws)
  | ue <- units
  , (subst, rws) <- tryMatchLit (ueUnit ue) goal units []
  ]

-- DFS with visited set prevents cycling on reflexive/symmetric equation sets.
tryMatchLit :: Literal -> Literal -> [UnitEntry] -> [Literal] -> [(Subst, [RwStep])]
tryMatchLit lit goal units = go lit
  where
    eqs = eqUnits units
    go lit' visited = case matchLit lit' goal of
      Just subst  -> [(subst, [])]
      Nothing
        | lit' `elem` visited -> []
        | otherwise           ->
            [ (subst, RwStep nm (origL, origR) dir : rest)
            | (nm, origL, origR)  <- eqs
            , (lhs, rhs, dir)     <- (origL, origR, LR) :
                                     [ (origR, origL, RL) | all (`elem` termVars origR) (termVars origL) ]
            , let lit''            = rewriteLit lhs rhs lit'
            , lit'' /= lit'
            , (subst, rest)           <- go lit'' (lit' : visited)
            ]

-- Fails if any equation has rhs variables absent from lhs (invalid TSTP).
-- Callers must call ensureNamed on any derived equation before it reaches here.
eqUnits :: [UnitEntry] -> [(String, Term, Term)]
eqUnits us =
  [ (nm, l, r)
  | ue    <- us
  , let nm = fromMaybe (error "eqUnits: unnamed equation — call ensureNamed first") (ueName ue)
  , Eq l r <- [ueUnit ue]
  , let extra = filter (`notElem` termVars l) (termVars r)
  , null extra || error ("eqUnits: " ++ nm ++ " has rhs variables not in lhs: " ++ show extra)
  ]

termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (App _ ts) = concatMap termVars ts

translateNonUnits :: [(Maybe String, Clause, Subst)] -> Literal -> TransM ProofBlock
translateNonUnits _ _ = error "translateNonUnits: TODO"

processNonUnit :: Maybe String -> Clause -> Subst -> Literal -> TransM (Maybe ProofBlock)
processNonUnit _ _ _ _ = error "processNonUnit: TODO"

topoSort :: [(Maybe String, Clause, Subst)] -> [T.Unit] -> [(Maybe String, Clause, Subst)]
topoSort _ _ = error "topoSort: TODO"

makeBlock :: UnitEntry -> [((Term, Term), Dir)] -> TransM ProofBlock
makeBlock ue rw = do
  (ls, _) <- foldM step (reverse baseLines, ueUnit ue) rw
  return (HaveHence (reverse ls))
  where
    baseLines = case ueDeriv ue of
      Just (HaveHence ls) -> ls
      Just (EqChain {})   -> error "makeBlock: stored derivation is EqChain"
      Nothing             ->
        [ Have (ueUnit ue)
            (fromMaybe (error "makeBlock: unnamed unit has no derivation") (ueName ue))
        ]
    step (acc, curLit) ((origL, origR), dir) = do
      nm <- ensureNamed (Eq origL origR)
      let (lhs, rhs) = if dir == LR then (origL, origR) else (origR, origL)
          cur'       = rewriteLit lhs rhs curLit
          justDir    = if dir == RL then Just RL else Nothing
      return (Hence cur' (ByRw nm justDir) : acc, cur')

rwChainTo :: Term -> Term -> TransM [(RwStep, Term)]
rwChainTo s t = do
  units <- gets tsUnits
  case findPath units s t [] of
    Nothing   -> error ("rwChainTo: no rewrite path from " ++ show s ++ " to " ++ show t)
    Just path -> mapM nameStep path
  where
    nameStep (nm, origL, origR, dir, cur') =
      return (RwStep nm (origL, origR) dir, cur')

findPath :: [UnitEntry] -> Term -> Term -> [Term]
         -> Maybe [(String, Term, Term, Dir, Term)]
findPath units = go
  where
    eqs = eqUnits units
    go cur target visited
      | cur == target      = Just []
      | cur `elem` visited = Nothing
      | otherwise          = listToMaybe $ do
          (nm, origL, origR) <- eqs
          (dir, cur')        <- let cLR    = rewrite origL origR cur
                                    cRL    = rewrite origR origL cur
                                    rlSafe = all (`elem` termVars origR) (termVars origL)
                                in  [ (LR, cLR) | cLR /= cur ]
                                ++  [ (RL, cRL) | cRL /= cur, rlSafe ]
          rest               <- maybeToList $ go cur' target (cur : visited)
          return ((nm, origL, origR, dir, cur') : rest)

ensureNamed :: Literal -> TransM String
ensureNamed lit = do
  units <- gets tsUnits
  case findUnitByLit lit units of
    Just (UnitEntry (Just name) _ _) -> return name
    Just (UnitEntry Nothing _ (Just stored)) -> do
      k <- freshLemmaNum
      let name = "lemma " ++ show k
      emitLemma name lit stored
      modifyUnit lit (UnitEntry (Just name) lit Nothing)
      return name
    Just (UnitEntry Nothing _ Nothing) ->
      error ("ensureNamed: unnamed unit has no derivation: " ++ show lit)
    Nothing ->
      error ("ensureNamed: literal not in Units: " ++ show lit)

freshLemmaNum :: TransM Int
freshLemmaNum = do
  modify $ \s -> s { tsLemmaCount = tsLemmaCount s + 1 }
  gets tsLemmaCount

emitLemma :: String -> Literal -> ProofBlock -> TransM ()
emitLemma name lit block =
  modify $ \s -> s { tsLemmas = (name, lit, block) : tsLemmas s }

modifyUnit :: Literal -> UnitEntry -> TransM ()
modifyUnit lit new =
  modify $ \s ->
    s { tsUnits = replaceFirst (tsUnits s) }
  where
    replaceFirst []     = []
    replaceFirst (u:us) = if ueUnit u == lit then new : us else u : replaceFirst us

addToUnits :: UnitEntry -> TransM ()
addToUnits ue = modify $ \s -> s { tsUnits = tsUnits s ++ [ue] }

findUnitByLit :: Literal -> [UnitEntry] -> Maybe UnitEntry
findUnitByLit lit = find (\ue -> ueUnit ue == lit)

applySubst :: Subst -> Literal -> Literal
applySubst subst (Eq l r)    = Eq  (applySubstTerm subst l) (applySubstTerm subst r)
applySubst subst (NEq l r)   = NEq (applySubstTerm subst l) (applySubstTerm subst r)
applySubst subst (Rel n ts)  = Rel n  (map (applySubstTerm subst) ts)
applySubst subst (NRel n ts) = NRel n (map (applySubstTerm subst) ts)

applySubstTerm :: Subst -> Term -> Term
applySubstTerm subst (Var x)    = fromMaybe (Var x) (lookup x subst)
applySubstTerm _ (Const c)  = Const c
applySubstTerm subst (App f ts) = App f (map (applySubstTerm subst) ts)

applySubstBlock :: Subst -> ProofBlock -> ProofBlock
applySubstBlock subst (HaveHence ls)    = HaveHence (map (applySubstLine subst) ls)
applySubstBlock subst (EqChain s steps) = EqChain (applySubstTerm subst s) (map applyStep steps)
  where
    applyStep (RwStep nm (l, r) d, cur) =
      (RwStep nm (applySubstTerm subst l, applySubstTerm subst r) d, applySubstTerm subst cur)

applySubstLine :: Subst -> ProofLine -> ProofLine
applySubstLine subst (Have  lit nm) = Have  (applySubst subst lit) nm
applySubstLine subst (And   lit nm) = And   (applySubst subst lit) nm
applySubstLine subst (Hence lit j)  = Hence (applySubst subst lit) j

-- One-sided: variables in lhs are bound by matching, then applied to rhs.
rewrite :: Term -> Term -> Term -> Term
rewrite lhs rhs t =
  case matchTerm lhs t [] of
    Just subst  -> applySubstTerm subst rhs
    Nothing -> case t of
      App f args -> App f (map (rewrite lhs rhs) args)
      _          -> t

rewriteLit :: Term -> Term -> Literal -> Literal
rewriteLit lhs rhs (Eq l r)    = Eq  (rewrite lhs rhs l) (rewrite lhs rhs r)
rewriteLit lhs rhs (NEq l r)   = NEq (rewrite lhs rhs l) (rewrite lhs rhs r)
rewriteLit lhs rhs (Rel n ts)  = Rel n  (map (rewrite lhs rhs) ts)
rewriteLit lhs rhs (NRel n ts) = NRel n (map (rewrite lhs rhs) ts)

matchTerm :: Term -> Term -> Subst -> Maybe Subst
matchTerm (Var x) t subst =
  case lookup x subst of
    Nothing -> Just ((x, t) : subst)
    Just t' -> if t' == t then Just subst else Nothing
matchTerm (Const c) (Const c') subst
  | c == c'   = Just subst
  | otherwise = Nothing
matchTerm (App f1 as1) (App f2 as2) subst
  | f1 == f2 && length as1 == length as2 = matchAll (zip as1 as2) subst
  | otherwise = Nothing
matchTerm _ _ _ = Nothing

matchLit :: Literal -> Literal -> Maybe Subst
matchLit (Rel n1 ts1) (Rel n2 ts2)
  | n1 == n2 && length ts1 == length ts2 = matchAll (zip ts1 ts2) []
  | otherwise = Nothing
matchLit (NRel n1 ts1) (NRel n2 ts2)
  | n1 == n2 && length ts1 == length ts2 = matchAll (zip ts1 ts2) []
  | otherwise = Nothing
matchLit (Eq  l1 r1) (Eq  l2 r2) = matchAll [(l1, l2), (r1, r2)] []
                                <|> matchAll [(l1, r2), (r1, l2)] []
matchLit (NEq l1 r1) (NEq l2 r2) = matchAll [(l1, l2), (r1, r2)] []
                                <|> matchAll [(l1, r2), (r1, l2)] []
matchLit _ _ = Nothing

matchAll :: [(Term, Term)] -> Subst -> Maybe Subst
matchAll pairs subst = foldl (\acc (a, b) -> acc >>= matchTerm a b) (Just subst) pairs

-- Handles both E (split_conjunct on CNF) and Vampire (negated_conjecture on FOF).
classifyAxioms :: [T.Unit]
               -> ([(String, Literal)], [(Maybe String, Clause, Subst)], Literal)
classifyAxioms units =
  let fofAxioms = [ (unitNameToString n, f)
                  | T.Unit n (T.Formula (T.Standard T.Axiom) (T.FOF f)) _ <- units ]
      negConjE  = [ cl
                  | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.CNF cl))
                              (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                  , rule == Text.pack "split_conjunct"
                  , not (isFalsum cl) ]
      negConjV  = [ f
                  | T.Unit _ (T.Formula (T.Standard T.NegatedConjecture) (T.FOF f))
                              (Just (T.Inference (T.Atom rule) _ _, _)) <- units
                  , rule == Text.pack "negated_conjecture" ]
      (unitFOFs, nonUnitFOFs) = partition (isPositiveUnitFOF . snd) fofAxioms
      axUnits    = [ (n, extractUnitFOF f)       | (n, f) <- unitFOFs    ]
      axNonUnits = [ (Just n, fofToClause f, []) | (n, f) <- nonUnitFOFs ]
      goalLit    = case (negConjE, negConjV) of
                     ([cl], []) -> negateGoal cl
                     ([], [f])  -> negateGoalFOF f
                     _          -> error "classifyAxioms: expected exactly one negated conjecture"
  in (axUnits, axNonUnits, goalLit)

isPositiveUnitFOF :: T.UnsortedFirstOrder -> Bool
isPositiveUnitFOF (T.Atomic _)                   = True
isPositiveUnitFOF (T.Quantified T.Forall _ body) = isPositiveUnitFOF body
isPositiveUnitFOF _                              = False

extractUnitFOF :: T.UnsortedFirstOrder -> Literal
extractUnitFOF (T.Atomic lit)                 = convertLit lit
extractUnitFOF (T.Quantified T.Forall _ body) = extractUnitFOF body
extractUnitFOF _                              = error "extractUnitFOF: not a positive unit"

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

negateGoalFOF :: T.UnsortedFirstOrder -> Literal
negateGoalFOF (T.Negated (T.Atomic lit)) = convertLit lit
negateGoalFOF _ = error "negateGoalFOF: unexpected negated conjecture shape"

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
