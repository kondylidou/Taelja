module Translator where

import qualified Data.TPTP as T
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import Data.Sequence (Seq, (|>))
import Data.Foldable (toList) -- explicit: Map.toList in scope prevents Prelude resolution
import Control.Monad (foldM, forM_, void, when)
import Debug.Trace (traceM)
import Control.Monad.State.Strict
import Data.List (nub)
import Data.Maybe (fromMaybe, isJust, isNothing)

import Types
import Helpers
import Converter

-- The unit map mirrors the sequence so lookups in ensureNamed and addToUnits
-- are O(log n) rather than a linear scan.
-- tsUnits is a Seq so snoc (append-at-end) is O(log n) rather than O(n).
data TransState = TransState
  { tsUnits      :: Seq UnitEntry
  , tsUnitMap    :: Map.Map Literal UnitEntry
  , tsLemmaCount :: Int
  , tsLemmas     :: [(String, Literal, ProofBlock)]
  , tsDebug      :: Bool
  }

type TransM a = State TransState a

whenDebug :: String -> TransM ()
whenDebug msg = do
  d <- gets tsDebug
  when d (traceM msg)

-- Entry point: classify the TSTP axioms, then prove each goal in order.
translate :: Bool -> T.TSTP -> StructuredProof
translate debug (T.TSTP _ units) =
  let (axEntries, initUnitEntries, axNonUnits, goalLits) = classifyAxioms units
      initState = TransState
        { tsUnits      = Seq.fromList initUnitEntries
        , tsUnitMap    = Map.fromList [(ueUnit ue, ue) | ue <- initUnitEntries]
        , tsLemmaCount = length axEntries
        , tsLemmas     = []
        , tsDebug      = debug
        }
      (goalBlocks, finalState) = runState (mapM (proveGoal axNonUnits) goalLits) initState
  in StructuredProof
       { axioms = axEntries
       , lemmas = reverse (tsLemmas finalState)
       , goals  = zip goalLits goalBlocks
       }

proveGoal :: [(String, Clause)] -> Literal -> TransM ProofBlock
proveGoal []       goalLit = proveFromUnits goalLit
proveGoal nonUnits goalLit = proveWithNonUnits nonUnits goalLit

proveFromUnits :: Literal -> TransM ProofBlock
proveFromUnits goal = case goal of
  Eq s t -> do
    steps <- rwChainTo s t
    return (EqChain s steps)
  _ -> do
    units <- gets (toList . tsUnits)
    case findMatchingUnit goal units of
      Just (ue, subst, rws) -> do
        block <- makeBlock ue rws
        return (applySubstBlock subst block)
      Nothing -> do
        unitList <- gets (map (show . ueUnit) . toList . tsUnits)
        error ("cannot discharge goal " ++ show goal
               ++ "\n  units in set: " ++ show unitList)

-- Process non-unit clauses in Waldmann's position ordering (Lemma 0.6):
-- a single ordered pass suffices because when we reach clause C, all units
-- its body requires have already been derived by earlier clauses.
-- If the pass stalls, name all anonymous equations and retry once; if that
-- also fails, fall back to pure unit-based proof search.
proveWithNonUnits :: [(String, Clause)] -> Literal -> TransM ProofBlock
proveWithNonUnits nonUnits goalLit = do
  before <- gets (Map.size . tsUnitMap)
  whenDebug ("[pass] goal=" ++ show goalLit ++ " units=" ++ show before
             ++ " clauses=" ++ show (length nonUnits))
  mBlock <- onePass nonUnits
  case mBlock of
    Just block -> do
      whenDebug "[pass] goal proved"
      return block
    Nothing -> do
      whenDebug "[pass] stalled, forcing equation names and retrying"
      ensureAllEqNamed
      mBlock2 <- onePass nonUnits
      case mBlock2 of
        Just block -> return block
        Nothing    -> proveFromUnits goalLit
  where
    -- After each clause adds a new unit, scan all clauses for DAG sharing:
    -- if the new unit would be the first body literal of ≥2 clauses, pre-name
    -- it so they all cite the same lemma. We scan all nonUnits (not just the
    -- remaining ones) so that sharing is detected regardless of processing order.
    onePass []              = return Nothing
    onePass ((n, c) : rest) = do
      szBefore <- gets (Map.size . tsUnitMap)
      mBlock <- processNonUnit n c goalLit
      case mBlock of
        Just block -> return (Just block)
        Nothing    -> do
          szAfter <- gets (Map.size . tsUnitMap)
          when (szAfter > szBefore) (preScanShared nonUnits)
          onePass rest

-- Before processing each round, detect unnamed units that would match the first
-- body literal of ≥2 different non-unit clauses. Those units sit at DAG merge
-- points: multiple derivation paths share the same intermediate result. Pre-naming
-- them avoids duplicating the derivation in each consumer's proof block.
preScanShared :: [(String, Clause)] -> TransM ()
preScanShared nonUnits = do
  units <- gets (toList . tsUnits)
  let firstLits = [(cn, l) | (cn, Clause (l:_) _) <- nonUnits]
      -- For each clause's first body literal, find which unnamed unit matches it.
      matches = [ (cn, ueUnit (bmEntry bm))
                | (cn, lit) <- firstLits
                , Just bm  <- [bodyLitMatch lit units]
                , isNothing (ueName (bmEntry bm))
                ]
      grouped = Map.fromListWith (++) [(unitLit, [cn]) | (cn, unitLit) <- matches]
      shared  = [lit | (lit, cns) <- Map.toList grouped, length (nub cns) >= 2]
  forM_ shared $ \lit -> do
    m <- gets tsUnitMap
    case Map.lookup lit m of
      Just ue | isNothing (ueName ue), isJust (ueDeriv ue) -> do
        whenDebug ("  [preScanShared] pre-naming shared unit: " ++ show lit)
        void (ensureNamed lit)
      _ -> return ()

-- When the fixpoint stalls, names every unnamed equation so BFS can see it.
-- This can emit lemmas for equations that turn out not to matter, but that
-- is better than failing to find a proof that exists.
ensureAllEqNamed :: TransM ()
ensureAllEqNamed = do
  whenDebug "[ensureAllEqNamed] naming all anonymous equations for BFS"
  units <- gets tsUnits
  forM_ units $ \ue -> case ueUnit ue of
    Eq _ _ -> void (ensureNamed (ueUnit ue))
    _      -> return ()

-- Top-down first: match the head to the goal and prove the body under that substitution.
-- If that fails (head doesn't match or body cannot be proved), try bottom-up instead.
processNonUnit :: String -> Clause -> Literal -> TransM (Maybe ProofBlock)
processNonUnit clauseName (Clause bodyLits mHead) goalLit = do
  let headLit = fromMaybe (error "processNonUnit: unit clause") mHead
  case matchLit headLit goalLit of
    Just σHead -> do
      whenDebug ("  [" ++ clauseName ++ "] top-down: head matches goal, proving body")
      let targets = map (applySubst σHead) bodyLits
      -- Name tail body literals now so their derivations are ready when we cite them.
      case targets of { _ : _ : _ -> prelemmatize clauseName (tail targets); _ -> return () }
      mResult <- processBody σHead bodyLits
      case mResult of
        Nothing         -> do
          whenDebug ("  [" ++ clauseName ++ "] top-down: body failed, falling back to bottom-up")
          nonUnitBottomUp clauseName bodyLits headLit goalLit
        Just (block, _) -> do
          whenDebug ("  [" ++ clauseName ++ "] top-down: succeeded")
          return (Just (appendLine block (Hence goalLit (ByAxiom clauseName))))
    Nothing -> do
      whenDebug ("  [" ++ clauseName ++ "] top-down: head does not match goal, trying bottom-up")
      nonUnitBottomUp clauseName bodyLits headLit goalLit

-- Proves the body first, then derives the grounded head and tries to connect it
-- to the goal via matching or rewriting. If it still cannot reach the goal, stores
-- the grounded head as a new unit for the next fixpoint round.
-- Free unit variables (uppercase-initial) get instantiated over the goal's ground
-- subterms. This works because freshenClause always c-prefixes clause variables,
-- so isUpper reliably distinguishes unit vars from clause vars.
nonUnitBottomUp :: String -> [Literal] -> Literal -> Literal -> TransM (Maybe ProofBlock)
nonUnitBottomUp clauseName bodyLits headLit goalLit = do
  mResult <- processBody [] bodyLits
  case mResult of
    Nothing -> do
      whenDebug ("  [" ++ clauseName ++ "] bottom-up: body failed")
      return Nothing
    Just (block, σFinal) -> do
      let groundH = applySubst σFinal headLit
          block'  = appendLine block (Hence groundH (ByAxiom clauseName))
      case matchLit groundH goalLit of
        Just σ' -> do
          whenDebug ("  [" ++ clauseName ++ "] bottom-up: derived " ++ show groundH ++ " matches goal directly")
          return (Just (applySubstBlock σ' block'))
        Nothing -> do
          units' <- gets (toList . tsUnits)
          case tryRwPath groundH goalLit units' of
            Just (rwPath, σRw) -> do
              whenDebug ("  [" ++ clauseName ++ "] bottom-up: derived " ++ show groundH ++ " reaches goal via rewriting")
              blk <- extendWithRw block' rwPath
              return (Just (applySubstBlock σRw blk))
            Nothing -> do
              whenDebug ("  [" ++ clauseName ++ "] bottom-up: derived " ++ show groundH ++ ", stored as new unit")
              addToUnits (UnitEntry Nothing groundH (Just block'))
              return Nothing

processBody :: Subst -> [Literal] -> TransM (Maybe (ProofBlock, Subst))
processBody _ [] = error "processBody: empty body"
processBody σ0 (l1 : rest) = do
  units <- gets (toList . tsUnits)
  let target1 = applySubst σ0 l1
  case bodyLitMatch target1 units of
    Nothing -> return Nothing
    Just (BodyMatch ue1 blkSubst1 rws1 clauseUpd1) -> do
      let σ1 = σ0 ++ clauseUpd1
      blk1 <- makeBlock ue1 rws1
      let ls1 = case applySubstBlock blkSubst1 blk1 of
                  HaveHence ls -> ls
                  EqChain {}   -> error "processBody: initial block is EqChain"
      result <- foldM foldBodyLit (Just (reverse ls1, σ1)) rest
      return $ fmap (\(revLs, σ) -> (HaveHence (reverse revLs), σ)) result

-- Accumulator for the body fold: tries to match the next literal under the
-- current substitution and appends an And-line to the reversed line list.
foldBodyLit :: Maybe ([ProofLine], Subst) -> Literal -> TransM (Maybe ([ProofLine], Subst))
foldBodyLit Nothing _ = return Nothing
foldBodyLit (Just (revLs, σ)) lit = do
  let target = applySubst σ lit
  units <- gets (toList . tsUnits)
  case bodyLitMatch target units of
    Nothing -> do
      whenDebug ("    body literal no match: " ++ show target)
      return Nothing
    Just (BodyMatch ue _blkSubst rws clauseUpd) -> do
      let σ'         = σ ++ clauseUpd
          displayLit = applySubst clauseUpd target
      if null rws && null clauseUpd
        then do
          name <- ensureNamed (ueUnit ue)
          return (Just (And displayLit name : revLs, σ'))
        else do
          blk <- makeBlock ue rws
          -- Store the generic (pre-instantiation) form so lemmas are non-ground.
          -- When rws is non-empty, the last rewrite result is the generic literal
          -- with unit vars (uppercase) still free. When rws is empty but clauseUpd
          -- is non-null, the unit itself is the generic form.
          let genericLit | null rws  = ueUnit ue
                         | otherwise = snd (last rws)
          addToUnits (UnitEntry Nothing genericLit (Just blk))
          name <- ensureNamed genericLit
          return (Just (And displayLit name : revLs, σ'))

-- If the rewrite path ends at a non-ground equation, give it its own lemma
-- rather than inlining all the steps. The emitter renders it as an EqChain.
makeBlock :: UnitEntry -> [(RwStep, Literal)] -> TransM ProofBlock
makeBlock ue rwPath = case finalNonGroundEq rwPath of
  Just (finalLit, l, r) -> do
    m <- gets tsUnitMap
    case Map.lookup finalLit m of
      Nothing -> do
        units <- gets (toList . tsUnits)
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
        -- Cannot inline an EqChain, so name it and reference it with a single Have line.
        Just (EqChain {})   -> do
          nm <- ensureNamed (ueUnit ue)
          return [Have (ueUnit ue) nm]
        Nothing ->
          return [Have (ueUnit ue)
                    (fromMaybe (error "makeBlock: unnamed unit has no derivation")
                               (ueName ue))]
      rwLines <- mapM stepToLine rwPath
      return (HaveHence (baseLines ++ rwLines))
    finalNonGroundEq []    = Nothing
    finalNonGroundEq steps = case snd (last steps) of
      lit@(Eq l r) | not (null (litVars lit)) -> Just (lit, l, r)
      _                                        -> Nothing
    stepToLine (RwStep _ (origL, origR) dir, nextLit) = do
      nm' <- ensureNamed (Eq origL origR)
      return (Hence nextLit (ByRw nm' (dirAnnotation dir)))

rwChainTo :: Term -> Term -> TransM [(RwStep, Term)]
rwChainTo s t = do
  units <- gets (toList . tsUnits)
  case findPath units s t of
    Nothing   -> do
      let eqs = map (\(n,l,r) -> n ++ ": " ++ show l ++ "=" ++ show r) (eqUnits units)
      error ("no equational chain from " ++ show s ++ " to " ++ show t
             ++ "\n  available equations: " ++ show eqs)
    Just path -> return path

-- LR is the default direction so needs no annotation; only RL is marked explicitly.
dirAnnotation :: Dir -> Maybe Dir
dirAnnotation RL = Just RL
dirAnnotation LR = Nothing

extendWithRw :: ProofBlock -> [(RwStep, Literal)] -> TransM ProofBlock
extendWithRw = foldM step
  where
    step blk (RwStep _ (origL, origR) dir, nextLit) = do
      nm <- ensureNamed (Eq origL origR)
      return (appendLine blk (Hence nextLit (ByRw nm (dirAnnotation dir))))

-- Names unnamed units that exactly match a tail body literal before we start,
-- so the same derivation does not end up inlined in multiple places.
-- Uses Map.lookup (O(log n)) rather than BFS since only exact matches qualify.
-- Skips units derived from the current clause to avoid circular references.
prelemmatize :: String -> [Literal] -> TransM ()
prelemmatize currentClause = mapM_ go
  where
    go t = do
      m <- gets tsUnitMap
      let found = case Map.lookup t m of
                    Just ue -> Just ue
                    Nothing -> case t of
                      Eq a b -> Map.lookup (Eq b a) m
                      _      -> Nothing
      case found of
        Just ue
          | isNothing (ueName ue)
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
      whenDebug ("  [ensureNamed] " ++ name ++ ": " ++ show lit)
      recordLemma name lit stored
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

recordLemma :: String -> Literal -> ProofBlock -> TransM ()
recordLemma name lit block =
  modify $ \s -> s { tsLemmas = (name, lit, block) : tsLemmas s }

modifyUnit :: Literal -> UnitEntry -> TransM ()
modifyUnit lit new =
  modify $ \s -> s
    { tsUnits   = fmap (\u -> if ueUnit u == lit then new else u) (tsUnits s)
    , tsUnitMap = Map.insert lit new (tsUnitMap s)
    }

-- New derivations replace an existing unnamed entry when they are strictly shorter.
-- Named entries are never replaced: they may already be cited in emitted lemmas.
addToUnits :: UnitEntry -> TransM ()
addToUnits ue = do
  m <- gets tsUnitMap
  case Map.lookup (ueUnit ue) m of
    Nothing -> modify $ \s -> s
      { tsUnits   = tsUnits s |> ue
      , tsUnitMap = Map.insert (ueUnit ue) ue m
      }
    Just old
      | isNothing (ueName old)
      , Just newBlk <- ueDeriv ue
      , Just oldBlk <- ueDeriv old
      , blockSize newBlk < blockSize oldBlk -> do
          whenDebug ("  [addToUnits] shorter proof for " ++ show (ueUnit ue)
                     ++ " (" ++ show (blockSize oldBlk) ++ " -> " ++ show (blockSize newBlk) ++ ")")
          modifyUnit (ueUnit ue) ue
    Just _ -> return ()
