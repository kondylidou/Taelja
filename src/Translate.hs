{-# LANGUAGE LambdaCase #-}
module Translate (translate) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, forM, forM_, unless, void, when)
import Data.Bifunctor (second)
import Control.Monad.State
import Data.List (find, intercalate, nub, nubBy, partition, sortBy)
import Data.Maybe (catMaybes, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe)
import Data.Ord (Down(..), comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
import ProofTree
  ( buildProofInfo, headLitOf, unitNameStr
  , resolveSourceName
  )
import TptpConvert
import TweeInterface
import LemmaBuilder

translate :: Bool -> T.TSTP -> IO (Maybe StructuredProof)
translate debug (T.TSTP _ units) =
  case buildProofInfo units of
    Nothing -> do
      hPutStrLn stderr "translate: no refutation found (unsupported proof structure)"
      return Nothing
    Just origInfo -> do
      let unitMap0 = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- units]
          origAxiomNames = Set.fromList
            [ leName e | e <- piElectrons origInfo, leRole e == OrigAxiom ]
          candidates = filter (\(cname, _) ->
                          resolveSourceName unitMap0 cname `Set.notMember` origAxiomNames)
                        (findLemmaCandidates units)
      if null candidates
        then Just <$> runAlgorithm debug origInfo units Map.empty
        else do
          let candNames = Set.fromList (map fst candidates)
              modUnits  = map replace units
              replace u@(T.Unit n _ _)
                | Set.member (unitNameStr n) candNames = makeFileSourced u
                | otherwise                            = u
              replace u = u
          -- First pass: make all candidates file-sourced to compute tstp2name
          case buildProofInfo modUnits of
            Nothing -> Just <$> runAlgorithm debug origInfo units Map.empty
            Just tentativeInfo -> do
              let tentativeUnitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- modUnits]
                  (_, tentativePosToName, _) =
                    assignAxiomNames (piElectrons tentativeInfo) (piNonUnits tentativeInfo) tentativeUnitMap
                  tstp2name = Map.fromList
                    [ (leName e, nm)
                    | e <- piElectrons tentativeInfo
                    , leRole e == OrigAxiom
                    , Just nm <- [Map.lookup (lePos e) tentativePosToName]
                    ]
                  unitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- units]
              candResults <- forM candidates (buildCandidateLemma unitMap tstp2name)
              let validNames = Set.fromList
                    [ cname | ((cname, _), Just _) <- zip candidates candResults ]
              if Set.null validNames
                then do
                  -- The tentative (file-source) pass failed — typically because the
                  -- candidate's ancestor axioms disappeared from the modified tree and
                  -- have no entry in tstp2name.  Retry using the original proof tree's
                  -- axiom names; if that works run with origInfo so the naming stays
                  -- consistent (original axioms keep their "axiom N" names in the output).
                  let (_, origPosToName, _) =
                        assignAxiomNames (piElectrons origInfo) (piNonUnits origInfo) unitMap0
                      origTstp2name = Map.fromList
                        [ (leName e, nm)
                        | e <- piElectrons origInfo
                        , leRole e == OrigAxiom
                        , Just nm <- [Map.lookup (lePos e) origPosToName]
                        ]
                  retryResults <- forM candidates (buildCandidateLemma unitMap0 origTstp2name)
                  let retryValidCands = Map.fromList
                        [ (cname, (lit, blk))
                        | ((cname, _), Just (lit, blk)) <- zip candidates retryResults ]
                  Just <$> runAlgorithm debug origInfo units retryValidCands
                else do
                  -- Second pass: only file-source the valid candidates, recompute
                  let finalModUnits = map (replaceValid validNames) units
                      replaceValid ns u@(T.Unit n _ _)
                        | Set.member (unitNameStr n) ns = makeFileSourced u
                        | otherwise                     = u
                      replaceValid _ u = u
                  case buildProofInfo finalModUnits of
                    Nothing -> Just <$> runAlgorithm debug origInfo units Map.empty
                    Just mainInfo -> do
                      let finalUnitMap = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- finalModUnits]
                          (_, posToName, _) =
                            assignAxiomNames (piElectrons mainInfo) (piNonUnits mainInfo) finalUnitMap
                          finalTstp2name = Map.fromList
                            [ (leName e, nm)
                            | e <- piElectrons mainInfo
                            , leRole e == OrigAxiom
                            , Just nm <- [Map.lookup (lePos e) posToName]
                            ]
                          validCandList = filter ((`Set.member` validNames) . fst) candidates
                      finalResults <- forM validCandList (buildCandidateLemma unitMap finalTstp2name)
                      let validCands = Map.fromList
                            [ (cname, (lit, blk))
                            | ((cname, _), Just (lit, blk)) <- zip validCandList finalResults
                            ]
                      Just <$> runAlgorithm debug mainInfo finalModUnits validCands

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
  let avail   = filter (maybe False (< pos) . uePos) (stUnits s)
      unnamed = filter (isNothing . ueName) avail
      named   = filter (isJust   . ueName) avail
  in unnamed ++ named

emitGoalProof :: Literal -> ProofBlock -> AlgM ()
emitGoalProof lit blk = modify $ \s -> s { stGoals = stGoals s ++ [(lit, blk)] }

promoteToLemma :: Literal -> ProofBlock -> AlgM String
promoteToLemma lit blk = do
  goalVs <- gets stGoalVars
  let freeVars = Set.fromList (litVars lit)
      -- EqChains are always valid universally-quantified equational lemmas.
      -- HaveHence with And steps comes from a multi-body nucleus application;
      -- if the head has free variables not from the goal, the nucleus unification
      -- was incomplete and the lemma statement is unsound.
      -- HaveHence without And steps is a sequential horn derivation, which is
      -- always valid even if non-ground.
      hasAndStep (HaveHence steps) = any (\case And {} -> True; _ -> False) steps
      hasAndStep _                 = False
      shouldBlock = hasAndStep blk
                 && not (freeVars `Set.isSubsetOf` goalVs)
  if shouldBlock
    then do
      units <- gets stUnits
      case find (\u -> ueUnit u == lit && isJust (ueName u)) units of
        Just u  -> return (fromMaybe "axioms" (ueName u))
        Nothing -> return "axioms"
    else do
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

-- promotes to a lemma if unnamed; runs buildBlk to get a proof when needed.
-- An empty HaveHence [] block (returned when twee cannot prove a derived
-- relational unit) is never promoted to a named lemma — we fall back to the
-- generic justification "axioms" so the parent proof step is still emitted.
ensureNamed :: Literal -> AlgM ProofBlock -> AlgM String
ensureNamed lit buildBlk = do
  units <- gets stUnits
  case find (\u -> ueUnit u == lit) units of
    Just ue ->
      case ueName ue of
        Just nm -> return nm
        Nothing ->
          case ueProof ue of
            Just blk -> case blk of
              HaveHence [Have _ nm] -> return nm
              _                     -> promoteToLemma lit blk
            Nothing  -> do
              blk <- buildBlk
              case blk of
                HaveHence []        -> error ("ensureNamed: no proof found for: " ++ show lit)
                HaveHence [Have _ nm] -> return nm
                _                   -> promoteToLemma lit blk
    Nothing -> do
      blk <- buildBlk
      case blk of
        HaveHence [] -> error ("ensureNamed: no proof found for: " ++ show lit)
        -- Single "have lit by name" with no further steps: inline the name
        -- directly rather than wrapping in a trivial lemma.  This covers both
        -- ground axiom instances (e.g. product(a,a,identity) by axiom 3) and
        -- ground instances of non-ground lemmas (e.g. p(a) by lemma 5).
        HaveHence [Have _ nm] -> return nm
        _ -> do
          nm <- promoteToLemma lit blk
          addUnit (UnitEntry (Just nm) lit Nothing Nothing)
          return nm

-- Length of common prefix of two strings.
commonPrefixLen :: String -> String -> Int
commonPrefixLen s1 s2 = length $ takeWhile id $ zipWith (==) s1 s2

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
      Just σn ->
        -- Remove self-bindings (x → Var x): these arise when body lit and electron
        -- share a variable name (e.g. both use "X0"). An identity binding would
        -- prevent a later body literal from properly grounding that variable.
        let σn' = filter (\(x, t) -> Var x /= t) σn
        in case extendSubst σ0 σn' of
          Just σ0' -> Just ([], σ0')
          Nothing  -> Nothing
      Nothing -> Nothing
    tryKiPattern k = case matchLit k li of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    tryKiFlip k = case matchLit k (flipEq li) of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    tryBothSides li' k =
      -- Rename ki's vars to avoid clashes with li's vars in matchBothLit.
      -- Without this, shared var names (e.g. both using "X0") confuse matchBothLit
      -- into treating them as the same variable, producing incorrect bindings.
      let kVars = nub (litVars k)
          k'    = suffixVarsLit "_e" k
      in case matchBothLit li' k' σ0 [] of
        Just (σ0', σi') ->
          -- Occurs check: if any ki-var's binding contains itself, deepApplySubstTerm loops.
          if any (\(v, t) -> v `elem` termVars t) σi'
            then Nothing
            else
              let σ0c = [(x, deepApplySubstTerm σi' t) | (x, t) <- σ0']
                  -- Apply σ0c to ground any σ0-vars that appear in σi' bindings.
                  σi  = [ (v, applySubstTerm σ0c (deepApplySubstTerm σi' (Var (v ++ "_e")))) | v <- kVars ]
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

-- Algorithm 3 find_elec: step 1 is a pure match; step 2 is rw_chain (demod chain,
-- with Twee as fallback when the chain is absent or produces no steps), then tryMatch.
processBody
  :: [Literal]
  -> Subst
  -> [UnitEntry]
  -> Map.Map String [(String, Dir)]
  -> String
  -> AlgM (Maybe (Subst, [(UnitEntry, Subst, [(RwStep, Literal)])]))
processBody lits σ0 elecs simpl pos = go lits σ0 []
  where
    -- Three-tier ordering:
    --  1. Direct sibling at pos[:-1]+"0" (the proof-tree electron for the outermost body lit)
    --  2. Unnamed derived electrons, sorted by proximity (nearest first)
    --  3. Named (axiom) electrons, sorted by proximity
    sortedElecs =
      let siblingPos = if not (null pos) && last pos == '1'
                       then Just (init pos ++ "0") else Nothing
          (sibling, rest) = case siblingPos of
            Nothing -> ([], elecs)
            Just sp -> partition (\e -> uePos e == Just sp) elecs
          (unnamed, named) = partition (isNothing . ueName) rest
          byProx = Down . commonPrefixLen pos . fromMaybe "" . uePos
          sortedUnnamed = sortBy (comparing byProx) unnamed
          sortedNamed   = sortBy (comparing byProx) named
      in sibling ++ sortedUnnamed ++ sortedNamed

    go [] σ0' _ = return (Just (σ0', []))
    go (li : rest) σ0' usedPos = do
      let liInst    = applySubst σ0' li
          (unused, used') = partition (\e -> uePos e `notElem` usedPos) sortedElecs
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
          units <- gets stUnits
          -- Step 2: rw_chain — demod chain if available, Twee when absent or no steps
          tryRwChain liInst σ0' units prioritized rest usedPos

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

    -- rw_chain: try demod chain for each candidate; Twee when chain is absent or gives no steps.
    tryRwChain liInst σ0' units candidates restLits usedPos = do
      let demodMatches =
            [ (ue, σi, σ0'', rw)
            | ue <- candidates
            , let chain = fromMaybe [] (Map.lookup (fromMaybe "" (uePos ue)) simpl)
            , not (null chain)
            , let (kstar, rw) = rwChain (ueUnit ue) chain units
            , not (null rw)
            , Just (σi, σ0'') <- [tryMatch liInst kstar σ0'] ]
      mBT <- tryAll demodMatches restLits usedPos
      case mBT of
        Just res -> return (Just res)
        Nothing  -> do
          mRes <- findElecIO liInst σ0' pos units
          case mRes of
            Nothing              -> return Nothing
            Just (ki, σi, σ0'', rwi) -> complete ki σi σ0'' rwi restLits usedPos

-- Twee rw_chain fallback: called from tryRwChain when the demod chain is absent or gives no steps.
-- For equational literals, calls Twee on the body literal, then recovers the HaveHence
-- electron from the chain; falls back to a synthetic EqChain unit when recovery fails.
-- For relational literals, calls equational Twee treating the predicate as a function
-- (handles terminating rewrites); falls back to single-step rewriting for non-terminating cases.
findElecIO
  :: Literal -> Subst -> String
  -> [UnitEntry]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
findElecIO li σ0 pos units = case li of
  Eq l r -> do
    mRaw <- liftIO (callTwee (tweableUnits units) (Eq l r))
    case mRaw of
      Nothing       -> return Nothing
      Just (_, [])  -> return Nothing
      Just (_, chain) -> do
        mRes <- recoverElecFromTweeChain li σ0 chain
        case mRes of
          Just res -> return (Just res)
          Nothing  -> do
            steps' <- mapM promoteStep chain
            let blk = EqChain l steps'
                ki  = UnitEntry Nothing li (Just blk) (Just pos)
            addUnit ki
            return (Just (ki, [], σ0, []))
  _ -> do
    let isHHu u    = case ueProof u of { Just (HaveHence _) -> True; _ -> False }
        hhElecs    = [ u | u <- units, isNothing (ueName u), isHHu u ]
        namedElecs = [ u | u <- units, isJust (ueName u) ]
        srcElecs   = hhElecs ++ namedElecs
        eqEntries  = filter (isEqLit . ueUnit) (tweableUnits units)
    mRw <- matchViaRw li σ0 srcElecs eqEntries
    case mRw of
      Just res -> return (Just res)
      Nothing  -> do
        mRaw <- liftIO (callTwee (tweableUnits units) li)
        case mRaw of
          Nothing      -> return Nothing
          Just (_, []) -> return Nothing
          Just (start, chain) -> do
            let goalFun = case li of { Rel n _ -> n; _ -> "" }
                validInter (_, _, t) = case t of
                  Const n -> n == goalFun || n == "true"
                  App n _ -> n == goalFun
                  _       -> False
            if all validInter chain
              then do
                steps' <- mapM promoteStep chain
                let blk = EqChain start steps'
                    ki  = UnitEntry Nothing li (Just blk) (Just pos)
                addUnit ki
                return (Just (ki, [], σ0, []))
              else return Nothing
  where
    promoteStep (stepUe, dir, cur) = do
      nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
      case ueUnit stepUe of
        Eq a b   -> return (RwStep nm (a, b) dir, cur)
        Rel n as -> let relT = if null as then Const n else App n as
                    in return (RwStep nm (relT, Const "true") dir, cur)
        _        -> error "findElecIO: unexpected unit in Twee chain"

-- Recover the electron from a Twee equational chain: find the HaveHence electron
-- among the chain participants, then try single-step rewriting to match li.
recoverElecFromTweeChain
  :: Literal -> Subst
  -> [(UnitEntry, Dir, Term)]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
recoverElecFromTweeChain li σ0 chain = do
  let chainUes  = map (\(ue, _, _) -> ue) chain
      hhElecs   = filter isHH chainUes
      eqEntries = filter isEq chainUes
  matchViaRw li σ0 hhElecs eqEntries
  where
    isHH ue = case ueProof ue of { Just (HaveHence _) -> True; _ -> False }
    isEq ue = case ueUnit ue of { Eq _ _ -> True; _ -> False }

-- For each candidate electron, try (a) direct match and (b) single-step rewriting
-- with each available equation, checking if the result matches li.
-- Fallback for cases Twee cannot handle (e.g. non-terminating rewrite rules).
matchViaRw
  :: Literal -> Subst
  -> [UnitEntry]  -- candidate electrons (HaveHence or named)
  -> [UnitEntry]  -- candidate equation units
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
matchViaRw li σ0 srcElecs eqEntries = firstJustM tryElec srcElecs
  where
    firstJustM _ [] = return Nothing
    firstJustM f (x:xs) = f x >>= \case
      Just r  -> return (Just r)
      Nothing -> firstJustM f xs

    tryElec u = case tryMatch li (ueUnit u) σ0 of
      Just (σi, σ0') -> return (Just (u, σi, σ0', []))
      Nothing        -> firstJustM (tryRw u) eqEntries

    tryRw u eq
      | ueUnit u == ueUnit eq = return Nothing
    tryRw u eq = case ueUnit eq of
      Eq sa sb -> case listToMaybe
                    [ (dir, res, σi, σ0')
                    | dir <- [LR, RL]
                    , res <- rewriteLitAll (ueUnit u) (sa, sb) dir
                    , Just (σi, σ0') <- [tryMatch li res σ0] ] of
        Nothing -> return Nothing
        Just (dir, res, σi, σ0') -> do
          nm <- getEqName eq
          case nm of
            Nothing -> return Nothing
            Just n  -> return $ Just (u, σi, σ0', [(RwStep n (sa, sb) dir, applySubst σi res)])
      _ -> return Nothing

    getEqName eq = case ueName eq of
      Just n  -> return (Just n)
      Nothing -> case ueProof eq of
        Just _  -> Just <$> ensureNamed (ueUnit eq) (makeBlock eq [] [])
        Nothing -> return Nothing

-- rwSteps come from rwChain on the uninstantiated electron; σi applied to literals
-- so "hence p(a)" appears instead of "hence p(X)"
makeBlock :: UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
makeBlock ki σi rwSteps = do
  units <- gets stUnits
  base  <- buildBase units
  let rwStepsInst = map (second (applySubst σi)) rwSteps
  return (foldl applyRwLine base rwStepsInst)
  where
    lit = applySubst σi (ueUnit ki)

    buildBase units =
      let allUnnamed = filter (\u -> ueUnit u == ueUnit ki && isNothing (ueName u)) units
          hasHence (HaveHence ls) = any (\case Hence {} -> True; _ -> False) ls
          hasHence _              = False
          mBest = find (maybe False hasHence . ueProof) allUnnamed
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
                _ -> do
                  let genCands = filter (\u -> isNothing (ueName u)
                                           && isJust (ueProof u)
                                           && isJust (matchLit (ueUnit u) lit)) units
                  case genCands of
                    (genU : _) | Just σg <- matchLit (ueUnit genU) lit
                                , Just stored <- ueProof genU ->
                        if isEqChain stored
                          then do nm <- ensureNamed (ueUnit genU) (return stored)
                                  return (HaveHence [Have lit nm])
                          else return (applySubstBlock σg stored)
                    _ -> namedCase units
        Nothing -> namedCase units

    namedCase units =
      case find (\u -> ueUnit u == ueUnit ki) units of
        Just u ->
          case ueName u of
            Just nm -> return (HaveHence [Have lit nm])
            Nothing -> do
              -- unnamed unit with no stored proof: try to give it a name via Twee
              case ueUnit u of
                Eq l r -> do
                  let namedUs = filter (isJust . ueName) units
                  mBlk <- tweeChain l r namedUs
                  case mBlk of
                    Just blk -> do
                      nm <- ensureNamed (ueUnit u) (return blk)
                      return (HaveHence [Have lit nm])
                    Nothing -> do
                      liftIO $ hPutStrLn stderr $
                        "[warn] makeBlock: cannot prove unnamed eq unit: " ++ ppLitI (ueUnit ki)
                      return (EqChain l [])
                _ -> do
                  let namedUnits = filter (isJust . ueName) units
                      mNamed = listToMaybe
                        [ nm | nu <- namedUnits
                             , Just nm <- [ueName nu]
                             , Just _  <- [matchLit (ueUnit nu) lit] ]
                  case mNamed of
                    Just nm -> return (HaveHence [Have lit nm])
                    Nothing -> return (HaveHence [])
        Nothing -> do
          liftIO $ hPutStrLn stderr $
            "[warn] makeBlock: unit not in table: " ++ ppLitI (ueUnit ki)
          case ueUnit ki of
            Eq l _ -> return (EqChain l [])
            _      -> return (HaveHence [])

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
-- unit clause with no body: treat as direct assertion
buildProofBlock [] mAxName _σ0 headLit =
  return $ HaveHence $ case mAxName of
    Just ax -> [Have headLit ax]
    Nothing -> []
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

-- equational goals use EqChain built from the electron or Twee;
-- relational goals with a Twee chain also use EqChain (shows p(args) = ... = true);
-- otherwise relational goals use HaveHence.
-- rwi non-empty forces HaveHence so "hence … by rw" is preserved
emitBlockForGoal :: Literal -> UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
emitBlockForGoal _gl ki _σi []
  | isNothing (ueName ki)
  , Just blk@(EqChain {}) <- ueProof ki
  = return blk
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
          case mBlk of
            Just blk -> return blk
            Nothing  -> makeBlock ki σi []
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
    Nothing  -> do
      liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ") — could not convert to clause"
      return False
    Just cls ->
      let Clause bodyLits mHead = applyGroundingClause θ cls
      in do
        elecs   <- getElectrons pos
        mResult <- processBody bodyLits [] elecs simpl pos
        case mResult of
          Nothing -> do
            liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ")"
                ++ "  body=[" ++ intercalate ", " (map ppLitI bodyLits) ++ "] — no matching electron found"
            -- Goal-grounding fallback: if the head matches a goal lit,
            -- instantiate free variables and retry processBody.
            case mHead of
              -- Sibling-grounding fallback for NegConjecture: when the body lit
              -- has free variables, match against the sibling derived electron to
              -- ground them (e.g. V_U → c_1), then retry so that step-2.5 can
              -- find a rewriting match.
              Nothing -> case bodyLits of
                [singleLit] -> do
                  let sibPos = if not (null pos) && last pos == '1'
                               then Just (init pos ++ "0") else Nothing
                  case sibPos of
                    Nothing -> return False
                    Just sp -> do
                      allUnits <- gets stUnits
                      case listToMaybe [u | u <- allUnits, uePos u == Just sp] of
                        Nothing  -> return False
                        Just sib -> case matchLit singleLit (ueUnit sib) of
                          Nothing    -> return False
                          Just σ_sib -> do
                            let bodyLitsG = [applySubst σ_sib singleLit]
                            mResult2 <- processBody bodyLitsG [] elecs simpl pos
                            case mResult2 of
                              Nothing -> return False
                              Just (σ0, matched) -> do
                                let pairs = zip goalLits matched
                                if null pairs then return False
                                else do
                                  forM_ pairs $ \(gl, (ki, σi, rwi)) -> do
                                    let gl' = applySubst σ_sib (applySubst σ0 gl)
                                    blk <- emitBlockForGoal gl' ki σi rwi
                                    emitGoalProof gl' blk
                                  return True
                _ -> return False
              Just hl ->
                case listToMaybe [σ | gl <- goalLits, Just σ <- [matchLit hl gl]] of
                  Nothing   -> return False
                  Just σ_gl -> do
                    let bodyLitsG = map (applySubst σ_gl) bodyLits
                        headLitG  = applySubst σ_gl hl
                    mResult2 <- processBody bodyLitsG [] elecs simpl pos
                    -- processBody is greedy (no backtracking), so if the normal order
                    -- fails, retry with reversed body literals. This matters for
                    -- multi-body Horn clauses where the first literal's named-axiom
                    -- match commits to the wrong grounding (e.g. axiom 4 in GRP001-5/E:
                    -- normal order matches axiom 2 for lit 1 but then lit 3 = goal;
                    -- reversed order matches axiom 2 for lit 3 → axiom 3 → c_0_21).
                    mResult2R <- case mResult2 of
                      Just _  -> return mResult2
                      Nothing -> processBody (reverse bodyLitsG) [] elecs simpl pos
                    case mResult2R of
                      Nothing -> return False
                      Just (σ0, matched) -> do
                        blk <- buildProofBlock matched mAxName σ0 headLitG
                        let headInst = applySubst σ0 headLitG
                        when (isJust mAxName) $ do
                          addUnit (UnitEntry Nothing headInst (Just blk) (Just pos))
                          case blk of
                            EqChain {} -> void (ensureNamed headInst (return blk))
                            _ -> return ()
                        -- For derived inner nuclei (no axiom name): if the head is a
                        -- goal literal, emit the goal proof directly using "axioms"
                        -- as the fallback justification (e.g. E's inline spm steps).
                        -- For named axioms: emit the goal proof with the proper axiom name.
                        case (mAxName, listToMaybe [gl | gl <- goalLits, isJust (matchLit headInst gl)]) of
                          (Nothing, Just gl) -> do
                            blkFull <- buildProofBlock matched (Just "axioms") σ0 headLitG
                            emitGoalProof gl blkFull
                            return True
                          (Just _, Just gl) -> do
                            emitGoalProof gl blk
                            return True
                          _ -> return False
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
                    let pairs     = zip goalLits matched
                        unmatched = drop (length matched) goalLits
                    if null pairs
                      then return False
                      else do
                        forM_ pairs $ \(gl, (ki, σi, rwi)) -> do
                          let gl' = applySubst σ0 gl
                          blk <- emitBlockForGoal gl' ki σi rwi
                          emitGoalProof gl' blk
                        forM_ unmatched $ \gl -> do
                          liftIO $ hPutStrLn stderr $
                            "[warn] processOneNonUnit: unmatched goal lit: " ++ ppLitI (applySubst σ0 gl)
                          emitGoalProof (applySubst σ0 gl) (HaveHence [])
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
                    _ -> return ()
                -- Extra goal-grounding attempt: the natural electron match may produce a
                -- unit that shares the head shape with a goal but with different ground
                -- terms (e.g. axiom 11 matches k≤f and emits 0≤f-k, while the goal is
                -- 0≤f-g).  If the head also matches a goal literal under a *different*
                -- grounding σ_gl, retry processBody with the goal-grounded body so that
                -- the goal unit gets stored too.
                when (isJust mAxName) $ do
                  elecs2 <- getElectrons pos
                  let altGoalPairs = [ (σ, gl) | gl <- goalLits
                                                , not (isEqLit gl)
                                                , Just σ <- [matchLit headLit gl]
                                                , applySubst σ headLit /= headInst ]
                  case altGoalPairs of
                    [] -> return ()
                    ((σ_gl, _) : _) -> do
                      let bodyLitsG = map (applySubst σ_gl) bodyLits
                          headLitG  = applySubst σ_gl headLit
                      mResult2 <- processBody bodyLitsG [] elecs2 simpl pos
                      -- processBody is greedy (no backtracking); if normal order fails,
                      -- retry with reversed body literals. This fixes cases where the
                      -- first body literal commits to a wrong grounding (e.g. axiom 4
                      -- in GRP001-5/E: normal order matches axiom 2 for lit 1, binding
                      -- X1=b which makes lit 3 the goal itself; reversed order matches
                      -- axiom 2 for lit 3 giving X1=c, then axiom 3 and c_0_21 close).
                      mResult2R <- case mResult2 of
                        Just _  -> return mResult2
                        Nothing -> processBody (reverse bodyLitsG) [] elecs2 simpl pos
                      case mResult2R of
                        Nothing -> return ()
                        Just (σ0', matched') -> do
                          blk2 <- buildProofBlock matched' mAxName σ0' headLitG
                          let headInst2 = applySubst σ0' headLitG
                          addUnit (UnitEntry Nothing headInst2 (Just blk2) (Just pos))
                          case blk2 of
                            EqChain {} -> void (ensureNamed headInst2 (return blk2))
                            _ -> return ()
                          -- If the grounded head matches the goal, emit the proof now
                          -- so pass-2 (innerNusNG) cannot overwrite it with "by axioms".
                          case listToMaybe [gl' | gl' <- goalLits
                                               , isJust (matchLit headInst2 gl')] of
                            Just gl' -> emitGoalProof gl' blk2
                            Nothing  -> return ()
                -- For derived inner non-units (mAxName=Nothing): if the head shape
                -- matches a goal under a different grounding, retry processBody with
                -- goal-grounded body so that step-2 findElecIO can find unnamed ground
                -- electrons (e.g. E's inline spm steps like c_0_16 in GRP001-5).
                -- This only fires in the second pass (innerNusNG), so named axiom
                -- paths always get priority.
                if isNothing mAxName
                  then do
                    elecs3 <- getElectrons pos
                    let altGoals = [ (σ_gl, gl)
                                   | gl <- goalLits
                                   , not (isEqLit gl)
                                   , Just σ_gl <- [matchLit headLit gl]
                                   , applySubst σ_gl headLit /= headInst ]
                    case altGoals of
                      [] -> return False
                      ((σ_gl, gl) : _) -> do
                        let bodyLitsG3 = map (applySubst σ_gl) bodyLits
                            headLitG3  = applySubst σ_gl headLit
                        mGoalResult <- processBody bodyLitsG3 [] elecs3 simpl pos
                        case mGoalResult of
                          Nothing -> return False
                          Just (σ0', matched2) -> do
                            blkFull <- buildProofBlock matched2 (Just "axioms") σ0' headLitG3
                            emitGoalProof gl blkFull
                            return True
                  else return False

processNonUnits
  :: Bool  -- debug
  -> Bool  -- warnOnFail: emit warning if nuclei remain unprocessed after all retries
  -> Subst
  -> [LeafEntry]
  -> Map.Map String String
  -> [Literal]
  -> Map.Map String [(String, Dir)]
  -> AlgM ()
processNonUnits debug warnOnFail θ nonUnits posToName goalLits simpl = go nonUnits
  where
    nGoals = length goalLits

    go [] = return ()
    go pending = do
      nDone <- gets (length . stGoals)
      when (nDone < nGoals) $ do
        prevCount <- gets (length . stUnits)
        failed    <- processPass pending
        newCount  <- gets (length . stUnits)
        nDone2    <- gets (length . stGoals)
        -- Retry only if new units were derived and the goal is still unproved.
        -- This handles Vampire FOF proofs where axiom leaves appear at deeper
        -- positions than refutation-chain inner nodes (string-sort ordering
        -- puts inner nodes first, but axioms may depend on each other).
        if newCount > prevCount && nDone2 < nGoals && not (null failed)
          then go failed
          else when (warnOnFail && not (null failed) && nDone2 < nGoals) $
            liftIO $ hPutStrLn stderr $
              "[warn] processNonUnits: " ++ show (length failed)
              ++ " nucleus/nuclei could not be processed"

    processPass [] = return []
    processPass (entry : rest) = do
      nDone <- gets (length . stGoals)
      if nDone >= nGoals
        then return []
        else do
          prevCount <- gets (length . stUnits)
          done      <- processOneNonUnit debug θ entry posToName goalLits simpl
          newCount  <- gets (length . stUnits)
          if done
            then return []
            else do
              restFailed <- processPass rest
              return (if newCount > prevCount then restFailed else entry : restFailed)

findUnitForGoal :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Literal)
findUnitForGoal goal units = listToMaybe $
  [ (ue, ρ0, goal)
  | ue <- units, Just ρ0 <- [matchLit (ueUnit ue) goal] ]
  ++
  [ (ue, [], applySubst ρ0 goal)
  | ue <- units, Just ρ0 <- [matchLit goal (ueUnit ue)] ]
  ++
  -- bidirectional via tryMatch: handles free goal variables (e.g. from negated conjecture)
  -- Only tried when one-way matching in both directions has already failed.
  [ (ue, σi, applySubst σ0 goal)
  | ue <- units
  , isNothing (matchLit (ueUnit ue) goal)
  , isNothing (matchLit goal (ueUnit ue))
  , Just (σi, σ0) <- [tryMatch goal (ueUnit ue) []]
  ]

-- reconstruct an equational proof from the demod chain at p_{G₁}
splitChain :: Term -> Term -> [(String, Dir)] -> [UnitEntry] -> ([(RwStep, Term)], [String])
splitChain l r chain units =
    let result = if curL == curR then reverse leftSteps ++ reverseRight (reverse rightSteps) else []
    in (result, dropped)
  where
    (leftSteps, rightSteps, curL, curR, dropped) = foldl step ([], [], l, r, []) (reverse chain)

    step (ls, rs, accL, accR, drp) (nm, dir) =
      case findEqByName nm units of
        Nothing     -> (ls, rs, accL, accR, nm : drp)
        Just (a, b) ->
          case rewriteTerm accL (a, b) dir of
            Just accL' -> ((RwStep nm (a, b) dir, accL') : ls, rs, accL', accR, drp)
            Nothing    ->
              case rewriteTerm accR (a, b) dir of
                Just accR' -> (ls, (RwStep nm (a, b) dir, accR') : rs, accL, accR', drp)
                Nothing    -> (ls, rs, accL, accR, nm : drp)

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
      (chainSteps, _) <- case mChain of
            Just chain -> do
              let (steps, dropped) = splitChain l r chain units
              mapM_ (\nm -> liftIO $ hPutStrLn stderr $
                "[warn] splitChain: step not found in units: " ++ nm) dropped
              return (steps, dropped)
            Nothing    -> return ([], [])
      if not (null chainSteps)
        then emitGoalProof goal (EqChain l chainSteps)
        else do
          us <- gets stUnits
          let mDerivedUnit = listToMaybe
                [ u | u <- us
                    , isNothing (ueName u)
                    , isJust (tryMatch goal (ueUnit u) [])
                    , Just (HaveHence {}) <- [ueProof u] ]
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
  let innerClauses  = mapMaybe (convertDeclToClause . leDecl)
                        (filter (\e -> leRole e == Derived) nonUnits)
      innerLits     = concatMap (\(Clause bs mh) -> bs ++ catMaybes [mh]) innerClauses
      innerFreeVars = nub $ concatMap litVars innerLits
      trueFreeVars  = filter (`Set.notMember` leafVars) innerFreeVars
      goalConsts    = nub $ concatMap litConsts goalLits
      groundTerm    = case goalConsts of { (c:_) -> Const c; [] -> Const "c_ground" }
  in [(v, groundTerm) | v <- trueFreeVars]

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

runAlgorithm
  :: Bool
  -> ProofInfo
  -> [T.Unit]
  -> Map.Map String (Literal, ProofBlock)  -- tstp_name → pre-built lemma
  -> IO StructuredProof
runAlgorithm debug info allUnits candLemmaMap = do
  let unitMap    = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      goalLits'  = map convertLit (piGoalLits info)

      (rawAxiomList, posToName, namedUnits) =
        assignAxiomNames (piElectrons info) (piNonUnits info) unitMap

      -- Axioms that are actually pre-built lemmas get their names here
      candAxiomNames = Set.fromList
        [ nm
        | e <- piElectrons info
        , leRole e == OrigAxiom
        , Map.member (leName e) candLemmaMap
        , Just nm <- [Map.lookup (lePos e) posToName]
        ]
      -- Real axioms (not candidates)
      axiomList = filter (\case
          AUnit nm _    -> nm `Set.notMember` candAxiomNames
          ANonUnit nm _ -> nm `Set.notMember` candAxiomNames
        ) rawAxiomList
      -- Pre-lemma entries in proof-tree order
      preLemmaEntries =
        [ (axNm, lit, blk)
        | e <- piElectrons info
        , leRole e == OrigAxiom
        , Just (lit, blk) <- [Map.lookup (leName e) candLemmaMap]
        , Just axNm <- [Map.lookup (lePos e) posToName]
        ]

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
        [ UnitEntry Nothing lit mProof (Just (lePos e))
        | e <- filter (\e -> leRole e == Derived) (piElectrons info)
        , let lit    = electronLit unitMap e
              mProof = fmap snd (Map.lookup (leName e) candLemmaMap)
        , lit `notElem` goalLits' ]

      -- Equational axioms from the TSTP file not visible as proof-tree leaves.
      -- Twee proofs often bury the original axioms inside rewriting chains, so
      -- they never appear as leaves and are absent from namedUnits.  We add them
      -- here so that callTwee has background axioms to work with.
      -- For Vampire/E proofs this is unnecessary (unused axioms were genuinely
      -- not needed) and can make Twee subprocesses very heavy, so we skip it.
      isTweeProof = any isTweeUnit allUnits
        where
          isTweeUnit (T.Unit _ _ (Just (T.Inference (T.Atom rule) _ _, _))) =
            rule `elem` map Text.pack ["rewriting", "proved_conjecture"]
          isTweeUnit _ = False
      proofTreeAxNames = Set.fromList
        [ leName e | e <- piElectrons info ++ piNonUnits info
                   , leRole e == OrigAxiom ]
      bgEqPairs = if not isTweeProof then [] else
        nubBy (\(_, l1) (_, l2) -> l1 == l2)
        [ (unitNameStr n, clit)
        | u@(T.Unit n decl _) <- allUnits
        , isOrigAxiomDecl decl
        , not (isDerivedUnit u)
        , unitNameStr n `Set.notMember` proofTreeAxNames
        -- only pure positive-unit clauses: nuclei like (comp(X,Y) → meet(X,Y)=zero)
        -- must be excluded because headLitOf strips the body, creating unsound axioms
        , case convertDeclToClause decl of
            Just (Clause [] (Just _)) -> True
            _                         -> False
        , Just lit <- [headLitOf decl]
        , let clit = convertLit lit
        , isEqLit clit
        ]
      nBgBase = length axiomList
      bgAxiomList  = [ AUnit ("axiom " ++ show (nBgBase + i)) lit
                     | (i, (_, lit)) <- zip [1..] bgEqPairs ]
      bgNamedUnits = [ UnitEntry (Just ("axiom " ++ show (nBgBase + i))) lit Nothing Nothing
                     | (i, (_, lit)) <- zip [1..] bgEqPairs ]

      -- variables from file-sourced axioms are legitimately universally quantified
      leafVars = Set.fromList $
        concatMap (litVars . electronLit unitMap)
          (filter (\e -> leRole e == OrigAxiom) (piElectrons info))
        ++
        concatMap (maybe [] clauseVars . convertDeclToClause . leDecl)
          (filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNonUnits info))
        where clauseVars (Clause bs mh) = concatMap litVars (bs ++ catMaybes [mh])

      θ = buildGroundingSubst goalLits' leafVars (piNonUnits info)

      -- derived clauses with L0=⊥ are skipped: they'd intercept goal emission
      hasGroundHead e = case convertDeclToClause (leDecl e) of
        Just (Clause _ (Just hl)) -> null (litVars (applySubst θ hl))
        _                         -> False
      -- inner non-units with positive heads but non-ground vars (e.g. derived Horn
      -- clauses from E's inline inference steps like spm(A,B) inside sr(...))
      hasPositiveHead e = case convertDeclToClause (leDecl e) of
        Just (Clause _ (Just _)) -> True
        _                         -> False
      leafNonUnits  = filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNonUnits info)
      innerNus      = filter (\e -> leRole e == Derived && hasGroundHead e) (piNonUnits info)
      innerNusNG    = filter (\e -> leRole e == Derived && hasPositiveHead e
                                    && not (hasGroundHead e)) (piNonUnits info)
      allNonUnits   = sortBy (comparing lePos) (leafNonUnits ++ innerNus)

      nAll = length axiomList + length bgAxiomList
      goalVarSet = Set.fromList (concatMap litVars goalLits')
      initSt = AlgState
        { stUnits    = namedUnits ++ derivedUnits ++ bgNamedUnits
        , stLemmas   = preLemmaEntries
        , stGoals    = []
        , stCounter  = nAll + 1
        , stGoalVars = goalVarSet
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
    unless (null θ) $ do
      dbg debug ""
      dbg debug $ "θ: " ++ intercalate ", " [v ++ " → " ++ ppTerm t | (v, t) <- θ]
    forM_ pG1Chain $ \chain -> do
      dbg debug ""
      dbg debug $ "pG1: " ++ ppSimplChain chain
    dbg debug ""

  finalSt <- execStateT (action θ allNonUnits innerNusNG posToName goalLits' simpl pG1Chain) initSt
  if null (stGoals finalSt)
    then do
      hPutStrLn stderr "translate: no goal proof produced"
      return (StructuredProof (axiomList ++ bgAxiomList) (stLemmas finalSt) [])
    else return (StructuredProof (axiomList ++ bgAxiomList) (stLemmas finalSt) (stGoals finalSt))
  where
    action θ allNonUnits innerNusNG posToName goalLits simpl pG1Chain = do
      -- First pass: leaf axioms + ground-head derived non-units.
      processNonUnits debug False θ allNonUnits posToName goalLits simpl
      nDone <- gets (length . stGoals)
      -- Second pass: derived non-ground-head Horn nuclei (e.g. E's inline spm steps).
      -- Only tried when the first pass (leaf + ground-head non-units) failed to prove
      -- the goal, so named axiom paths always get priority.
      when (nDone < length goalLits) $
        processNonUnits debug False θ innerNusNG posToName goalLits simpl
      nDone2 <- gets (length . stGoals)
      when (nDone2 < length goalLits) $ do
        proven <- gets (map fst . stGoals)
        let unproven = filter (`notElem` proven) goalLits
        mapM_ (proveGoal pG1Chain) unproven
      nDone3 <- gets (length . stGoals)
      when (nDone3 < length goalLits) $
        liftIO $ hPutStrLn stderr "[warn] processNonUnits: goal(s) could not be proved"

