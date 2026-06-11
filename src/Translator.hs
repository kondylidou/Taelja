module Translator where

import qualified Data.TPTP as T
import Data.Char (isUpper)
import Data.List (nub, partition)
import qualified Data.Map.Strict as Map
import Control.Monad (foldM, forM_, void)
import Control.Monad.State
import Data.Maybe (fromMaybe, isJust, isNothing)

import Types
import Helpers
import Converter

-- tsUnitMap mirrors tsUnits for O(log n) point lookups (ensureNamed, addToUnits).
-- tsUnitCount lets the fixpoint check progress without traversing the whole list.
data TransState = TransState
  { tsUnits      :: [UnitEntry]
  , tsUnitMap    :: Map.Map Literal UnitEntry
  , tsUnitCount  :: Int
  , tsLemmaCount :: Int
  , tsLemmas     :: [(String, Literal, ProofBlock)]
  }

type TransM a = State TransState a

translate :: T.TSTP -> StructuredProof
translate (T.TSTP _ units) =
  let (axEntries, initUnitEntries, axNonUnits, goalLits) = classifyAxioms units
      initState = TransState
        { tsUnits      = initUnitEntries
        , tsUnitMap    = Map.fromList [(ueUnit ue, ue) | ue <- initUnitEntries]
        , tsUnitCount  = length initUnitEntries
        , tsLemmaCount = length axEntries
        , tsLemmas     = []
        }
      (goalBlocks, finalState) = runState (mapM (mainLoop axNonUnits) goalLits) initState
  in StructuredProof
       { axioms = axEntries
       , lemmas = reverse (tsLemmas finalState)
       , goals  = zip goalLits goalBlocks
       }

mainLoop :: [(String, Clause, Subst)] -> Literal -> TransM ProofBlock
mainLoop []       goalLit = translateNonUnitsEmpty goalLit
mainLoop nonUnits goalLit = translateNonUnits nonUnits goalLit

translateNonUnitsEmpty :: Literal -> TransM ProofBlock
translateNonUnitsEmpty goal = case goal of
  Eq s t -> do
    steps <- rwChainTo s t
    return (EqChain s steps)
  _ -> do
    units <- gets tsUnits
    case findMatchingUnit goal units of
      Just (ue, subst, rws) -> do
        block <- makeBlock ue rws
        return (applySubstBlock subst block)
      Nothing ->
        error ("translateNonUnitsEmpty: no unit matches goal: " ++ show goal)

-- Each round tries every clause; if at least one new unit was added we go
-- again because new units may unlock previously-unmatched body literals.
translateNonUnits :: [(String, Clause, Subst)] -> Literal -> TransM ProofBlock
translateNonUnits nonUnits goalLit = fixpoint
  where
    fixpoint = do
      before <- gets tsUnitCount
      mBlock <- oneRound nonUnits
      case mBlock of
        Just block -> return block
        Nothing    -> do
          after <- gets tsUnitCount
          if after > before
            then fixpoint
            else do
              ensureAllEqNamed
              mBlock2 <- oneRound nonUnits
              case mBlock2 of
                Just block -> return block
                Nothing    -> translateNonUnitsEmpty goalLit
    oneRound []               = return Nothing
    oneRound ((n, c, s) : rest) = do
      mBlock <- processNonUnit n c s goalLit
      case mBlock of
        Just block -> return (Just block)
        Nothing    -> oneRound rest

-- Last resort when the fixpoint stalls: name every unnamed equation so BFS
-- can see it. May emit lemmas for equations unrelated to the current goal.
ensureAllEqNamed :: TransM ()
ensureAllEqNamed = do
  units <- gets tsUnits
  forM_ units $ \ue -> case ueUnit ue of
    Eq _ _ -> void (ensureNamed (ueUnit ue))
    _      -> return ()

processNonUnit :: String -> Clause -> Subst -> Literal -> TransM (Maybe ProofBlock)
processNonUnit clauseName (Clause bodyLits mHead) σ0 goalLit = do
  let headLit = fromMaybe (error "processNonUnit: unit clause") mHead
  case matchLit headLit goalLit of
    Just σHead -> do
      let σ       = σ0 ++ σHead
          targets = map (applySubst σ) bodyLits
      -- pre-lemmatize tail literals so their derivations get names before we cite them
      case targets of { _ : _ : _ -> prelemmatize clauseName (tail targets); _ -> return () }
      mResult <- processBody σ bodyLits
      case mResult of
        Nothing         -> nonUnitBottomUp clauseName bodyLits σ0 headLit goalLit
        Just (block, _) -> return (Just (appendLine block (Hence goalLit (ByAxiom clauseName))))
    Nothing -> nonUnitBottomUp clauseName bodyLits σ0 headLit goalLit

-- Prove the body, derive the grounded head, then try to connect it to the goal.
-- If the head still has free unit variables (uppercase-initial), instantiate
-- them over the goal's ground subterms and store each instance for the next round.
-- The isUpper split works because freshenClause always c-prefixes clause variables.
nonUnitBottomUp :: String -> [Literal] -> Subst -> Literal -> Literal -> TransM (Maybe ProofBlock)
nonUnitBottomUp clauseName bodyLits σ0 headLit goalLit = do
  mResult <- processBody σ0 bodyLits
  case mResult of
    Nothing -> return Nothing
    Just (block, σFinal) -> do
      let groundH = applySubst σFinal headLit
          block'  = appendLine block (Hence groundH (ByAxiom clauseName))
      case matchLit groundH goalLit of
        Just σ' -> return (Just (applySubstBlock σ' block'))
        Nothing -> do
          units' <- gets tsUnits
          case tryRwPath groundH goalLit units' of
            Just (rwPath, σRw) -> do
              blk <- extendWithRw block' rwPath
              return (Just (applySubstBlock σRw blk))
            Nothing -> do
              let freeVs        = nub (litVars groundH)
                  (unitFree, _) = partition (isUpper . head) freeVs
              if null unitFree
                then addToUnits (UnitEntry Nothing groundH (Just block'))
                else forM_ (instantiations unitFree (groundSubtermsLit goalLit)) $ \σ -> do
                       let gh = applySubst σ groundH
                           bl = applySubstBlock σ block'
                       addToUnits (UnitEntry Nothing gh (Just bl))
              return Nothing

processBody :: Subst -> [Literal] -> TransM (Maybe (ProofBlock, Subst))
processBody _ [] = error "processBody: empty body"
processBody σ0 (l1 : rest) = do
  units <- gets tsUnits
  let target1 = applySubst σ0 l1
  case bodyLitMatch target1 units of
    Nothing -> return Nothing
    Just (BodyMatch ue1 blkSubst1 rws1 clauseUpd1) -> do
      let σ1 = σ0 ++ clauseUpd1
      blk1 <- makeBlock ue1 rws1
      foldM addAndLitAcc (Just (applySubstBlock blkSubst1 blk1, σ1)) rest

addAndLitAcc :: Maybe (ProofBlock, Subst) -> Literal -> TransM (Maybe (ProofBlock, Subst))
addAndLitAcc Nothing _ = return Nothing
addAndLitAcc (Just (block, σ)) lit = do
  let target = applySubst σ lit
  units <- gets tsUnits
  case bodyLitMatch target units of
    Nothing -> return Nothing
    Just (BodyMatch ue blkSubst rws clauseUpd) -> do
      let σ'         = σ ++ clauseUpd
          displayLit = applySubst clauseUpd target
      if null rws
        then do
          name <- ensureNamed (ueUnit ue)
          return (Just (appendLine block (And displayLit name), σ'))
        else do
          blk <- makeBlock ue rws
          addToUnits (UnitEntry Nothing displayLit (Just (applySubstBlock blkSubst blk)))
          name <- ensureNamed displayLit
          return (Just (appendLine block (And displayLit name), σ'))

-- If the rewrite path ends at a non-ground equation, promote it to an EqChain
-- lemma rather than inlining the steps — the emitter can render it more cleanly.
makeBlock :: UnitEntry -> [(RwStep, Literal)] -> TransM ProofBlock
makeBlock ue rwPath = case nonGroundEqEnd rwPath of
  Just (finalLit, l, r) -> do
    m <- gets tsUnitMap
    case Map.lookup finalLit m of
      Nothing -> do
        units <- gets tsUnits
        eqBlock <- case findPath units l r of
          Just path -> return (EqChain l path)
          Nothing   -> buildInline
        addToUnits (UnitEntry Nothing finalLit (Just eqBlock))
      Just _ -> return ()
    nm <- ensureNamed finalLit
    return (HaveHence [Have finalLit nm])
  Nothing -> buildInline
  where
    buildInline = do
      baseLines <- case ueDeriv ue of
        Just (HaveHence ls) -> return ls
        -- stored derivation is an EqChain: name it and reference it with a single Have
        Just (EqChain {})   -> do
          nm <- ensureNamed (ueUnit ue)
          return [Have (ueUnit ue) nm]
        Nothing ->
          return [Have (ueUnit ue)
                    (fromMaybe (error "makeBlock: unnamed unit has no derivation")
                               (ueName ue))]
      rwLines <- mapM stepToLine rwPath
      return (HaveHence (baseLines ++ rwLines))
    nonGroundEqEnd []    = Nothing
    nonGroundEqEnd steps = case snd (last steps) of
      lit@(Eq l r) | not (null (litVars lit)) -> Just (lit, l, r)
      _                                        -> Nothing
    stepToLine (RwStep _ (origL, origR) dir, nextLit) = do
      nm' <- ensureNamed (Eq origL origR)
      let justDir = if dir == RL then Just RL else Nothing
      return (Hence nextLit (ByRw nm' justDir))

rwChainTo :: Term -> Term -> TransM [(RwStep, Term)]
rwChainTo s t = do
  units <- gets tsUnits
  case findPath units s t of
    Nothing   -> error ("rwChainTo: no rewrite path from " ++ show s ++ " to " ++ show t)
    Just path -> return path

extendWithRw :: ProofBlock -> [(RwStep, Literal)] -> TransM ProofBlock
extendWithRw = foldM step
  where
    step blk (RwStep _ (origL, origR) dir, nextLit) = do
      nm <- ensureNamed (Eq origL origR)
      let justDir = if dir == RL then Just RL else Nothing
      return (appendLine blk (Hence nextLit (ByRw nm justDir)))

-- Pre-lemmatize unnamed units that exactly match a tail body literal so
-- the same derivation doesn't get inlined multiple times. Skip units derived
-- from the current clause to avoid circular references.
prelemmatize :: String -> [Literal] -> TransM ()
prelemmatize currentClause targets = do
  units <- gets tsUnits
  mapM_ (go units) targets
  where
    go units t = case findMatchingUnit t units of
      Just (ue, σUnit, rws)
        | null σUnit
        , null rws
        , isNothing (ueName ue)
        , isJust (ueDeriv ue)
        , not (derivedByClause currentClause ue) ->
            void (ensureNamed (ueUnit ue))
      _ -> return ()

ensureNamed :: Literal -> TransM String
ensureNamed lit = do
  m <- gets tsUnitMap
  case Map.lookup lit m of
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
  modify $ \s -> s
    { tsUnits   = replaceFirst (tsUnits s)
    , tsUnitMap = Map.insert lit new (tsUnitMap s)
    }
  where
    replaceFirst []     = []
    replaceFirst (u:us) = if ueUnit u == lit then new : us else u : replaceFirst us

-- First-write-wins: if a unit for this literal already exists we keep it,
-- even if the new derivation would be shorter.
addToUnits :: UnitEntry -> TransM ()
addToUnits ue = do
  m <- gets tsUnitMap
  case Map.lookup (ueUnit ue) m of
    Nothing -> modify $ \s -> s
      { tsUnits     = tsUnits s ++ [ue]
      , tsUnitMap   = Map.insert (ueUnit ue) ue m
      , tsUnitCount = tsUnitCount s + 1
      }
    Just _  -> return ()
