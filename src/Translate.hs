module Translate (translate) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, forM_, void, when)
import Control.Monad.State
import Data.Char (toUpper)
import Data.List (find, intercalate, isInfixOf, nub, partition, sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (catMaybes, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe)
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import System.IO (hPutStrLn, stderr)
import System.Process (readProcessWithExitCode)

import Types
import Helpers
import ProofTree
  ( LeafRole(..), LeafEntry(..), ProofInfo(..)
  , buildProofInfo, headLitOf, unitNameStr
  )

translate :: Bool -> T.TSTP -> IO StructuredProof
translate debug (T.TSTP _ units) =
  case buildProofInfo units of
    Nothing   -> error "translate: no refutation found"
    Just info -> runAlgorithm debug info units

type AlgM a = StateT AlgState IO a

addUnit :: UnitEntry -> AlgM ()
addUnit ue = modify $ \s -> s { stUnits = stUnits s ++ [ue] }

nextCounter :: AlgM Int
nextCounter = do
  k <- gets stCounter
  modify $ \s -> s { stCounter = k + 1 }
  return k

-- unnamed (locally-derived) electrons first; named axioms second
getElectrons :: String -> AlgM [UnitEntry]
getElectrons pos = gets $ \s ->
  let avail   = filter (\u -> maybe False (< pos) (uePos u)) (stUnits s)
      unnamed = filter (isNothing . ueName) avail
      named   = filter (isJust   . ueName) avail
  in unnamed ++ named

emitGoalProof :: Literal -> ProofBlock -> AlgM ()
emitGoalProof lit blk = modify $ \s -> s { stGoals = stGoals s ++ [(lit, blk)] }

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
    promote nm u
      | ueUnit u == lit && isNothing (ueName u) =
          u { ueName = Just nm, ueProof = Nothing }
      | otherwise = u

-- promotes to a lemma if unnamed; runs buildBlk to get a proof when needed
ensureNamed :: Literal -> AlgM ProofBlock -> AlgM String
ensureNamed lit buildBlk = do
  units <- gets stUnits
  case find (\u -> ueUnit u == lit) units of
    Just ue ->
      case ueName ue of
        Just nm -> return nm
        Nothing ->
          case ueProof ue of
            Just blk -> promoteToLemma lit blk
            Nothing  -> buildBlk >>= promoteToLemma lit
    Nothing -> do
      blk  <- buildBlk
      nm   <- promoteToLemma lit blk
      addUnit (UnitEntry (Just nm) lit Nothing Nothing)
      return nm

-- match body literal li against electron ki; returns (σi, σ0') on success
tryMatch :: Literal -> Literal -> Subst -> Maybe (Subst, Subst)
tryMatch li ki σ0 =
  tryAsPattern li ki
  <|> tryAsPattern (flipEq li) ki
  <|> tryKiPattern ki
  <|> tryKiPattern (flipEq ki)
  <|> tryKiFlip ki
  <|> tryBothSides li ki
  <|> tryBothSides (flipEq li) ki
  where
    tryAsPattern li' k = case matchLit li' k of
      Just σn -> case extendSubst σ0 σn of
        Just σ0' -> Just ([], σ0')
        Nothing  -> Nothing
      Nothing -> Nothing
    tryKiPattern k = case matchLit k li of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    tryKiFlip k = case matchLit k (flipEq li) of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    tryBothSides li' k = case matchBothLit li' k σ0 [] of
      Just (σ0', σi) ->
        let σ0c = [(x, applySubstTerm σi t) | (x, t) <- σ0']
        in if applySubst σ0c li' == applySubst σi k
           then Just (σi, σ0c)
           else Nothing
      _ -> Nothing
    flipEq (Eq l r) = Eq r l
    flipEq x        = x

-- replay demod chain: outermost-first on input, reversed to replay innermost-first;
-- steps whose equation isn't in units are skipped
rwChain :: Literal -> [(String, Dir)] -> [UnitEntry] -> (Literal, [(RwStep, Literal)])
rwChain start chain units = go start [] (reverse chain)
  where
    go cur acc [] = (cur, reverse acc)
    go cur acc ((nm, dir) : rest) =
      case findEqByName nm units of
        Nothing     -> go cur acc rest
        Just (l, r) ->
          case rewriteLit cur (l, r) dir of
            Nothing   -> go cur acc rest
            Just cur' -> go cur' ((RwStep nm (l, r) dir, cur') : acc) rest

-- raw derived electrons with no proof excluded: Twee can't justify them later
tweableUnits :: [UnitEntry] -> [UnitEntry]
tweableUnits = filter (\u -> isJust (ueName u) || isJust (ueProof u))

tweeChain :: Term -> Term -> [UnitEntry] -> AlgM (Maybe ProofBlock)
tweeChain l r units = do
  mRes <- liftIO (callTwee units (Eq l r))
  case mRes of
    Nothing              -> return Nothing
    Just (_, [])         -> return Nothing
    Just (start, chain) -> do
      steps <- mapM promoteStep chain
      return (Just (EqChain start steps))
  where
    promoteStep (stepUe, dir, cur) = do
      nm <- ensureNamed (ueUnit stepUe)
               (makeBlock stepUe [] [])
      case ueUnit stepUe of
        Eq a b -> return (RwStep nm (a, b) dir, cur)
        _      -> error "tweeChain: non-eq unit in Twee chain"

-- step 1: pure match with backtracking; steps 2/2.5/3 (IO) only when step 1 fails
processBody
  :: [Literal]
  -> Subst
  -> [UnitEntry]
  -> Map.Map String [(String, Dir)]
  -> String
  -> AlgM (Maybe (Subst, [(UnitEntry, Subst, [(RwStep, Literal)])]))
processBody lits σ0 elecs simpl pos = go lits σ0 []
  where
    go [] σ0' _ = return (Just (σ0', []))
    go (li : rest) σ0' usedPos = do
      let liInst    = applySubst σ0' li
          (unused, used') = partition (\e -> uePos e `notElem` usedPos) elecs
          prioritized = unused ++ used'
          step1Elecs  = filter (\ue -> isJust (ueName ue) || isJust (ueProof ue)) prioritized
          -- All pure step-1 candidates (no IO)
          pureMatches = [ (ue, σi, σ0'', [])
                        | ue <- step1Elecs
                        , Just (σi, σ0'') <- [tryMatch liInst (ueUnit ue) σ0'] ]
      mBT <- tryAll pureMatches rest usedPos
      case mBT of
        Just res -> return (Just res)
        Nothing  -> do
          -- IO fallback: steps 2 / 2.5 / 3
          units <- gets stUnits
          let step2Matches =
                [ (ue, σi, σ0'', rw)
                | ue <- elecs
                , let chain = fromMaybe [] (Map.lookup (fromMaybe "" (uePos ue)) simpl)
                , not (null chain)
                , let (kstar, rw) = rwChain (ueUnit ue) chain units
                , not (null rw)
                , Just (σi, σ0'') <- [tryMatch liInst kstar σ0'] ]
          mBT2 <- tryAll step2Matches rest usedPos
          case mBT2 of
            Just res -> return (Just res)
            Nothing -> do
              mRes <- findElecIO liInst σ0' prioritized pos units
              case mRes of
                Nothing -> return Nothing
                Just (ki, σi, σ0'', rwi) ->
                  complete ki σi σ0'' rwi rest usedPos

    tryAll [] _ _ = return Nothing
    tryAll ((ki, σi, σ0'', rwi) : rest_cands) restLits usedPos = do
      mResult <- go restLits σ0'' (uePos ki : usedPos)
      case mResult of
        Just (σ0''', matched) -> return (Just (σ0''', (ki, σi, rwi) : matched))
        Nothing               -> tryAll rest_cands restLits usedPos

    complete ki σi σ0'' rwi restLits usedPos = do
      mRest <- go restLits σ0'' (uePos ki : usedPos)
      case mRest of
        Nothing              -> return Nothing
        Just (σ0''', matched) -> return (Just (σ0''', (ki, σi, rwi) : matched))

-- step 2.5: dynamic rw match; step 3: Twee fallback for equational literals
findElecIO
  :: Literal -> Subst -> [UnitEntry] -> String
  -> [UnitEntry]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
findElecIO li σ0 elecs pos units = do
  step25 <- do
    let haveHenceElecs =
          [ u | u <- elecs, isNothing (ueName u), Just (HaveHence _) <- [ueProof u] ]
        namedElecs = [ u | u <- elecs, isJust (ueName u) ]
        rwEqs = [ (eq, a, b) | eq <- tweableUnits elecs, Eq a b <- [ueUnit eq] ]
        srcElecs = case li of
          Eq _ _ -> haveHenceElecs
          _      -> haveHenceElecs ++ namedElecs
        rwMatches =
          [ (u, eq, a, b, dir, σi, σ0')
          | u <- srcElecs, (eq, a, b) <- rwEqs, dir <- [LR, RL]
          , Just res <- [rewriteLit (ueUnit u) (a, b) dir]
          , Just (σi, σ0') <- [tryMatch li res σ0] ]
    case listToMaybe rwMatches of
      Nothing -> return Nothing
      Just (u, eq, a, b, dir, σi, σ0') -> do
        nm <- ensureNamed (ueUnit eq) (makeBlock eq [] [])
        let result = applySubst σi (fromMaybe li (rewriteLit (ueUnit u) (a, b) dir))
        return (Just (u, σi, σ0', [(RwStep nm (a, b) dir, result)]))
  case step25 of
    Just res -> return (Just res)
    Nothing  ->
      case li of
        Eq l r -> do
          mBlk <- tweeChain l r (tweableUnits units)
          case mBlk of
            Nothing  -> return Nothing
            Just blk -> do
              let ki = UnitEntry Nothing li (Just blk) (Just pos)
              addUnit ki
              return (Just (ki, [], σ0, []))
        _ -> return Nothing

-- rwSteps come from rwChain on the uninstantiated electron; σi applied to literals
-- so "hence p(a)" appears instead of "hence p(X)"
makeBlock :: UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
makeBlock ki σi rwSteps = do
  units <- gets stUnits
  base  <- buildBase units
  let rwStepsInst = map (\(rw, c) -> (rw, applySubst σi c)) rwSteps
  return (foldl applyRwLine base rwStepsInst)
  where
    lit = applySubst σi (ueUnit ki)

    buildBase units =
      let allUnnamed = filter (\u -> ueUnit u == ueUnit ki && isNothing (ueName u)) units
          hasHence (HaveHence ls) = any (\l -> case l of Hence {} -> True; _ -> False) ls
          hasHence _              = False
          mBest = find (\u -> maybe False hasHence (ueProof u)) allUnnamed
              <|> listToMaybe allUnnamed
      in case mBest of
        Just unnamed ->
          case ueProof unnamed of
            Just stored
              | isEqChain stored -> do
                  nm <- ensureNamed (ueUnit ki) (return stored)
                  return (HaveHence [Have lit nm])
              | not (hasHence stored) -> do
                  nm <- ensureNamed (ueUnit ki) (return stored)
                  return (HaveHence [Have lit nm])
              | otherwise ->
                  return (applySubstBlock σi stored)
            Nothing ->
              -- named-only so Twee doesn't see circular unnamed units
              case ueUnit unnamed of
                Eq l r -> do
                  let namedUs = filter (isJust . ueName) units
                  mBlk <- tweeChain l r namedUs
                  case mBlk of
                    Just blk -> do
                      nm <- ensureNamed (ueUnit unnamed) (return blk)
                      return (HaveHence [Have lit nm])
                    Nothing  -> namedCase units
                _ -> namedCase units
        Nothing -> namedCase units

    namedCase units =
      case find (\u -> ueUnit u == ueUnit ki) units of
        Just u ->
          let nm = fromMaybe (error ("makeBlock: unnamed: " ++ show (ueUnit ki)))
                             (ueName u)
          in return (HaveHence [Have lit nm])
        Nothing ->
          error ("makeBlock: electron not in Units: " ++ show (ueUnit ki))

electronTarget :: UnitEntry -> Subst -> [(RwStep, Literal)] -> Literal
electronTarget ki σi rw = case rw of
  [] -> applySubst σi (ueUnit ki)
  _  -> snd (last rw)

buildProofBlock
  :: [(UnitEntry, Subst, [(RwStep, Literal)])]
  -> Maybe String  -- axiom name for "hence L0 by name" (Nothing for inner nodes)
  -> Subst         -- σ0
  -> Literal       -- head literal L0
  -> AlgM ProofBlock
buildProofBlock [] _ _ _ = error "buildProofBlock: empty"
buildProofBlock ((k1, σ1, rw1) : rest) mAxName σ0 headLit = do
  blk1 <- makeBlock k1 σ1 rw1
  blk  <- foldM addAnd blk1 rest
  return $ case mAxName of
    Just ax -> appendLine blk (Hence (applySubst σ0 headLit) (ByAxiom ax))
    Nothing -> blk
  where
    addAnd blk (ki, σi, rwi) = do
      let targ = electronTarget ki σi rwi
      blki <- makeBlock ki σi rwi
      nm   <- ensureNamed targ (return blki)
      return (appendLine blk (And targ nm))

-- equational goals use EqChain; relational goals use HaveHence
-- rwi non-empty forces HaveHence so "hence … by rw" is preserved
emitBlockForGoal :: Literal -> UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
emitBlockForGoal gl@(Eq l r) ki σi rwi
  | not (null rwi) = makeBlock ki σi rwi
  | isNothing (ueName ki)
  , Just (HaveHence {}) <- ueProof ki
  = makeBlock ki σi []
  | otherwise      =
      case buildEqChainFromElectron gl ki σi [] of
        Just blk -> return blk
        Nothing  -> do
          units <- gets stUnits
          mBlk  <- tweeChain l r (tweableUnits units)
          return (fromMaybe (EqChain l []) mBlk)
emitBlockForGoal _gl ki σi rwi = makeBlock ki σi rwi

buildEqChainFromElectron :: Literal -> UnitEntry -> Subst -> [(RwStep, Literal)] -> Maybe ProofBlock
buildEqChainFromElectron (Eq l r) ki σi [] = do
  nm    <- ueName ki
  (a,b) <- case ueUnit ki of { Eq a b -> Just (a,b); _ -> Nothing }
  let a' = applySubstTerm σi a
      b' = applySubstTerm σi b
      tryDir d = case rewriteTerm l (a', b') d of
                   Just cur | cur == r -> Just (EqChain l [(RwStep nm (a,b) d, r)])
                   _                   -> Nothing
  tryDir LR <|> tryDir RL
buildEqChainFromElectron _ _ _ _ = Nothing

processOneNonUnit
  :: Bool
  -> Subst
  -> LeafEntry
  -> Map.Map String String          -- pos → axiom name
  -> [Literal]                       -- goal literals
  -> Map.Map String [(String, Dir)]  -- simpl chains
  -> AlgM Bool
processOneNonUnit debug θ entry posToName goalLits simpl = do
  let pos    = lePos entry
      mAxName = Map.lookup pos posToName
  case convertDeclToClause (leSrcDecl entry) of
    Nothing  -> return False
    Just cls ->
      let Clause bodyLits mHead = applyGroundingClause θ cls
      in do
        elecs   <- getElectrons pos
        mResult <- processBody bodyLits [] elecs simpl pos
        case mResult of
          Nothing -> do
            liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ")"
                ++ "  body=[" ++ intercalate ", " (map ppLitI bodyLits) ++ "] — no matching electron found"
            return False
          Just (σ0, matched)  ->
            case mHead of
              Nothing ->
                -- L0 = ⊥: emit goal proofs; σ0 instantiates any remaining variables
                case (goalLits, matched) of
                  ([gl], [(ki, σi, _)])
                    | isNothing (ueName ki)
                    , Just chain@(EqChain {}) <- ueProof ki ->
                        emitGoalProof (applySubst σ0 gl) (applySubstBlock σi chain) >> return True
                  _ -> do
                    let pairs = zip goalLits matched
                    if null pairs
                      then return False
                      else do
                        forM_ pairs $ \(gl, (ki, σi, rwi)) -> do
                          let gl' = applySubst σ0 gl
                          blk <- emitBlockForGoal gl' ki σi rwi
                          emitGoalProof gl' blk
                        return True
              Just headLit -> do
                blk <- buildProofBlock matched mAxName σ0 headLit
                let headInst = applySubst σ0 headLit
                -- inner non-units (mAxName=Nothing) produce no "hence L0 by axiom",
                -- so skip storing them to avoid corrupting later proofs
                when (isJust mAxName) $ do
                  addUnit (UnitEntry Nothing headInst (Just blk) (Just pos))
                  -- EqChains can't nest inside HaveHence, so promote immediately
                  case blk of
                    EqChain {} -> void (ensureNamed headInst (return blk))
                    _          -> return ()
                return False

processNonUnits
  :: Bool
  -> Subst
  -> [LeafEntry]
  -> Map.Map String String
  -> [Literal]
  -> Map.Map String [(String, Dir)]
  -> AlgM ()
processNonUnits debug θ nonUnits posToName goalLits simpl = go nonUnits
  where
    nGoals = length goalLits

    go [] = return ()
    go (entry : rest) = do
      nDone <- gets (length . stGoals)
      if nDone >= nGoals then return ()
      else do
        done <- processOneNonUnit debug θ entry posToName goalLits simpl
        if done then return () else go rest

findUnitForGoal :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Literal)
findUnitForGoal goal units = listToMaybe $
  [ (ue, ρ0, goal)
  | ue <- units, Just ρ0 <- [matchLit (ueUnit ue) goal] ]
  ++
  [ (ue, [], applySubst ρ0 goal)
  | ue <- units, Just ρ0 <- [matchLit goal (ueUnit ue)] ]

-- reconstruct an equational proof from the demod chain at p_{G₁}
splitChain :: Term -> Term -> [(String, Dir)] -> [UnitEntry] -> [(RwStep, Term)]
splitChain l r chain units =
    if curL == curR then reverse leftSteps ++ reverseRight (reverse rightSteps) else []
  where
    (leftSteps, rightSteps, curL, curR) = foldl step ([], [], l, r) (reverse chain)

    step (ls, rs, accL, accR) (nm, dir) =
      case findEqByName nm units of
        Nothing     -> (ls, rs, accL, accR)
        Just (a, b) ->
          case rewriteTerm accL (a, b) dir of
            Just accL' -> ((RwStep nm (a, b) dir, accL') : ls, rs, accL', accR)
            Nothing    ->
              case rewriteTerm accR (a, b) dir of
                Just accR' -> (ls, (RwStep nm (a, b) dir, accR') : rs, accL, accR')
                Nothing    -> (ls, rs, accL, accR)

    reverseRight [] = []
    reverseRight rs =
      let prevTerms = r : map snd (init rs)
          flipped   = [ (RwStep nm eq (flipDir d), prev)
                      | ((RwStep nm eq d, _), prev) <- zip rs prevTerms ]
      in reverse flipped

    flipDir LR = RL
    flipDir RL = LR

proveGoal :: Maybe [(String, Dir)] -> Literal -> AlgM ()
proveGoal mChain goal = do
  units <- gets stUnits
  case goal of
    Eq l r -> do
      let chainSteps = case mChain of
            Just chain -> splitChain l r chain units
            Nothing    -> []
      if not (null chainSteps)
        then emitGoalProof goal (EqChain l chainSteps)
        else do
          us <- gets stUnits
          let mDerivedUnit = listToMaybe
                [ u | u <- us
                    , isNothing (ueName u)
                    , Just (HaveHence {}) <- [ueProof u]
                    , isJust (tryMatch goal (ueUnit u) []) ]
          mDerivedBlk <- case mDerivedUnit of
            Nothing -> return Nothing
            Just u  -> Just <$> makeBlock u [] []
          case mDerivedBlk of
            Just blk -> emitGoalProof goal blk
            Nothing  -> do
              mTwee <- liftIO (callTwee (tweableUnits units) goal)
              case mTwee of
                Just (start, chain) | not (null chain) -> do
                  steps' <- mapM promoteTweeStep chain
                  emitGoalProof goal (EqChain start steps')
                _ -> do
                  liftIO $ hPutStrLn stderr $
                    "[warn] no proof found for goal: " ++ ppLitI goal
                  emitGoalProof goal (EqChain l [])
    _ ->
      case findUnitForGoal goal units of
        Just (ue, ρ0, instGoal) -> do
          blk <- makeBlock ue ρ0 []
          emitGoalProof instGoal blk
        Nothing -> do
          liftIO $ hPutStrLn stderr $
            "[warn] no unit found for goal: " ++ ppLitI goal
          emitGoalProof goal (HaveHence [])
  where
    promoteTweeStep (stepUe, dir, cur) = do
      nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
      case ueUnit stepUe of
        Eq a b -> return (RwStep nm (a, b) dir, cur)
        _      -> error "proveGoal: non-eq unit in Twee chain"

-- use source formula (general form) for OrigAxiom; fall back to derived literal
-- when resolveSourceName traced through rewriting and the source is unrelated
electronLit :: Map.Map String T.Unit -> LeafEntry -> Literal
electronLit unitMap e = case leRole e of
  OrigAxiom ->
    case Map.lookup (leName e) unitMap of
      Just (T.Unit _ srcDecl _) | Just srcLit <- headLitOf srcDecl ->
        let converted = convertLit srcLit
            flipped   = flipLit converted
        in case matchLit converted derivedLit <|> matchLit flipped derivedLit of
             Just _ -> converted  -- derived is an instance (possibly flipped) of source
             Nothing -> derivedLit  -- unrelated: resolveSourceName traced through rewriting
      _ -> derivedLit
  _ -> derivedLit
  where
    derivedLit = case headLitOf (leDecl e) of
      Just lit -> convertLit lit
      Nothing  -> error ("electronLit: no head literal for " ++ leName e)

assignAxiomNames
  :: [LeafEntry]
  -> [LeafEntry]
  -> Map.Map String T.Unit
  -> ([Axiom], Map.Map String String, [UnitEntry])
assignAxiomNames electrons nonUnits unitMap =
  let unitTags    = [(lePos e, Left e)  | e <- electrons, leRole e == OrigAxiom]
      nonUnitTags = [(lePos e, Right e) | e <- nonUnits,  leRole e == OrigAxiom]
      allLeaves   = sortBy (comparing fst) (unitTags ++ nonUnitTags)
      (axiomList, posToName, _) = foldl step ([], Map.empty, Map.empty) allLeaves
      namedUnits =
        [ UnitEntry (Map.lookup (lePos e) posToName) (electronLit unitMap e) Nothing (Just (lePos e))
        | e <- electrons, leRole e == OrigAxiom ]
  in (axiomList, posToName, namedUnits)
  where
    step (axAcc, posMap, seen) (pos, Left e) =
      let origKey = leName e
          lit     = electronLit unitMap e
      in case Map.lookup origKey seen of
           Just existingName ->
             (axAcc, Map.insert pos existingName posMap, seen)
           Nothing ->
             let n  = length axAcc + 1
                 nm = "axiom " ++ show n
             in (axAcc ++ [AUnit nm lit],
                 Map.insert pos nm posMap,
                 Map.insert origKey nm seen)

    step (axAcc, posMap, seen) (pos, Right e) =
      -- leSrcDecl preserves the original body-literal order and equation direction
      let origKey = leName e
      in case Map.lookup origKey seen of
           Just existingName ->
             (axAcc, Map.insert pos existingName posMap, seen)
           Nothing ->
             case convertDeclToClause (leSrcDecl e) of
               Just cls@(Clause _ (Just _)) ->
                 let n  = length axAcc + 1
                     nm = "axiom " ++ show n
                 in (axAcc ++ [ANonUnit nm cls],
                     Map.insert pos nm posMap,
                     Map.insert origKey nm seen)
               _ -> (axAcc, posMap, seen)

applyGroundingClause :: Subst -> Clause -> Clause
applyGroundingClause θ (Clause bs mh) =
  Clause (map (applySubst θ) bs) (fmap (applySubst θ) mh)

buildGroundingSubst :: [Literal] -> Set.Set String -> [LeafEntry] -> Subst
buildGroundingSubst goalLits leafVars nonUnits =
  let innerClauses  = mapMaybe (\e -> convertDeclToClause (leDecl e))
                        (filter (\e -> leRole e == Derived) nonUnits)
      innerLits     = concatMap (\(Clause bs mh) -> bs ++ catMaybes [mh]) innerClauses
      innerFreeVars = nub $ concatMap litVars innerLits
      trueFreeVars  = filter (`Set.notMember` leafVars) innerFreeVars
      goalConsts    = nub $ concatMap litConsts goalLits
      groundTerm    = case goalConsts of { (c:_) -> Const c; [] -> Const "c_ground" }
  in [(v, groundTerm) | v <- trueFreeVars]

ppTerm :: Term -> String
ppTerm (Var x)    = x
ppTerm (Const c)  = c
ppTerm (App f ts) = f ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

ppLitI :: Literal -> String
ppLitI (Eq  a b)   = ppTerm a ++ " = " ++ ppTerm b
ppLitI (NEq a b)   = ppTerm a ++ " ≠ " ++ ppTerm b
ppLitI (Rel p [])  = p
ppLitI (Rel p ts)  = p ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"
ppLitI (NRel p []) = "¬" ++ p
ppLitI (NRel p ts) = "¬" ++ p ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

ppClauseI :: Clause -> String
ppClauseI (Clause [] Nothing)  = "⊥"
ppClauseI (Clause bs Nothing)  = intercalate ", " (map ppLitI bs) ++ " → ⊥"
ppClauseI (Clause [] (Just h)) = ppLitI h
ppClauseI (Clause bs (Just h)) = intercalate ", " (map ppLitI bs) ++ " → " ++ ppLitI h

ppDir :: Dir -> String
ppDir LR = "L→R"
ppDir RL = "R→L"

ppSimplChain :: [(String, Dir)] -> String
ppSimplChain [] = "(none)"
ppSimplChain ss = intercalate ", " [n ++ "(" ++ ppDir d ++ ")" | (n, d) <- ss]

dbg :: Bool -> String -> IO ()
dbg True  msg = hPutStrLn stderr msg
dbg False _   = return ()

runAlgorithm :: Bool -> ProofInfo -> [T.Unit] -> IO StructuredProof
runAlgorithm debug info allUnits = do
  let unitMap    = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      goalLits'  = map convertLit (piGoalLits info)

      (axiomList, posToName, namedUnits) =
        assignAxiomNames (piElectrons info) (piNonUnits info) unitMap

      nameToAxiom = Map.fromList
        [ (leName e, nm)
        | e <- piElectrons info, leRole e == OrigAxiom
        , Just nm <- [Map.lookup (lePos e) posToName] ]
      resolveSimplName n = fromMaybe n (Map.lookup n nameToAxiom)
      simpl = Map.fromList
        [ (lePos e, [(resolveSimplName n, d) | (n, d) <- leSimpl e])
        | e <- piElectrons info ]

      -- demod chain at the negated conjecture position; used by splitChain as fallback
      pG1Chain = case find (\e -> leRole e == NegConjecture) (piNonUnits info) of
        Just e | not (null (leSimpl e)) ->
          Just [(resolveSimplName n, d) | (n, d) <- leSimpl e]
        _ -> Nothing

      derivedUnits =
        [ UnitEntry Nothing (electronLit unitMap e) Nothing (Just (lePos e))
        | e <- filter (\e -> leRole e == Derived) (piElectrons info)
        , let lit = electronLit unitMap e
        , lit `notElem` goalLits' ]

      -- variables from file-sourced axioms are legitimately universally quantified
      leafVars = Set.fromList $
        concatMap (litVars . electronLit unitMap)
          (filter (\e -> leRole e == OrigAxiom) (piElectrons info))
        ++
        concatMap (\e -> maybe [] clauseVars (convertDeclToClause (leDecl e)))
          (filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNonUnits info))
        where clauseVars (Clause bs mh) = concatMap litVars (bs ++ catMaybes [mh])

      θ = buildGroundingSubst goalLits' leafVars (piNonUnits info)

      -- derived clauses with L0=⊥ are skipped: they'd intercept goal emission
      hasGroundHead e = case convertDeclToClause (leDecl e) of
        Just (Clause _ (Just hl)) -> null (litVars (applySubst θ hl))
        _                         -> False
      leafNonUnits = filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNonUnits info)
      innerNus     = filter (\e -> leRole e == Derived && hasGroundHead e) (piNonUnits info)
      allNonUnits  = sortBy (comparing lePos) (leafNonUnits ++ innerNus)

      nAll = length axiomList
      initSt = AlgState
        { stUnits   = namedUnits ++ derivedUnits
        , stLemmas  = []
        , stGoals   = []
        , stCounter = nAll + 1
        }

  when debug $ do
    dbg debug $ "goals: " ++ intercalate ", " (map ppLitI goalLits')
    dbg debug ""
    let tagged = map (True,)  (piElectrons info)
              ++ map (False,) allNonUnits
        sorted  = sortBy (comparing (lePos . snd)) tagged
        showPos p = if null p then "ε" else p
        posWidth = maximum $ map (length . showPos . lePos . snd) sorted
        padPos p = let s = showPos p in s ++ replicate (posWidth - length s) ' '
    forM_ sorted $ \(isElec, e) -> do
      let tag    = if isElec then "+" else "-"
          axNm   = fromMaybe (leName e) (Map.lookup (lePos e) posToName)
          label  = case leRole e of
                     OrigAxiom     -> axNm
                     NegConjecture -> "[goal]"
                     Derived       -> "[derived]"
          lit    = if isElec
                   then ppLitI (electronLit unitMap e)
                   else maybe "?" ppClauseI (convertDeclToClause (leSrcDecl e))
          simplS = case [(resolveSimplName n, d) | (n, d) <- leSimpl e] of
                     [] -> ""
                     ss -> "  {" ++ ppSimplChain ss ++ "}"
      dbg debug $ "  @" ++ padPos (lePos e) ++ " [" ++ tag ++ "] " ++ label ++ ": " ++ lit ++ simplS
    when (not (null θ)) $ do
      dbg debug ""
      dbg debug $ "θ: " ++ intercalate ", " [v ++ " → " ++ ppTerm t | (v, t) <- θ]
    forM_ pG1Chain $ \chain -> do
      dbg debug ""
      dbg debug $ "pG1: " ++ ppSimplChain chain
    dbg debug ""

  finalSt <- execStateT (action θ allNonUnits posToName goalLits' simpl pG1Chain) initSt
  if null (stGoals finalSt)
    then error "translate: no goal proof produced"
    else return (StructuredProof axiomList (stLemmas finalSt) (stGoals finalSt))
  where
    action θ allNonUnits posToName goalLits simpl pG1Chain = do
      processNonUnits debug θ allNonUnits posToName goalLits simpl
      nDone <- gets (length . stGoals)
      when (nDone < length goalLits) $ do
        proven <- gets (map fst . stGoals)
        let unproven = filter (`notElem` proven) goalLits
        mapM_ (proveGoal pG1Chain) unproven

tweeBin :: FilePath
tweeBin = "bin/twee"

toTptpTerm :: Term -> String
toTptpTerm (Var [])       = []
toTptpTerm (Var (c:cs))   = toUpper c : cs
toTptpTerm (Const f)      = f
toTptpTerm (App f ts)     = f ++ "(" ++ intercalate "," (map toTptpTerm ts) ++ ")"

toCnfAxiom :: String -> Term -> Term -> String
toCnfAxiom name l r =
  "cnf(" ++ name ++ ", axiom, " ++ toTptpTerm l ++ " = " ++ toTptpTerm r ++ ")."

toCnfNegGoal :: String -> Term -> Term -> String
toCnfNegGoal name l r =
  "cnf(" ++ name ++ ", negated_conjecture, " ++ toTptpTerm l ++ " != " ++ toTptpTerm r ++ ")."

sanitizeId :: String -> String
sanitizeId = map (\c -> if c == ' ' then '_' else c)

isEqLit :: Literal -> Bool
isEqLit (Eq _ _) = True
isEqLit _        = False

dirFlag :: Dir -> Maybe Dir
dirFlag LR = Nothing
dirFlag RL = Just RL


findEqByName :: String -> [UnitEntry] -> Maybe (Term, Term)
findEqByName nm units = listToMaybe
  [ (l, r) | ue <- units, ueName ue == Just nm, Eq l r <- [ueUnit ue] ]

applyRwLine :: ProofBlock -> (RwStep, Literal) -> ProofBlock
applyRwLine b (rw, c) = appendLine b (Hence c (ByRw (rwName rw) (dirFlag (rwDir rw))))

parseTweeStepNames :: String -> [String]
parseTweeStepNames output =
  mapMaybe extractName (filter ("{ by axiom" `isInfixOf`) (lines output))
  where
    extractName line = case dropWhile (/= '(') line of
      []       -> Nothing
      (_:rest) -> let nm = takeWhile (/= ')') rest
                  in if null nm then Nothing else Just nm

-- backtrack over rewrite positions because root-first order may be wrong
-- (e.g. f(X)=X matches root and subterm; root can be the wrong choice)
replayTweeChainTo
  :: Map.Map String UnitEntry -> [String] -> Term -> Term
  -> [(UnitEntry, Dir, Term)]
replayTweeChainTo idToUe stepNames start end = fromMaybe [] (go start stepNames)
  where
    go cur [] = if cur == end then Just [] else Nothing
    go cur (tid:rest) =
      case Map.lookup tid idToUe of
        Nothing -> go cur rest
        Just ue ->
          case ueUnit ue of
            Eq a b ->
              listToMaybe
                [ (ue, dir, t) : steps
                | (dir, t) <- [(LR, u) | u <- rewriteTermAll cur (a, b) LR]
                           ++ [(RL, u) | u <- rewriteTermAll cur (a, b) RL]
                , Just steps <- [go t rest]
                ]
            _ -> go cur rest

callTwee :: [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTwee units (Eq l r) = do
  let rawEqUnits = [(i, ue) | (i, ue) <- zip [(0::Int)..] units, isEqLit (ueUnit ue)]
      -- Put general (variable-containing) equations before ground ones so Twee's
      -- proof strategy is consistent regardless of the prover's axiom ordering.
      eqUnits = sortBy (\(_, u1) (_, u2) ->
                  compare (null (litVars (ueUnit u1))) (null (litVars (ueUnit u2))))
                rawEqUnits
      mkId i ue = fromMaybe ("anon_" ++ show i) (sanitizeId <$> ueName ue)
      idToUe  = Map.fromList [(mkId i ue, ue) | (i, ue) <- eqUnits]
      axioms  = [ toCnfAxiom (mkId i ue) a b
                | (i, ue) <- eqUnits, Eq a b <- [ueUnit ue] ]
      negGoal = toCnfNegGoal "goal" l r
      input   = unlines (axioms ++ [negGoal])
      tmpFile = "/tmp/taelja_twee_input.p"
  writeFile tmpFile input
  (_, out, _) <- readProcessWithExitCode tweeBin
                   ["--no-colour", "--formal-proof", "--max-time", "10", tmpFile] ""
  let stepNames = parseTweeStepNames out
      chainL    = replayTweeChainTo idToUe stepNames l r
      chainR    = replayTweeChainTo idToUe stepNames r l
      result
        | not (null chainL) = Just (l, chainL)
        | not (null chainR) = Just (r, chainR)
        | otherwise         = Nothing
  return result
callTwee _ _ = return Nothing

-- ── TPTP → internal conversion ───────────────────────────────────────────────

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

