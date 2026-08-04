module Translate (translate, collectLeaves) where

import Control.Monad (foldM, forM_, when)
import Control.Monad.State
import Data.Char (toUpper)
import Data.List (find, intercalate, isInfixOf, nub, partition, sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (catMaybes, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe)
import Control.Applicative ((<|>))
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import System.Exit (ExitCode(..))
import System.Process (readProcessWithExitCode)

import Types
import Helpers
import ProofTree
  ( ProofTree, buildProofTree, leafList, innerList, demodChainsForLeaves
  , isPositiveUnitFormula, headLitOf, unitNameStr
  )

-- Top-level entry: build the proof tree, run the algorithm, return the structured proof.
translate :: Bool -> T.TSTP -> IO StructuredProof
translate _ (T.TSTP _ units) =
  case buildProofTree units of
    Nothing   -> error "translate: no refutation found"
    Just tree ->
      case collectLeaves tree units of
        Nothing                                    -> error "translate: no goal found"
        Just (initUnits, nonUnits, innerNus, goal) ->
          let unitMap        = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- units]
              demodChains    = demodChainsForLeaves (resolveSourceName unitMap) tree
              origEqPairs    = extractOrigEqAxioms units goal
              origPredPairs  = extractOrigPredUnits units goal
              origHornClauses = extractOrigSingleBodyHornClauses units
          in runAlgorithm initUnits nonUnits innerNus goal demodChains origEqPairs origPredPairs origHornClauses

-- Extract file-sourced purely-unit positive equational clauses from the TSTP file.
-- Only clauses with exactly ONE literal (a positive equality) are included —
-- Horn clauses with an equational head but body literals are excluded.
-- Used as a Twee fallback when all proof-tree leaves are circular (derived = goal).
extractOrigEqAxioms :: [T.Unit] -> [Literal] -> [(String, Literal)]
extractOrigEqAxioms allUnits goalLits = nub
  [ (unitNameStr n, convertLit lit)
  | T.Unit n decl (Just (T.File _ _, _)) <- allUnits
  , isSinglePosEq decl
  , Just lit@(T.Equality _ T.Positive _) <- [headLitOf decl]
  , convertLit lit `notElem` goalLits
  ]
  where
    isSinglePosEq (T.Formula _ (T.CNF (T.Clause ls))) =
      case toList ls of
        [(T.Positive, T.Equality _ T.Positive _)] -> True
        _                                          -> False
    isSinglePosEq _ = False

-- Extract file-sourced positive unit PREDICATE clauses (not equations).
-- Used in the circular-leaf pre-loop as electrons for Horn clause derivation.
extractOrigPredUnits :: [T.Unit] -> [Literal] -> [(String, Literal)]
extractOrigPredUnits allUnits goalLits = nub
  [ (unitNameStr n, convertLit lit)
  | T.Unit n decl (Just (T.File _ _, _)) <- allUnits
  , isSinglePosPred decl
  , Just lit@(T.Predicate (T.Defined _) _) <- [headLitOf decl]
  , convertLit lit `notElem` goalLits
  ]
  where
    isSinglePosPred (T.Formula _ (T.CNF (T.Clause ls))) =
      case toList ls of
        [(T.Positive, T.Predicate (T.Defined _) _)] -> True
        _                                             -> False
    isSinglePosPred _ = False

-- Extract file-sourced Horn clauses with exactly one RELATIONAL negative body literal
-- and one positive equality head. These can derive equational lemmas in the pre-loop.
extractOrigSingleBodyHornClauses :: [T.Unit] -> [(String, T.Declaration)]
extractOrigSingleBodyHornClauses allUnits =
  [ (unitNameStr n, decl)
  | T.Unit n decl (Just (T.File _ _, _)) <- allUnits
  , isSingleRelBodyEqHead decl
  ]
  where
    isSingleRelBodyEqHead (T.Formula _ (T.CNF (T.Clause ls))) =
      let lits = toList ls
          negLits = [l | (T.Negative, l) <- lits]
          posLits = [l | (T.Positive, l) <- lits]
      in case (negLits, posLits) of
           ([T.Predicate (T.Defined _) _], [T.Equality _ T.Positive _]) -> True
           _ -> False
    isSingleRelBodyEqHead _ = False

-- Pre-loop derivation: for each single-body Horn clause, find a matching predicate
-- electron from origPredPairs and instantiate the equational head as a new lemma.
-- Returns (lemmaName, derivedEquation, proofBlock) triples, numbered from startN+1.
deriveSingleBodyLemmas
  :: [(String, Literal)]        -- named predicate units: (axiomName, literal)
  -> [(String, T.Declaration)]  -- Horn clauses: (axiomName, declaration)
  -> Int                        -- base number (length of allAxiomList before lemmas)
  -> [(String, Literal, ProofBlock)]
deriveSingleBodyLemmas namedPredPairs namedHornDecls startN =
  snd (foldl go (0, []) namedHornDecls)
  where
    go (i, acc) (hornAxiomName, decl) =
      case decl of
        T.Formula _ (T.CNF (T.Clause ls)) ->
          let lits    = toList ls
              negLits = [l | (T.Negative, l) <- lits]
              posLits = [l | (T.Positive, l) <- lits]
          in case (negLits, posLits) of
               ([bodyLit@(T.Predicate (T.Defined _) _)], [headLit@(T.Equality _ T.Positive _)]) ->
                 let bodyConv = convertLit bodyLit
                     headConv = convertLit headLit
                     mMatch   = listToMaybe
                       [ (predAxiomName, predLit, σ)
                       | (predAxiomName, predLit) <- namedPredPairs
                       , Just σ <- [matchLit bodyConv predLit]
                       ]
                 in case mMatch of
                      Just (predAxiomName, predLit, σ) ->
                        let derivedEq = applySubst σ headConv
                            lemmaName = "lemma " ++ show (startN + i + 1)
                            blk = HaveHence [Have predLit predAxiomName
                                            , Hence derivedEq (ByAxiom hornAxiomName)]
                        in (i + 1, acc ++ [(lemmaName, derivedEq, blk)])
                      Nothing -> (i, acc)
               _ -> (i, acc)
        _ -> (i, acc)

-- Classify leaf clauses into electrons (Units) and nuclei (NonUnits).
-- Leaves are visited in ≺-increasing (left-first DFS) position order.
collectLeaves :: ProofTree -> [T.Unit]
             -> Maybe ([UnitEntry], [(String, String, T.Declaration)], [(String, String, T.Declaration)], [Literal])
collectLeaves tree units =
  case findGoal units of
    Nothing      -> Nothing
    Just rawGoal ->
      let goal    = map convertLit rawGoal
          unitMap = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n _ _) <- units ]
          -- Negated conjecture leaves keep their own declaration (not the source-resolved
          -- one) so their role is visible when assigning axiom names and building blocks.
          origDecl name leafDecl =
            case resolveSourceUnit unitMap name of
              T.Unit origN origD _
                | isNegatedConjecture leafDecl -> (name, leafDecl)
                | isNegatedConjecture origD    -> (name, leafDecl)
                | otherwise -> (unitNameStr origN, origD)
              _ -> (name, leafDecl)
          ls      = leafList tree
          -- Returns (entryName, literal) for a positive-unit leaf.
          -- When the source formula (after resolveSourceUnit) is a substitution
          -- instance or an orientation-flip of the derived formula, use the source
          -- (generic axiom).  Otherwise keep the derived formula so that matchBody
          -- can match body literals that have been specialised by rewriting.
          ownOrResolved name decl =
            case resolveSourceUnit unitMap name of
              T.Unit rN rD _ ->
                let rLit  = headLitOf rD
                    oLit  = headLitOf decl
                    isEqL (T.Equality {}) = True
                    isEqL _               = False
                in case (rLit, oLit) of
                     (Just rL, Just oL) | isEqL rL /= isEqL oL ->
                       Just (name, oL)    -- type mismatch: use own name + formula
                     (Just rL, Just oL) | isEqL oL, unitNameStr rN /= name ->
                       -- eq-to-eq chain: keep derived formula unless source can
                       -- instance (or flip-instance) to it.  This preserves
                       -- rewriting-derived equations (COL003-7 c20) while
                       -- resolving pure substitution/flip instances back to source.
                       let rL' = convertLit rL
                           oL' = convertLit oL
                           sourceFits = isJust (matchLit rL' oL')
                                     || isJust (matchLit rL' (flipLit oL'))
                       in if sourceFits
                            then fmap (\l -> (unitNameStr rN, l)) (rLit <|> oLit)
                            else Just (name, oL)
                     _ -> fmap (\l -> (unitNameStr rN, l)) (rLit <|> oLit)
              _ -> fmap (\l -> (name, l)) (headLitOf decl)
          us      = [ UnitEntry (Just entryName) (convertLit lit) Nothing (Just pos)
                    | (pos, name, decl) <- ls
                    , isPositiveUnitFormula decl
                    , Just (entryName, lit) <- [ownOrResolved name decl]
                    -- Exclude derived (plain) equations equal to the goal:
                    -- using them would produce a circular proof (axiom = goal).
                    , not (isPlainDecl decl && convertLit lit `elem` goal) ]
          nus     = [ (pos, nuName, nuDecl)
                    | (pos, name, decl) <- ls
                    , not (isPositiveUnitFormula decl)
                    , let (nuName, nuDecl) = origDecl name decl ]
          -- Intermediate PTNode derived clauses (not leaves, not proved_conjecture,
          -- not positive unit formulas).  Passed to processNonUnits but NOT to
          -- assignAxiomNames so they remain unnamed (mAxiomName = Nothing).
          innerNus = innerList tree
      in Just (us, nus, innerNus, goal)

-- TPTP → internal AST conversions

convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) [])   = Const (Text.unpack f)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = App (Text.unpack f) (map convertTerm args)
convertTerm (T.Number (T.IntegerConstant n))          = Const (show n)
convertTerm t = error ("convertTerm: unsupported term: " ++ show t)

convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit t = error ("convertLit: unsupported literal: " ++ show t)

resolveSourceName :: Map.Map String T.Unit -> String -> String
resolveSourceName unitMap name = case resolveSourceUnit unitMap name of
  T.Unit n _ _ -> unitNameStr n
  _            -> name

resolveSourceUnit :: Map.Map String T.Unit -> String -> T.Unit
resolveSourceUnit unitMap = go
  where
    -- Follow inference steps back to the original input clause,
    -- but stop at "negated_conjecture" (semantic transformation, not preprocessing).
    go name = case Map.lookup name unitMap of
      Just u@(T.Unit _ _ (Just (T.Inference (T.Atom rule) _ parents, _)))
        | rule /= Text.pack "negated_conjecture" ->
            case concatMap flatParents parents of
              (p:_) -> go p
              []    -> u
      Just u  -> u
      Nothing -> error ("resolveSourceUnit: not found: " ++ name)

    flatParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    flatParents (T.Parent (T.Inference _ _ ps) _) = concatMap flatParents ps
    flatParents _                                  = []

findGoal :: [T.Unit] -> Maybe [T.Literal]
findGoal units =
  case listToMaybe [ lits | T.Unit _ decl _ <- units
                           , isConjecture decl
                           , Just lits <- [goalLiterals decl] ] of
    Just lits -> Just lits
    Nothing   -> listToMaybe
      [ lits | T.Unit _ decl (Just (T.File _ _, _)) <- units
             , isNegatedConjecture decl
             , Just lits <- [unnegateDecl decl] ]

goalLiterals :: T.Declaration -> Maybe [T.Literal]
goalLiterals decl = case headLitOf decl of
  Just lit -> Just [lit]
  Nothing  -> case decl of
    T.Formula _ (T.FOF f) -> conjunctLits f
    _                     -> Nothing

conjunctLits :: T.UnsortedFirstOrder -> Maybe [T.Literal]
conjunctLits (T.Quantified T.Forall _ body) = conjunctLits body
conjunctLits (T.Atomic lit)                 = Just [lit]
conjunctLits (T.Connected l T.Conjunction r) =
  (++) <$> conjunctLits l <*> conjunctLits r
conjunctLits _                              = Nothing

isConjecture :: T.Declaration -> Bool
isConjecture (T.Formula (T.Standard T.Conjecture) _) = True
isConjecture _                                       = False

isNegatedConjecture :: T.Declaration -> Bool
isNegatedConjecture (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegatedConjecture _                                              = False

isPlainDecl :: T.Declaration -> Bool
isPlainDecl (T.Formula (T.Standard T.Plain) _) = True
isPlainDecl _                                  = False

unnegateDecl :: T.Declaration -> Maybe [T.Literal]
unnegateDecl (T.Formula _ (T.CNF (T.Clause lits))) = case toList lits of
  [(T.Negative, lit)]                       -> Just [lit]
  [(T.Positive, T.Equality l T.Negative r)] -> Just [T.Equality l T.Positive r]
  ls | all ((== T.Negative) . fst) ls      -> Just (map snd ls)
  _                                         -> Nothing
unnegateDecl (T.Formula _ (T.FOF f)) = fmap (:[]) (unnegateFOF f)
unnegateDecl _                       = Nothing

unnegateFOF :: T.UnsortedFirstOrder -> Maybe T.Literal
unnegateFOF (T.Quantified T.Forall _ body) = unnegateFOF body
unnegateFOF (T.Negated (T.Atomic lit))     = Just lit
unnegateFOF _                              = Nothing

-- Declaration → Clause conversion

convertDeclToClause :: T.Declaration -> Maybe Clause
convertDeclToClause (T.Formula _ (T.CNF (T.Clause lits))) =
  let ls       = toList lits
      bodyLits = [convertLit l | (T.Negative, l) <- ls]
      headLits = [convertLit l | (T.Positive, l) <- ls, not (isReservedTLit l)]
  in mkClause bodyLits headLits
convertDeclToClause (T.Formula _ (T.FOF f)) = convertFOFToClause f
convertDeclToClause _ = Nothing

-- A NEq in head position represents ¬(s=t), so it becomes a body equality.
-- Mixed NEq+non-NEq heads arise from Horn axioms like (s≠t ∨ P(x)); the NEqs
-- move to body as equalities and the single remaining literal becomes the head.
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
convertFOFToClause fof =
  case collectDisjuncts fof of
    Nothing -> Nothing
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
-- Handle implication A => B: body literals from A (negated), head from B.
-- This preserves the orientation of equality literals from original axioms.
collectDisjuncts (T.Connected body T.Implication hd) =
  (++) <$> collectImplBody body <*> collectDisjuncts hd
  where
    collectImplBody (T.Quantified T.Forall _ b) = collectImplBody b
    collectImplBody (T.Atomic lit)              = Just [(T.Negative, lit)]
    collectImplBody (T.Connected l T.Conjunction r) =
      (++) <$> collectImplBody l <*> collectImplBody r
    collectImplBody f = collectDisjuncts (T.Negated f)
collectDisjuncts _ = Nothing

-- Like collectDisjuncts but for one branch of a disjunction.
-- l≠r inside a disjunction is a negative body literal ¬(l=r), not a standalone NEq.
collectDisjunct :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
collectDisjunct (T.Atomic (T.Equality l T.Negative r)) =
  Just [(T.Negative, T.Equality l T.Positive r)]
collectDisjunct f = collectDisjuncts f

-- Assign "axiom N" names to non-negated-conjecture leaves in DFS position order.
-- Returns: (axiom list, position→axiom-name map, initUnits with names filled in).
assignAxiomNames
  :: [UnitEntry]
  -> [(String, String, T.Declaration)]
  -> ([Axiom], Map.Map String String, [UnitEntry])
assignAxiomNames initUnits nonUnits =
  let unitTags    = [(pos, Left ue)            | ue <- initUnits, Just pos <- [uePos ue]]
      nonUnitTags = [(pos, Right (name, decl)) | (pos, name, decl) <- nonUnits]
      allLeaves   = sortBy (comparing fst) (unitTags ++ nonUnitTags)
      (axiomList, posToName, _) = foldl step ([], Map.empty, Map.empty) allLeaves
      namedUnits =
        [ ue { ueName = Map.lookup pos posToName }
        | ue <- initUnits
        , Just pos <- [uePos ue]
        ]
  in (axiomList, posToName, namedUnits)
  where
    step (axAcc, posMap, origSeen) (pos, Left ue) =
      let origKey = fromMaybe ("@" ++ pos) (ueName ue)
      in case Map.lookup origKey origSeen of
           Just existingName ->
             (axAcc, Map.insert pos existingName posMap, origSeen)
           Nothing ->
             let n      = length axAcc + 1
                 axName = "axiom " ++ show n
                 ax     = AUnit axName (ueUnit ue)
             in (axAcc ++ [ax], Map.insert pos axName posMap, Map.insert origKey axName origSeen)

    step (axAcc, posMap, origSeen) (pos, Right (origName, decl)) =
      case Map.lookup origName origSeen of
        Just existingName ->
          (axAcc, Map.insert pos existingName posMap, origSeen)
        Nothing ->
          case convertDeclToClause decl of
            Just cls@(Clause _ (Just _)) ->
              let n      = length axAcc + 1
                  axName = "axiom " ++ show n
                  ax     = ANonUnit axName cls
              in (axAcc ++ [ax], Map.insert pos axName posMap, Map.insert origName axName origSeen)
            _ ->
              (axAcc, posMap, origSeen)

type AlgM a = StateT AlgState IO a

addUnit :: UnitEntry -> AlgM ()
addUnit ue = modify $ \s -> s { stUnits = stUnits s ++ [ue] }

nextCounter :: AlgM Int
nextCounter = do
  k <- gets stCounter
  modify $ \s -> s { stCounter = k + 1 }
  return k

-- ELECTRONS(p, Units): all units with position q ≺ p.
-- Unnamed (ueName = Nothing) units are tried before named ones so that
-- locally-derived anonymous facts are preferred over remote axioms.
getElectrons :: String -> AlgM [UnitEntry]
getElectrons p = gets (\s ->
  let available = filter (\ue -> case uePos ue of { Just q -> q < p; Nothing -> False }) (stUnits s)
      hasHenceStep blk = case blk of
                           HaveHence ls -> any (\l -> case l of Hence {} -> True; _ -> False) ls
                           _            -> False
      isComplete ue = maybe False hasHenceStep (ueProof ue)
      -- Complete unnamed blocks (with Hence step) come before incomplete ones.
      -- This ensures leaves' well-formed derived results are preferred over
      -- inner non-units' partial blocks when matchBodyAll picks its first candidate.
      completeUnnamed   = filter (\ue -> isNothing (ueName ue) &&  isComplete ue) available
      incompleteUnnamed = filter (\ue -> isNothing (ueName ue) && not (isComplete ue)) available
      named             = filter (isJust . ueName) available
  in completeUnnamed ++ incompleteUnnamed ++ named)

-- ENSURE_NAMED: return the name of a unit, promoting it to a lemma if unnamed.
-- ENSURE_NAMED(lit, buildBlk): return the name of `lit` in Units.
-- Works for any literal (equational or relational).
-- If unnamed but a proof is stored, promotes it to a lemma.
-- If unnamed with no stored proof, or not in Units at all, runs `buildBlk`
-- to construct the proof block, then promotes and (if missing) registers
-- the unit so future lookups find the assigned name.
ensureNamed :: Literal -> AlgM ProofBlock -> AlgM String
ensureNamed lit buildBlk = do
  units <- gets stUnits
  case find (\u -> ueUnit u == lit) units of
    Just ue ->
      case ueName ue of
        Just name -> return name
        Nothing   ->
          case ueProof ue of
            Just blk -> promoteToLemma lit blk
            Nothing  -> buildBlk >>= promoteToLemma lit
    Nothing -> do
      blk  <- buildBlk
      name <- promoteToLemma lit blk
      addUnit (UnitEntry (Just name) lit Nothing Nothing)
      return name

promoteToLemma :: Literal -> ProofBlock -> AlgM String
promoteToLemma lit blk = do
  k <- nextCounter
  let name = "lemma " ++ show k
  modify $ \s -> s
    { stLemmas = stLemmas s ++ [(name, lit, blk)]
    , stUnits  = map (promote name) (stUnits s)
    }
  return name
  where
    promote name u
      | ueUnit u == lit && isNothing (ueName u) =
          u { ueName = Just name, ueProof = Nothing }
      | otherwise = u

tweeBin :: FilePath
tweeBin = "bin/twee"

-- Format a Term as a TPTP term string (variables uppercase, functions lowercase).
toTptpTerm :: Term -> String
toTptpTerm (Var [])   = []
toTptpTerm (Var (c:cs)) = toUpper c : cs
toTptpTerm (Const f)  = f
toTptpTerm (App f ts) = f ++ "(" ++ intercalate "," (map toTptpTerm ts) ++ ")"

-- Wrap a universally quantified TPTP fof formula around an equational body.
toTptpFof :: String -> String -> Term -> Term -> String
toTptpFof name role l r =
  let vs   = nub (termVars l ++ termVars r)
      body = toTptpTerm l ++ " = " ++ toTptpTerm r
      capVar []     = []
      capVar (c:cs) = toUpper c : cs
      qbody = if null vs then body
              else "![" ++ intercalate "," (map capVar vs) ++ "]: " ++ body
  in "fof(" ++ name ++ ", " ++ role ++ ", " ++ qbody ++ ")."

-- "axiom 1" → "axiom_1", "lemma 3" → "lemma_3"
sanitizeId :: String -> String
sanitizeId = map (\c -> if c == ' ' then '_' else c)

isEqLit :: Literal -> Bool
isEqLit (Eq _ _) = True
isEqLit _        = False

dirFlag :: Dir -> Maybe Dir
dirFlag LR = Nothing
dirFlag RL = Just RL

findEqByName :: String -> [UnitEntry] -> Maybe (Term, Term)
findEqByName name units = listToMaybe
  [ (l, r) | ue <- units, ueName ue == Just name, Eq l r <- [ueUnit ue] ]

applyRwLine :: ProofBlock -> (RwStep, Literal) -> ProofBlock
applyRwLine b (rw, c) = appendLine b (Hence c (ByRw (rwName rw) (dirFlag (rwDir rw))))

-- Parse "= { by axiom N (name) }" lines and return the name tokens in order.
parseTweeStepNames :: String -> [String]
parseTweeStepNames output =
  let ls         = lines output
      inBlock    = dropWhile (not . ("% SZS output start Proof" `isInfixOf`)) ls
      proofLines = takeWhile (not . ("% SZS output end Proof"   `isInfixOf`)) (drop 1 inBlock)
      stepLines  = filter ("{ by axiom" `isInfixOf`) proofLines
  in mapMaybe extractName stepLines
  where
    extractName line =
      case dropWhile (/= '(') line of
        []      -> Nothing
        (_:rest) -> let nm = takeWhile (/= ')') rest
                    in if null nm then Nothing else Just nm

-- Replay a list of sanitized-TPTP step names from term l.
-- Returns (UnitEntry, Dir, resultTerm) — the caller handles naming.
replayTweeChain :: Map.Map String UnitEntry -> [String] -> Term -> [(UnitEntry, Dir, Term)]
replayTweeChain idToUe stepNames startTerm = go startTerm stepNames []
  where
    go _ [] acc = reverse acc
    go cur (tptpId:rest) acc =
      case Map.lookup tptpId idToUe of
        Nothing -> go cur rest acc
        Just ue ->
          case ueUnit ue of
            Eq a b ->
              case listToMaybe (rewriteTermAll cur (a, b) LR) of
                Just cur' -> go cur' rest ((ue, LR, cur') : acc)
                Nothing   ->
                  case listToMaybe (rewriteTermAll cur (a, b) RL) of
                    Just cur' -> go cur' rest ((ue, RL, cur') : acc)
                    Nothing   -> go cur rest acc
            _ -> go cur rest acc

-- Call Twee to prove Eq l r using all equational units (named and unnamed).
-- Returns (startTerm, chain) — startTerm may be l or r depending on how Twee
-- oriented the proof; caller uses startTerm as the EqChain start.
callTwee :: [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTwee units (Eq l r) = do
  let eqUnits   = [(i, ue) | (i, ue) <- zip [(0::Int)..] units, isEqLit (ueUnit ue)]
      mkId i ue = fromMaybe ("anon_" ++ show i) (sanitizeId <$> ueName ue)
      idToUe    = Map.fromList [(mkId i ue, ue) | (i, ue) <- eqUnits]
      axioms    = [ toTptpFof (mkId i ue) "axiom" a b
                  | (i, ue) <- eqUnits, Eq a b <- [ueUnit ue] ]
      conj      = toTptpFof "goal" "conjecture" l r
      input     = unlines (axioms ++ [conj])
      tmpFile   = "/tmp/taelja_twee_input.p"
  writeFile tmpFile input
  (ec, out, _) <- readProcessWithExitCode tweeBin
                    ["--tstp", "--no-colour", "--max-time", "10", tmpFile] ""
  case ec of
    ExitSuccess -> do
      let stepNames = parseTweeStepNames out
          chainL    = replayTweeChain idToUe stepNames l
          chainR    = replayTweeChain idToUe stepNames r
          chainEnd  = fmap (\(_, _, t) -> t) . listToMaybe . reverse
          result
            | not (null chainL) && chainEnd chainL == Just r = Just (l, chainL)
            | not (null chainR) && chainEnd chainR == Just l = Just (r, chainR)
            | otherwise                                       = Nothing
      return result
    _ -> return Nothing
callTwee _ _ = return Nothing

-- MATCH: for each body literal find an electron and substitutions (σ0, σi) such
-- Like matchBody but returns ALL consistent matchings (no IO side effects;
-- splitChainHeuristic is omitted).  Used for relational-head named clauses to
-- find the matching that directly proves the current goal even when it is not
-- the first DFS result.
matchBodyAll :: String -> [Literal] -> [UnitEntry] -> Map.Map String [(String, Dir)] -> Set.Set String -> Subst
             -> AlgM [(Subst, [(UnitEntry, Subst, Literal)])]
matchBodyAll _pos bodyLits electrons demodChains nvars initSigma = go bodyLits initSigma []
  where
    go [] σ0 acc = return [(σ0, reverse acc)]
    go (li:rest) σ0 acc = do
      let li' = applySubst σ0 li
      candidates <- allCandidates li' σ0
      fmap concat $ mapM (\(ue,σi,σ0') -> go rest σ0' ((ue,σi,applySubst σ0' li):acc)) candidates

    allCandidates li' σ0 = do
      units <- gets stUnits
      let chain ue = maybe [] (\p -> fromMaybe [] (Map.lookup p demodChains)) (uePos ue)
          kstar ue = fst (rwChainFromDemod (ueUnit ue) (chain ue) units)
          tryFresh ue klit = do
            k <- nextCounter
            let (kFresh, invMap) = freshenLit k klit
                -- After matching, de-freshen σ0' and σiOrig by substituting
                -- fresh vars back to the electron's original variable names.
                -- This prevents synthetic vars from polluting subsequent body literals.
                origMap  = [(fv, Var ov) | (fv, ov) <- invMap]
                deFresh s = [(v, applySubstTerm origMap t) | (v, t) <- s]
            return $ case tryMatchN nvars li' kFresh σ0 of
              Nothing          -> Nothing
              Just (σiF, σ0') ->
                let σiOrig = deFresh (convertSigma invMap σiF)
                in Just (ue, σiOrig, deFresh σ0')
      directResults <- mapM (\ue -> tryFresh ue (ueUnit ue)) electrons
      let directHits      = catMaybes directResults
          directElecUnits = map (\(u,_,_) -> ueUnit u) directHits
      demodResults <- mapM (\ue ->
        if ueUnit ue `elem` directElecUnits
          then return Nothing
          else tryFresh ue (kstar ue)) electrons
      let demodHits = catMaybes demodResults
      return (directHits ++ demodHits)

-- that K_i[σ_i] rewrites to L_i[σ0].  Returns Nothing on failure.
matchBody :: String -> [Literal] -> [UnitEntry] -> Map.Map String [(String, Dir)] -> Subst -> AlgM (Maybe (Subst, [(UnitEntry, Subst, Literal)]))
matchBody pos bodyLits electrons demodChains initSigma = go bodyLits initSigma []
  where
    -- DFS with backtracking: collect all direct candidates for each body literal,
    -- try them in order, backtracking on failure.  splitChainHeuristic (with IO
    -- side effects) is only invoked when ALL direct candidates have been exhausted.
    go [] σ0 acc = return $ Just (σ0, reverse acc)
    go (li:rest) σ0 acc = do
      units <- gets stUnits
      let li'        = applySubst σ0 li
          candidates = directCandidates li' σ0 units
      result <- tryAll candidates
      case result of
        Just _  -> return result
        Nothing -> do
          mElec <- splitChainHeuristic li' σ0
          case mElec of
            Nothing             -> return Nothing
            Just (ue, σi, σ0') -> go rest σ0' ((ue, σi, applySubst σ0' li) : acc)

      where
        tryAll [] = return Nothing
        tryAll ((ue, σi, σ0'):more) = do
          result <- go rest σ0' ((ue, σi, applySubst σ0' li) : acc)
          case result of
            Just _  -> return result
            Nothing -> tryAll more

    -- Collect every electron that matches li' under the current σ0 (no side effects).
    directCandidates li' σ0 units =
      let chain ue        = maybe [] (\p -> fromMaybe [] (Map.lookup p demodChains)) (uePos ue)
          kstar ue        = fst (rwChainFromDemod (ueUnit ue) (chain ue) units)
          tryM ue k       = case tryMatch li' k σ0 of
                              Just (σi, σ0') -> Just (ue, σi, σ0')
                              Nothing        -> Nothing
          directHits      = [res | ue <- electrons, Just res <- [tryM ue (ueUnit ue)]]
          demodHits       = [res | ue <- electrons
                                 , Just res <- [tryM ue (kstar ue)]
                                 , ueUnit ue `notElem` map (\(u,_,_) -> ueUnit u) directHits]
          candidateElecs  = case li' of
                              Rel _ _ -> electrons
                              _       -> filter (isNothing . ueName) electrons
          rwStepHits      =
            [ (ue, σi, σ0')
            | eqUe <- units
            , Eq ea eb <- [ueUnit eqUe]
            , dir      <- [LR, RL]
            , Just li'' <- [rewriteLit li' (ea, eb) dir]
            , ue <- candidateElecs
            , Just (σi, σ0') <- [tryMatch li'' (ueUnit ue) σ0]
            ]
      in directHits ++ demodHits ++ rwStepHits

    splitChainHeuristic (Eq l r) σ0 = do
      units  <- gets stUnits
      mChain <- liftIO (callTwee units (Eq l r))
      case mChain of
        Nothing           -> return Nothing
        Just (_, [])      -> return Nothing
        Just (start, chain) -> do
          steps <- mapM promoteStep chain
          let proof = EqChain start steps
              ue    = UnitEntry Nothing (Eq l r) (Just proof) (Just pos)
          addUnit ue
          return $ Just (ue, [], σ0)
      where
        promoteStep (stepUe, dir, cur) = do
          nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
          case ueUnit stepUe of
            Eq a b -> return (RwStep nm (a, b) dir, cur)
            _      -> error "splitChainHeuristic: non-eq unit in Twee chain"
    splitChainHeuristic _ _ = return Nothing

-- One-way matching: body literal li against electron ki.
-- 1. Try li as pattern against ki → extends σ0 with nucleus-var bindings.
-- 2. Try ki as pattern against li → gives σi (electron-var bindings); σ0 unchanged.
-- Both directions also try flipped equality (Eq is symmetric).
-- Intentionally no unification — binding nucleus and electron vars simultaneously
-- causes naming-collision bugs.
tryMatch :: Literal -> Literal -> Subst -> Maybe (Subst, Subst)
tryMatch li ki σ0 =
  tryAsPattern li ki
  <|> tryAsPattern (flipEq li) ki
  <|> tryKiPattern ki
  <|> tryKiPattern (flipEq ki)
  <|> tryKiPattern ki `againstFlip` li
  <|> tryBothSides li ki
  <|> tryBothSides (flipEq li) ki
  where
    tryAsPattern li_form k = case matchLit li_form k of
      Just σ_new -> case extendSubst σ0 σ_new of
        Just σ0' -> Just ([], σ0')
        Nothing  -> Nothing
      Nothing -> Nothing
    tryKiPattern k = case matchLit k li of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    againstFlip m li_form = m <|> case matchLit ki (flipEq li_form) of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    -- Bidirectional: nucleus vars (in li_form) → σ0, electron vars (in ki) → σi.
    -- Compose σi into σ0' before the consistency check to handle shared variable names.
    tryBothSides li_form k = case matchBothLit li_form k σ0 [] of
      Just (σ0', σi) ->
        let σ0composed = [(x, applySubstTerm σi t) | (x, t) <- σ0']
        in if applySubst σ0composed li_form == applySubst σi k
           then Just (σi, σ0composed)
           else Nothing
      _ -> Nothing
    flipEq (Eq l r) = Eq r l
    flipEq x        = x

-- Freshen all variables in a literal with unique suffix "_v{k}".
-- Returns (freshened_literal, inv_map) where inv_map :: [(fresh_var, orig_var)].
freshenLit :: Int -> Literal -> (Literal, [(String, String)])
freshenLit k lit =
  let vars     = nub (litVars lit)
      freshMap = [(v, Var (v ++ "_v" ++ show k)) | v <- vars]
      invMap   = [(v ++ "_v" ++ show k, v) | v <- vars]
  in (applySubst freshMap lit, invMap)

-- Convert σi from fresh-variable names back to original variable names.
convertSigma :: [(String, String)] -> Subst -> Subst
convertSigma invMap σiF =
  [(orig, applySubstTerm σiF (Var fresh)) | (fresh, orig) <- invMap]

-- Nucleus-variable-aware tryMatch.
-- nvars: the set of variables belonging to the clause being processed.
-- In tryAsPattern, bindings for non-nucleus vars (leaked electron vars) are rejected.
-- In tryBothSides, matchBothLitN is used so non-nucleus vars on the left are ground-like.
-- When nvars is empty the behaviour is identical to tryMatch (accept all bindings).
tryMatchN :: Set.Set String -> Literal -> Literal -> Subst -> Maybe (Subst, Subst)
tryMatchN nvars li ki σ0 =
  tryAsPatternN li ki
  <|> tryAsPatternN (flipEq li) ki
  <|> tryKiPattern ki
  <|> tryKiPattern (flipEq ki)
  <|> tryKiPattern ki `againstFlip` li
  <|> tryBothSidesN li ki
  <|> tryBothSidesN (flipEq li) ki
  where
    tryAsPatternN li_form k = case matchLit li_form k of
      Just σ_new
        | Set.null nvars || all (\(x,_) -> Set.member x nvars) σ_new ->
            case extendSubst σ0 σ_new of
              Just σ0' -> Just ([], σ0')
              Nothing  -> Nothing
      _ -> Nothing
    tryKiPattern k = case matchLit k li of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    againstFlip m li_form = m <|> case matchLit ki (flipEq li_form) of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    tryBothSidesN li_form k = case matchBothLitN nvars li_form k σ0 [] of
      Just (σ0', σi) ->
        let σ0composed = [(x, applySubstTerm σi t) | (x, t) <- σ0']
        in if applySubst σ0composed li_form == applySubst σi k
           then Just (σi, σ0composed)
           else Nothing
      _ -> Nothing
    flipEq (Eq l r) = Eq r l
    flipEq x        = x

-- RW_CHAIN_TO (literal, with side effects): greedy best-effort rewriting toward t.
-- Returns (cur, steps) where cur may not equal t if no exact path exists;
-- the caller uses matchLit to close the remaining gap (Lemma 0.6).
rwChainToLit :: Literal -> Literal -> [UnitEntry] -> AlgM (Literal, [(RwStep, Literal)])
rwChainToLit s t units
  | s == t         = return (s, [])
  | flipLit s == t = return (t, [])
  | otherwise      = go s (Set.singleton s) []
  where
    go cur seen acc = case findStep cur seen of
      Nothing -> return (cur, reverse acc)
      Just (ue, eq, dir, cur')
        | isTarget cur' -> do
            name <- ensureNamed (ueUnit ue) (error "rwChainToLit: eq unit has no proof")
            return (t, reverse ((RwStep name eq dir, cur') : acc))
        | otherwise -> do
            name <- ensureNamed (ueUnit ue) (error "rwChainToLit: eq unit has no proof")
            go cur' (Set.insert cur' seen) ((RwStep name eq dir, cur') : acc)
    isTarget c = c == t || flipLit c == t
    findStep cur seen = listToMaybe (sortCandidates
      [ (ue, (l, r), dir, cur')
      | ue          <- units
      , Eq l r      <- [ueUnit ue]
      , (dir, cur') <- litSteps l r cur
      , Set.notMember cur' seen ])
      where
        curSize = litSize cur
        sortCandidates cs =
          filter (\(_, _, _, c) -> isTarget c) cs ++
          sortBy (comparing (\(_, _, _, c) -> litSize c))
                 (filter (\(_, _, _, c) -> litSize c <= curSize) cs) ++
          sortBy (comparing (\(_, _, _, c) -> litSize c))
                 (filter (\(_, _, _, c) -> litSize c >  curSize) cs)
    litSteps l r cur =
      [ (LR, c) | Just c <- [rewriteLit cur (l, r) LR] ] ++
      [ (RL, c) | Just c <- [rewriteLit cur (l, r) RL] ]

-- RW_CHAIN_TO (term, with side effects): greedy with step limit.
rwChainToTerm :: Term -> Term -> [UnitEntry] -> AlgM (Term, [(RwStep, Term)])
rwChainToTerm s t units
  | s == t    = return (s, [])
  | otherwise = go s (Set.singleton s) [] (0 :: Int)
  where
    maxSteps = 30 :: Int
    go cur seen acc n
      | cur == t      = return (cur, reverse acc)
      | n >= maxSteps = return (cur, reverse acc)
      | otherwise     = case findStep cur seen of
          Nothing -> return (cur, reverse acc)
          Just (ue, eq, dir, cur') -> do
            name <- ensureNamed (ueUnit ue) (error "rwChainToTerm: eq unit has no proof")
            go cur' (Set.insert cur' seen) ((RwStep name eq dir, cur') : acc) (n + 1)
    findStep cur seen = listToMaybe (sortCandidates
      [ (ue, (l, r), dir, cur')
      | ue          <- units
      , Eq l r      <- [ueUnit ue]
      , (dir, cur') <- termSteps l r cur
      , Set.notMember cur' seen ])
      where
        curSize = termSize cur
        sortCandidates cs =
          filter (\(_, _, _, c) -> c == t) cs ++
          sortBy (comparing (\(_, _, _, c) -> termSize c))
                 (filter (\(_, _, _, c) -> termSize c <= curSize) cs) ++
          sortBy (comparing (\(_, _, _, c) -> termSize c))
                 (filter (\(_, _, _, c) -> termSize c >  curSize) cs)
    termSteps l r cur =
      [ (LR, c) | c <- rewriteTermAll cur (l, r) LR ] ++
      [ (RL, c) | c <- rewriteTermAll cur (l, r) RL ]

-- RW_CHAIN_TO (proof-tree guided): replay the demodulation chain for an electron.
-- demodChain is outermost-first; steps are replayed in forward order (innermost first)
-- using the SAME direction as the original demodulation.
-- Steps whose equation is not in Units (derived equations) are silently skipped.
-- Steps that don't match cur (they rewrote a different literal) are also skipped.
rwChainFromDemod
  :: Literal              -- Ki·σi (electron after substitution)
  -> [(String, Dir)]      -- demodulation chain for the electron, outermost first
  -> [UnitEntry]          -- to look up equation literals by resolved name
  -> (Literal, [(RwStep, Literal)])
rwChainFromDemod s demodChain units = go s [] (reverse demodChain)
  where
    go cur acc [] = (cur, reverse acc)
    go cur acc ((name, dir) : rest) =
      case findEqByName name units of
        Nothing     -> go cur acc rest  -- derived equation not in initUnits, skip
        Just (l, r) ->
          case rewriteLit cur (l, r) dir of
            Nothing   -> go cur acc rest  -- step rewrote a different literal, skip
            Just cur' -> go cur' ((RwStep name (l, r) dir, cur') : acc) rest

-- D&S SplitChain: reconstruct an equational proof of l=r from the demodulation
-- chain at p_{G₁}.  The chain records how l≠r was reduced to t≠t; replaying it
-- in forward proof order (innermost first) and splitting each step by which side
-- of l≠r it rewrites gives leftSteps (l→…→t) and rightSteps (r→…→t).
-- Reversing and flipping rightSteps yields t→…→r, completing l=…=t=…=r.
-- Steps whose equation is not in Units are silently skipped.
splitChain :: Term -> Term -> [(String, Dir)] -> [UnitEntry] -> [(RwStep, Term)]
splitChain l r chain units =
    if curL == curR then reverse leftSteps ++ reverseRight (reverse rightSteps) else []
  where
    (leftSteps, rightSteps, curL, curR) = foldl step ([], [], l, r) (reverse chain)

    step (ls, rs, accL, accR) (name, dir) =
      case findEqByName name units of
        Nothing     -> (ls, rs, accL, accR)  -- derived equation not in initUnits, skip
        Just (a, b) ->
          case rewriteTerm accL (a, b) dir of
            Just accL' -> ((RwStep name (a, b) dir, accL') : ls, rs, accL', accR)
            Nothing    ->
              case rewriteTerm accR (a, b) dir of
                Just accR' -> (ls, (RwStep name (a, b) dir, accR') : rs, accL, accR')
                Nothing    -> (ls, rs, accL, accR)

    reverseRight [] = []
    reverseRight rs =
      let prevTerms = r : map snd (init rs)
          flipped   = [ (RwStep nm eq (flipDir d), prev)
                      | ((RwStep nm eq d, _), prev) <- zip rs prevTerms ]
      in reverse flipped

    flipDir LR = RL
    flipDir RL = LR

-- MAKE_BLOCK: build the proof block for an electron K with substitution σ and
-- For a 2-body right-child axiom and a single-body inner non-unit, infer the
-- literal that the left child (pos++"0") must have provided.
-- The inner non-unit consumed one body literal from the right axiom; the left
-- child consumed the other.  We recover it by matching the known remaining
-- body literal and the derived head against the axiom's body[0/1] and head.
inferLeftElectronLit :: Literal -> Literal -> Clause -> Maybe Literal
inferLeftElectronLit singleBody headLit (Clause [rb0, rb1] (Just rHead)) =
  tryConsumed rb0 rb1 <|> tryConsumed rb1 rb0
  where
    tryConsumed consumed remaining = do
      σ1 <- matchLit remaining singleBody
      σ2 <- matchLit (applySubst σ1 rHead) headLit
      return $ applySubst σ2 (applySubst σ1 consumed)
inferLeftElectronLit _ _ _ = Nothing

-- Prepend the left child's electron to an incomplete electron block and close
-- it with a Hence step.  The existing first Have line is demoted to And so
-- the left child becomes the canonical first electron.
insertLeftElectron :: Literal -> String -> ProofBlock -> String -> Literal -> ProofBlock
insertLeftElectron leftLit laxName electronBlk raxName headLit =
  case electronBlk of
    HaveHence (Have matchedLit matchedName : rest) ->
      HaveHence $
           Have leftLit laxName
         : And  matchedLit matchedName
         : rest
        ++ [Hence headLit (ByAxiom raxName)]
    _ -> electronBlk  -- unexpected shape; leave untouched

-- a list of rewrite steps leading from K[σ] to the target body literal.
makeBlock :: UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
makeBlock electronUe σi rwSteps = do
  units <- gets stUnits
  b     <- buildBase units
  return $ foldl applyRwLine b rwSteps
  where
    lit = ueUnit electronUe

    buildBase units =
      let allUnnamed  = filter (\u -> ueUnit u == lit && isNothing (ueName u)) units
          hasHence (HaveHence ls) = any (\l -> case l of Hence {} -> True; _ -> False) ls
          hasHence _              = False
          -- Prefer a complete block (one with a Hence step) over an incomplete one.
          -- This matters when an inner non-unit stores an incomplete block first
          -- and a leaf later derives the same literal with a complete block.
          mBest = find (\u -> maybe False hasHence (ueProof u)) allUnnamed
              <|> listToMaybe allUnnamed
      in case mBest of
        Just unnamed ->
          case ueProof unnamed of
            Just stored
              | isEqChain stored -> do
                  -- EqChain cannot be inlined inside a HaveHence block.
                  name <- ensureNamed lit (error "makeBlock: EqChain unit has no stored proof")
                  return $ HaveHence [Have (applySubst σi lit) name]
              | not (hasHence stored) -> do
                  -- Incomplete block (no Hence step): the stored block proves the
                  -- body literal, not the head literal `lit`.  Promote to a named
                  -- lemma so the caller's Have line cites `lit` correctly.
                  name <- ensureNamed lit (return stored)
                  return $ HaveHence [Have (applySubst σi lit) name]
              | otherwise ->
                  return $ applySubstBlock σi stored
            _ -> namedCase units
        Nothing -> namedCase units

    namedCase units =
      case find (\u -> ueUnit u == lit) units of
        Just u  ->
          let name = fromMaybe (error ("makeBlock: unnamed unit: " ++ show lit)) (ueName u)
          in return $ HaveHence [Have (applySubst σi lit) name]
        Nothing -> error ("makeBlock: electron not found in Units: " ++ show lit)

processNonUnit
  :: String
  -> Maybe String  -- this node's axiom name (Nothing for inner nodes)
  -> Maybe String  -- left child's axiom name  (pos++"0"), if a named leaf
  -> Maybe String  -- right child's axiom name (pos++"1"), if a named leaf
  -> Maybe Clause  -- right child's clause     (pos++"1"), if present in allNus
  -> Clause
  -> Literal       -- goal literal
  -> Map.Map String [(String, Dir)]  -- demodulation chains (keyed by leaf position)
  -> AlgM Bool     -- True when a goal was emitted
processNonUnit pos mAxiomName mLeftAxiomName mRightAxiomName mRightAxiomClause (Clause bodyLits mHead) goalLit demodChains = do
  elecs <- getElectrons pos
  let nvars = Set.fromList (concatMap litVars bodyLits ++ maybe [] litVars mHead)
  case (mAxiomName, mHead, bodyLits) of
    -- Multi-body named relational clause: collect all matches (with electron freshening),
    -- emit the first that directly proves the goal; otherwise add the first derived unit.
    (Just axName, Just l0, _:_:_) | not (isEqLit l0) -> do
      allMatches <- matchBodyAll pos bodyLits elecs demodChains nvars []
      let l0σ0Of (σ0, _) = applySubst σ0 l0
          findGoalMatch [] = Nothing
          findGoalMatch (m@(σ0,matched):rest) =
            case matchLit (l0σ0Of m) goalLit <|> matchLit (flipLit (l0σ0Of m)) goalLit of
              Just ρ0 -> Just (σ0, matched, ρ0)
              Nothing -> findGoalMatch rest
          mGoal = findGoalMatch allMatches
      case mGoal of
        Just (σ0, matched, ρ0) -> do
          blk <- buildElectronBlock σ0 matched demodChains
          let l0σ0 = applySubst σ0 l0
              blk1 = appendLine blk (Hence l0σ0 (ByAxiom axName))
          emitGoalProof goalLit (applySubstBlock ρ0 blk1) >> return True
        Nothing ->
          case allMatches of
            [] -> return False
            ((σ0,matched):_) -> do
              blk <- buildElectronBlock σ0 matched demodChains
              let l0σ0 = applySubst σ0 l0
                  blk1 = appendLine blk (Hence l0σ0 (ByAxiom axName))
              addUnit (UnitEntry Nothing l0σ0 (Just blk1) (Just pos)) >> return False

    -- Multi-body named equational-head clause (e.g. total_function2): collect all matches,
    -- filter trivial heads (LHS=RHS), emit the first non-trivial that proves the goal.
    (Just axName, Just l0, _:_:_) | isEqLit l0 -> do
      allMatches <- matchBodyAll pos bodyLits elecs demodChains nvars []
      let isTrivialEq (Eq l r) = l == r
          isTrivialEq _         = False
          l0σ0Of (σ0, _) = applySubst σ0 l0
          nonTrivial = filter (\m -> not (isTrivialEq (l0σ0Of m))) allMatches
          findGoalMatch [] = Nothing
          findGoalMatch (m@(σ0,matched):rest) =
            let l0σ0 = l0σ0Of m
            in case matchLit l0σ0 goalLit <|> matchLit (flipLit l0σ0) goalLit of
                 Just ρ0 -> Just (σ0, matched, ρ0, l0σ0)
                 Nothing -> findGoalMatch rest
          mGoal = findGoalMatch nonTrivial
      case mGoal of
        Just (σ0, matched, ρ0, l0σ0) -> do
          blk <- buildElectronBlock σ0 matched demodChains
          let headToEmit
                | Just _ <- matchLit l0σ0 goalLit = l0σ0
                | otherwise                         = flipLit l0σ0
              blk1 = appendLine blk (Hence headToEmit (ByAxiom axName))
          emitGoalProof goalLit (applySubstBlock ρ0 blk1) >> return True
        Nothing ->
          case nonTrivial of
            [] -> return False
            ((σ0,matched):_) -> do
              blk <- buildElectronBlock σ0 matched demodChains
              let l0σ0 = l0σ0Of (σ0, matched)
                  blk1 = appendLine blk (Hence l0σ0 (ByAxiom axName))
              addUnit (UnitEntry Nothing l0σ0 (Just blk1) (Just pos)) >> return False

    (Just axName, Just l0, [singleBody]) | not (isEqLit l0) && not (isEqLit singleBody) ->
      foldM (\goalDone ue -> do
        if goalDone then return True
        else do
          mMatch <- matchBody pos bodyLits [ue] demodChains []
          case mMatch of
            Nothing -> return False
            Just (σ0, matched) -> do
              blk <- buildElectronBlock σ0 matched demodChains
              let l0σ0 = applySubst σ0 l0
                  blk1 = appendLine blk (Hence l0σ0 (ByAxiom axName))
              case matchLit l0σ0 goalLit <|> matchLit (flipLit l0σ0) goalLit of
                Just ρ0 ->
                  emitGoalProof goalLit (applySubstBlock ρ0 blk1) >> return True
                Nothing -> do
                  units' <- gets stUnits
                  (cur, rwSteps) <- rwChainToLit l0σ0 goalLit units'
                  let blk2 = foldl applyRwLine blk1 rwSteps
                  if cur == goalLit
                    then emitGoalProof goalLit blk2 >> return True
                    else do
                      let mρ0 = matchLit cur goalLit <|> matchLit (flipLit cur) goalLit
                      case mρ0 of
                        Just ρ0 ->
                          emitGoalProof goalLit (applySubstBlock ρ0 blk2) >> return True
                        Nothing -> do
                          addUnit (UnitEntry Nothing l0σ0 (Just blk1) (Just pos))
                          return False)
        False elecs
    _ -> do
      mMatch <- matchBody pos bodyLits elecs demodChains []
      case mMatch of
        Nothing -> return False
        Just (σ0, matched) ->
          case mHead of
            Nothing ->
              -- L0 = ⊥: electrons directly prove the goal.
              -- If the single electron has an unnamed EqChain proof, emit it directly
              -- rather than wrapping it in "have X by lemma N".
              case matched of
                [] -> return False
                [(elecUe, σi, _)]
                  | isNothing (ueName elecUe)
                  , Just chain@(EqChain {}) <- ueProof elecUe ->
                      emitGoalProof goalLit (applySubstBlock σi chain) >> return True
                _ -> do
                  blk <- buildElectronBlock σ0 matched demodChains
                  emitGoalProof goalLit blk >> return True
            Just l0 -> do
              blk <- buildElectronBlock σ0 matched demodChains
              let l0σ0 = applySubst σ0 l0
                  -- Unnamed derived clauses (inner nodes) have no axiom citation;
                  -- skip the Hence step so the proof block stays well-formed.
                  blk1 = case mAxiomName of
                           Just axName -> appendLine blk (Hence l0σ0 (ByAxiom axName))
                           Nothing     -> blk
              case mAxiomName of
                -- Unnamed inner node: only enrich stUnits; never emit directly.
                -- The named leaf axiom that follows will cite the derived unit and
                -- produce a well-formed proof with a Hence step.
                -- Exception: if the derived unit IS the goal and all matched electrons
                -- are named leaf axioms, use the right child's axiom name (if any)
                -- to emit a goal proof directly — this handles inner non-units whose
                -- other electron was already discharged in a prior resolution step.
                Nothing
                  | l0σ0 == goalLit ->
                      let allNamed = all (\(ue,_,_) -> isJust (ueName ue)) matched
                      in case mRightAxiomName of
                           Just axName | allNamed ->
                             let proof = appendLine blk (Hence l0σ0 (ByAxiom axName))
                             -- Defer: a named multi-body leaf axiom may still fire first
                             -- and produce a more complete proof.  Only emit this candidate
                             -- after the main loop if the goal remains unproven.
                             in modify (\s -> s { stDeferredGoalProof =
                                   stDeferredGoalProof s <|> Just (goalLit, proof) })
                                >> return False
                           _ -> return False
                  | otherwise ->
                      case (mLeftAxiomName, mRightAxiomName, mRightAxiomClause, bodyLits) of
                        (Just laxName, Just raxName, Just rightClause, [singleBody])
                          | Just leftLit <- inferLeftElectronLit singleBody l0σ0 rightClause
                          -> do
                              let completeBlk = insertLeftElectron leftLit laxName blk raxName l0σ0
                              -- Add with position first so getElectrons can find it, then
                              -- immediately promote to a named lemma.  ensureNamed picks up
                              -- the ueProof we stored and uses it without a duplicate addUnit.
                              addUnit (UnitEntry Nothing l0σ0 (Just completeBlk) (Just pos))
                              _ <- ensureNamed l0σ0 (return completeBlk)
                              return False
                        _ -> do
                          addUnit (UnitEntry Nothing l0σ0 (Just blk1) (Just pos))
                          return False
                Just _ ->
                  -- If l0σ0 matches the goal via variable instantiation (ρ0), emit directly.
                  -- Calling rwChainToLit on a symbolic l0σ0 would diverge.
                  case matchLit l0σ0 goalLit <|> matchLit (flipLit l0σ0) goalLit of
                    Just ρ0 ->
                      emitGoalProof goalLit (applySubstBlock ρ0 blk1) >> return True
                    Nothing -> do
                      units' <- gets stUnits
                      (cur, rwSteps) <- rwChainToLit l0σ0 goalLit units'
                      let blk2 = foldl applyRwLine blk1 rwSteps
                      if cur == goalLit
                        then emitGoalProof goalLit blk2 >> return True
                        else
                          let mρ0 = matchLit cur goalLit <|> matchLit (flipLit cur) goalLit
                          in case mρ0 of
                            Just ρ0 ->
                              emitGoalProof goalLit (applySubstBlock ρ0 blk2) >> return True
                            Nothing -> do
                              addUnit (UnitEntry Nothing l0σ0 (Just blk1) (Just pos))
                              return False

emitGoalProof :: Literal -> ProofBlock -> AlgM ()
emitGoalProof lit blk = modify $ \s -> s { stGoals = stGoals s ++ [(lit, blk)] }

-- Build the combined proof block from all matched electrons.
-- For each electron, first try proof-tree-guided demod replay (rwChainFromDemod);
-- if that yields no steps and the electron differs from the target, fall back to
-- greedy rewriting (rwChainToLit).
buildElectronBlock :: Subst -> [(UnitEntry, Subst, Literal)] -> Map.Map String [(String, Dir)] -> AlgM ProofBlock
buildElectronBlock _ [] _ = error "buildElectronBlock: empty electron list"
buildElectronBlock _σ0 ((k1, σ1, target1):rest) demodChains = do
  units <- gets stUnits
  rw1 <- electronRwSteps k1 σ1 target1 units
  blk0 <- makeBlock k1 σ1 rw1
  foldM addAndLine blk0 rest
  where
    addAndLine blk (ki, σi, targeti) = do
      units <- gets stUnits
      rwi <- electronRwSteps ki σi targeti units
      nameI <- ensureNamed targeti (makeBlock ki σi rwi)
      return $ appendLine blk (And targeti nameI)

    electronRwSteps ki σi targeti units =
      let chain = maybe [] (\p -> fromMaybe [] (Map.lookup p demodChains)) (uePos ki)
          (_, demodSteps) = rwChainFromDemod (applySubst σi (ueUnit ki)) chain units
          stepsApplied = demodSteps
          kiσi = applySubst σi (ueUnit ki)
      in if kiσi == targeti || flipLit kiσi == targeti
         -- K already matches the target (direct match found via tryDirect).
         -- The demod chain may point elsewhere; suppress it.
         then return []
         else if null stepsApplied
              then fmap snd (rwChainToLit kiσi targeti units)
              else return stepsApplied

-- Find a unit that matches the goal and return the instantiated goal.
-- Two directions are tried:
--   (1) unit as pattern → ρ0 maps unit-vars to goal-terms; goal unchanged.
--   (2) goal as pattern → ρ0 maps goal-vars to unit-terms; goal instantiated.
findUnitForGoal :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Literal)
findUnitForGoal goal units = listToMaybe $
  [ (ue, ρ0, goal)
  | ue <- units
  , Just ρ0 <- [matchLit (ueUnit ue) goal]
  ] ++
  [ (ue, [], applySubst ρ0 goal)
  | ue <- units
  , Just ρ0 <- [matchLit goal (ueUnit ue)]
  ]

-- Try to prove an equational goal via proof-tree-guided demod chain at p_{G₁}.
-- Returns True if successful; caller falls back to tryGreedySplitChain on False.
tryDemodSplitChain :: Literal -> [(String, Dir)] -> [UnitEntry] -> AlgM Bool
tryDemodSplitChain goalLit chain units = do
  let (lhs, rhs) = case goalLit of { Eq gl gr -> (gl, gr); _ -> error "tryDemodSplitChain: non-eq goal" }
      steps = splitChain lhs rhs chain units
  if null steps
    then return False
    else emitGoalProof goalLit (EqChain lhs steps) >> return True

-- Promote one step from a callTwee result chain into an AlgM RwStep.
promoteTweeStep :: (UnitEntry, Dir, Term) -> AlgM (RwStep, Term)
promoteTweeStep (stepUe, dir, cur) = do
  nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
  case ueUnit stepUe of
    Eq a b -> return (RwStep nm (a, b) dir, cur)
    _      -> error "promoteTweeStep: non-eq unit in Twee chain"

-- Try to prove an equational goal via a greedy named-equation rewrite chain.
-- Falls back to calling Twee when greedy rewriting falls short.
tryGreedySplitChain :: Term -> Term -> Literal -> AlgM Bool
tryGreedySplitChain s t goalLit = do
  allUnits <- gets stUnits
  let namedEqs = [ue | ue <- allUnits, isJust (ueName ue), isEqLit (ueUnit ue)]
      (lhs, rhs) = case goalLit of { Eq gl gr -> (gl, gr); _ -> (s, t) }
  (cur, steps) <- rwChainToTerm lhs rhs namedEqs
  if cur == rhs
    then emitGoalProof goalLit (EqChain lhs steps) >> return True
    else do
      mTwee <- liftIO (callTwee namedEqs goalLit)
      case mTwee of
        Just (start, chain) | not (null chain) -> do
          steps' <- mapM promoteTweeStep chain
          emitGoalProof goalLit (EqChain start steps') >> return True
        _ -> return False

-- Main loop: process non-unit clauses until all goals are emitted.
processNonUnits
  :: [(String, String, T.Declaration)]
  -> Map.Map String String
  -> [Literal]
  -> Map.Map String [(String, Dir)]  -- resolved demodulation chains
  -> Maybe [(String, Dir)]           -- demod chain at p_{G₁}
  -> AlgM ()
processNonUnits nonUnits posToName goalLits demodChains pG1Chain = go nonUnits
  where
    nGoals  = length goalLits
    goalLit = head goalLits

    -- Map position → clause for every node in allNus (both leaf and inner).
    -- Used to recover the right child's clause when building complete inner-node proofs.
    posToClause = Map.fromList
      [ (p, cls)
      | (p, _, d) <- nonUnits
      , Just cls  <- [convertDeclToClause d] ]

    go [] = return ()
    go ((pos, _, decl):rest) = do
      nDone <- gets (length . stGoals)
      if nDone >= nGoals then return ()
      else case convertDeclToClause decl of
        Nothing  -> error ("processNonUnits: cannot convert non-unit clause at position "
                        ++ pos ++ ": " ++ show decl)
        Just cls -> do
          let mAxiomName       = Map.lookup pos         posToName
              mLeftAxiomName   = Map.lookup (pos ++ "0") posToName
              mRightAxiomName  = Map.lookup (pos ++ "1") posToName
              mRightAxiomClause = Map.lookup (pos ++ "1") posToClause
          eqDone <- case cls of
            Clause [Eq s t] Nothing | isNothing mAxiomName ->
              tryEqGoal s t goalLit
            Clause bodyLits Nothing | isNothing mAxiomName, nGoals > 1 ->
              if all isEqLit goalLits
                then tryAllSplitChain goalLits
                else tryRelationalGoalBlock pos bodyLits goalLits demodChains
            _ -> return False
          if eqDone then return ()
          else do
            finished <- processNonUnit pos mAxiomName mLeftAxiomName mRightAxiomName
                          mRightAxiomClause cls goalLit demodChains
            if finished then return () else go rest

    -- Try proof-tree-guided splitChain first; fall back to greedy search.
    tryEqGoal s t gl = do
      units <- gets stUnits
      case pG1Chain of
        Just chain | not (null chain) -> do
          done <- tryDemodSplitChain gl chain units
          if done then return True else tryGreedySplitChain s t gl
        _ -> tryGreedySplitChain s t gl

-- For conjunctive conjectures: prove each goal conjunct independently via EqChain.
tryAllSplitChain :: [Literal] -> AlgM Bool
tryAllSplitChain goalLits = do
  results <- mapM tryOne goalLits
  return (and results)
  where
    tryOne glit = case glit of
      Eq lhs rhs -> do
        allUnits <- gets stUnits
        let namedEqs = [ue | ue <- allUnits, isJust (ueName ue), isEqLit (ueUnit ue)]
        (cur, steps) <- rwChainToTerm lhs rhs namedEqs
        if cur == rhs
          then emitGoalProof glit (EqChain lhs steps) >> return True
          else return False
      _ -> return False

-- For conjunctive relational conjectures: match all body literals jointly to get
-- a consistent substitution σ0, then emit each goal with its own electron.
-- The body literals of the negated conjecture are exactly the goal literals
-- (same atoms, same order), so matched[i] is the electron for goalLits[i].
tryRelationalGoalBlock
  :: String -> [Literal] -> [Literal] -> Map.Map String [(String, Dir)] -> AlgM Bool
tryRelationalGoalBlock pos bodyLits goalLits demodChains = do
  elecs  <- getElectrons pos
  mMatch <- matchBody pos bodyLits elecs demodChains []
  case mMatch of
    Just (σ0, matched) | length matched == length goalLits -> do
      forM_ (zip goalLits matched) $ \(gl, (ue, σi, _)) -> do
        let instGoal = applySubst σ0 gl
        blk <- makeBlock ue σi []
        emitGoalProof instGoal blk
      return True
    _ -> return False

-- Prove a goal from the accumulated unit set.
proveGoal :: Maybe [(String, Dir)] -> Literal -> AlgM ()
proveGoal mChain goal = do
  units <- gets stUnits
  case findUnitForGoal goal units of
    Just (ue, ρ0, instGoal) -> do
      (_, rw) <- rwChainToLit (applySubst ρ0 (ueUnit ue)) instGoal units
      blk <- makeBlock ue ρ0 rw
      emitGoalProof instGoal blk
    Nothing ->
      case goal of
        Eq s t -> do
          case mChain of
            Just chain | not (null chain) -> do
              let steps = splitChain s t chain units
              if not (null steps)
                then emitGoalProof goal (EqChain s steps)
                else do
                  (_, steps2) <- rwChainToTerm s t units
                  emitGoalProof goal (EqChain s steps2)
            _ -> do
              (cur, steps) <- rwChainToTerm s t units
              if cur == t
                then emitGoalProof goal (EqChain s steps)
                else do
                  mTwee <- liftIO (callTwee units goal)
                  case mTwee of
                    Just (start, chain) | not (null chain) -> do
                      steps' <- mapM promoteTweeStep chain
                      emitGoalProof goal (EqChain start steps')
                    _ -> emitGoalProof goal (EqChain s steps)
        _ -> emitGoalProof goal (HaveHence [])

runAlgorithm
  :: [UnitEntry]
  -> [(String, String, T.Declaration)]  -- leaf non-units (named axioms)
  -> [(String, String, T.Declaration)]  -- inner non-units (unnamed, derived)
  -> [Literal]
  -> Map.Map String [(String, Dir)]  -- demodulation chains from proof tree
  -> [(String, Literal)]             -- original equational axioms for Twee fallback
  -> [(String, Literal)]             -- original predicate unit axioms for pre-loop
  -> [(String, T.Declaration)]       -- single-body Horn clauses for pre-loop
  -> IO StructuredProof
runAlgorithm initUnits nonUnits innerNus goalLits demodChains origEqPairs origPredPairs origHornClauses = do
  let (axiomList, posToName, namedUnits) = assignAxiomNames initUnits nonUnits
      -- When all proof-tree positive-unit leaves were circular (excluded because
      -- they equal the goal), inject file-sourced axioms and run a pre-loop to
      -- derive any equational lemmas reachable in one Horn-clause resolution step.
      n0 = length axiomList
      (origEqAxiomList, origEqUnitEntries,
       origPredAxiomList, origPredUnitEntries,
       origHornAxiomList, namedPredForLoop, namedHornForLoop)
        | null namedUnits =
            let neq = length origEqPairs
                nep = length origPredPairs
                eqAxioms  = [ AUnit ("axiom " ++ show (n0 + i)) lit
                            | (i, (_, lit)) <- zip [1..] origEqPairs ]
                eqUEs     = [ UnitEntry (Just ("axiom " ++ show (n0 + i))) lit Nothing Nothing
                            | (i, (_, lit)) <- zip [1..] origEqPairs ]
                predAxioms = [ AUnit ("axiom " ++ show (n0 + neq + i)) lit
                             | (i, (_, lit)) <- zip [1..] origPredPairs ]
                predUEs    = [ UnitEntry (Just ("axiom " ++ show (n0 + neq + i))) lit Nothing Nothing
                             | (i, (_, lit)) <- zip [1..] origPredPairs ]
                hornAxioms = [ ANonUnit ("axiom " ++ show (n0 + neq + nep + i)) cls
                             | (i, (_, decl)) <- zip [1..] origHornClauses
                             , Just cls <- [convertDeclToClause decl] ]
                namedPred  = [ ("axiom " ++ show (n0 + neq + i), lit)
                             | (i, (_, lit)) <- zip [1..] origPredPairs ]
                namedHorn  = [ ("axiom " ++ show (n0 + neq + nep + i), decl)
                             | (i, (_, decl)) <- zip [1..] origHornClauses ]
            in (eqAxioms, eqUEs, predAxioms, predUEs, hornAxioms, namedPred, namedHorn)
        | otherwise = ([], [], [], [], [], [], [])
      allAxiomList = axiomList ++ origEqAxiomList ++ origPredAxiomList ++ origHornAxiomList
      nAll = length allAxiomList
      -- Pre-loop: derive equational lemmas from single-body Horn clauses + pred electrons.
      preLoopLemmas = deriveSingleBodyLemmas namedPredForLoop namedHornForLoop nAll
      preLoopUEs    = [ UnitEntry (Just nm) lit Nothing Nothing
                      | (nm, lit, _) <- preLoopLemmas ]
      -- Map resolved TSTP source names → assigned "axiom N" names so demod
      -- chain entries (which carry TSTP names) can be looked up in stUnits.
      srcToAxiom = Map.fromList
        [ (resName, axName)
        | ue <- initUnits
        , Just pos <- [uePos ue]
        , let resName = fromMaybe ("@" ++ pos) (ueName ue)
        , Just axName <- [Map.lookup pos posToName] ]
      resolvedChains = Map.map (map (\(n, d) -> (fromMaybe n (Map.lookup n srcToAxiom), d))) demodChains
      initSt = AlgState
        { stUnits        = namedUnits ++ origEqUnitEntries ++ origPredUnitEntries ++ preLoopUEs
        , stLemmas       = preLoopLemmas
        , stGoals        = []
        , stCounter      = nAll + length preLoopLemmas + 1
        , stDeferredGoalProof = Nothing
        }
      pG1Chain = listToMaybe
        [ fromMaybe [] (Map.lookup pos resolvedChains)
        | (pos, _, _) <- nonUnits
        , isNothing (Map.lookup pos posToName) ]
      action = do
        -- Sort leaf non-units and inner non-units together by position.
        -- Inner non-units with no positive head (mHead=Nothing, e.g. derived ¬p(a)) are
        -- excluded: they can't contribute lemmas and must not steal goal emission from
        -- the leaf negated conjecture.
        let hasGroundPositiveHead (_, _, d) = case convertDeclToClause d of
              Just (Clause _ (Just headLit)) -> null (litVars headLit)
              _                              -> False
            innerNusGround = filter hasGroundPositiveHead innerNus
            allNus = sortBy (comparing (\(p,_,_) -> p)) (nonUnits ++ innerNusGround)
        processNonUnits allNus posToName goalLits resolvedChains pG1Chain
        nDone <- gets (length . stGoals)
        when (nDone < length goalLits) $ do
          -- Try deferred Fix 2 candidates (single-electron proofs for inner non-units
          -- whose right-child axiom is named) before falling back to proveGoal.
          -- These are deferred so that named multi-body axiom leaves get a chance to
          -- produce correct multi-electron proofs first.
          pending <- gets stDeferredGoalProof
          case pending of
            Just (gl, blk) -> emitGoalProof gl blk
            Nothing        -> return ()
          nDone2 <- gets (length . stGoals)
          when (nDone2 < length goalLits) $ do
            proven <- gets (map fst . stGoals)
            let unproven = filter (`notElem` proven) goalLits
            mapM_ (proveGoal pG1Chain) unproven
  finalSt <- execStateT action initSt
  if null (stGoals finalSt)
    then error "translate: algorithm terminated without producing a goal proof"
    else return (StructuredProof allAxiomList (stLemmas finalSt) (stGoals finalSt))
