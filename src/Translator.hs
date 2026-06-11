module Translator where

import qualified Data.TPTP as T
import Data.Char (isUpper)
import Data.List (find, nub, partition)
import Data.List.NonEmpty (toList)
import qualified Data.Set        as Set
import qualified Data.Text as Text
import Control.Applicative ((<|>))
import Control.Monad (foldM, forM_, void)
import Control.Monad.State
import Data.Maybe (fromMaybe, isJust, isNothing, listToMaybe)

import Types

data TransState = TransState
  { tsUnits      :: [UnitEntry]
  , tsLemmaCount :: Int
  , tsLemmas     :: [(String, Literal, ProofBlock)]
  }

type TransM a = State TransState a

-- Result of matching a body literal against the units set.
data BodyMatch = BodyMatch
  { bmEntry     :: UnitEntry
  , bmUnitSubst :: Subst               -- σUnit: applied to the stored proof block
  , bmRewrites  :: [(RwStep, Literal)] -- rewrite path with intermediate literals
  , bmClauseUpd :: Subst               -- σClause: appended to the accumulated clause substitution
  }

translate :: T.TSTP -> StructuredProof
translate (T.TSTP _ units) =
  let (axEntries, initUnitEntries, axNonUnits, goalLits) = classifyAxioms units
      initState = TransState
        { tsUnits      = initUnitEntries
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

-- Equational goals produce an EqChain; relational goals match a unit directly.
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

findMatchingUnit :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, [(RwStep, Literal)])
findMatchingUnit goal units = listToMaybe
  [ (ue, subst, rws)
  | ue <- units
  , Just (subst, rws) <- [tryMatchLit (ueUnit ue) goal units]
  ]

-- Generic BFS over a rewrite space.
-- rwFn: enumerate all single-position rewrites (lhs rhs node -> [node'])
-- sizeFn: node size for pruning
-- eqs: named equalities (name, lhs, rhs)
-- check: returns Just r when a node satisfies the goal
-- start: initial node; bound: max allowed size of intermediates
-- Result: the first hit as (r, forward-path [(step, node-after-step)])
bfsRewrite :: Ord a
           => (Term -> Term -> a -> [a])
           -> (a -> Int)
           -> [(String, Term, Term)]
           -> (a -> Maybe r)
           -> a
           -> Int
           -> Maybe (r, [(RwStep, a)])
bfsRewrite rwFn sizeFn eqs check start bound =
    bfs [(start, [])] (Set.singleton start)
  where
    bfs [] _ = Nothing
    bfs frontier visited =
      case [hit | (cur, path) <- frontier, Just r <- [check cur]
                , let hit = (r, reverse path)] of
        hit : _ -> Just hit
        []      ->
          let candidates  = concatMap (step visited) frontier
              -- deduplicate while preserving first-seen order (same as old nubBy)
              frontier'   = dedupFst candidates
              visited'    = Set.union visited (Set.fromList (map fst frontier'))
          in bfs frontier' visited'
    -- Keep first occurrence for each key, preserving list order
    dedupFst xs = go xs Set.empty
      where
        go []            _    = []
        go ((k, v) : rest) seen
          | Set.member k seen = go rest seen
          | otherwise         = (k, v) : go rest (Set.insert k seen)
    step visited (cur, path) =
      [ (cur', (RwStep nm (origL, origR) dir, cur') : path)
      | (nm, origL, origR) <- eqs
      , (lhs, rhs, dir)    <- (origL, origR, LR)
                            : [(origR, origL, RL) | all (`elem` termVars origR) (termVars origL)]
      , cur'               <- rwFn lhs rhs cur
      , cur' /= cur
      , sizeFn cur' <= bound
      , Set.notMember cur' visited
      ]

-- All results of applying lhs→rhs at exactly one position in a term.
rewritePos :: Term -> Term -> Term -> [Term]
rewritePos lhs rhs t =
  [ applySubstTerm subst rhs | Just subst <- [matchTerm lhs t []] ]
  ++ case t of
       App f args ->
         [ App f (take i args ++ [t'] ++ drop (i+1) args)
         | (i, arg) <- zip [0..] args
         , t' <- rewritePos lhs rhs arg
         ]
       _ -> []

-- All results of applying lhs→rhs at exactly one position within a literal.
rewritePosLit :: Term -> Term -> Literal -> [Literal]
rewritePosLit lhs rhs lit = case lit of
  Eq  l r   -> [Eq  l' r | l' <- rewritePos lhs rhs l]
            ++ [Eq  l r' | r' <- rewritePos lhs rhs r]
  NEq l r   -> [NEq l' r | l' <- rewritePos lhs rhs l]
            ++ [NEq l r' | r' <- rewritePos lhs rhs r]
  Rel n ts  -> [ Rel  n (take i ts ++ [t'] ++ drop (i+1) ts)
               | (i, t) <- zip [0..] ts, t' <- rewritePos lhs rhs t ]
  NRel n ts -> [ NRel n (take i ts ++ [t'] ++ drop (i+1) ts)
               | (i, t) <- zip [0..] ts, t' <- rewritePos lhs rhs t ]

rwBound :: [(String, Term, Term)] -> Int -> Int -> Int
rwBound eqs a b = a + b + maximum (0 : [termSize l | (_, l, _) <- eqs])

-- BFS with visited set and size bound finds the shortest rewrite path.
tryMatchLit :: Literal -> Literal -> [UnitEntry] -> Maybe (Subst, [(RwStep, Literal)])
tryMatchLit lit goal units =
  bfsRewrite rewritePosLit litSize eqs (`matchLit` goal) lit bound
  where
    eqs   = eqUnits units
    bound = rwBound eqs (litSize lit) (litSize goal)

-- INVARIANT: variables in bodyLit are "c"-prefixed (produced by freshenClause)
-- and variables in unitLit are uppercase-initial (from TPTP input).
-- The two namespaces are always disjoint, so splitting the combined substitution
-- by bodyVarSet membership correctly separates σClause from σUnit.
-- freshenClause enforces the "c" prefix; the TPTP standard mandates uppercase vars.

-- Match body literal using two-sided matching (unification).
-- Returns (unit, blockSubst, clauseUpdate, rewrites) where
--   blockSubst:    applied to block to ground unit variables
--   clauseUpdate:  extends the accumulated non-unit clause substitution
findBodyLitMatch :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)])
findBodyLitMatch bodyLit units = listToMaybe
  [ (ue, σUnit, σClause, rws)
  | ue <- units
  , Just (σClause, σUnit, rws) <- [tryMatchBodyLit bodyLit (ueUnit ue) units]
  ]

tryMatchBodyLit :: Literal -> Literal -> [UnitEntry] -> Maybe (Subst, Subst, [(RwStep, Literal)])
tryMatchBodyLit bodyLit unitLit allUnits =
  fmap split (bfsRewrite rewritePosLit litSize eqs (\cur -> unifyLit bodyLit cur []) unitLit bound)
  where
    split (combined, path) =
      let bodyVarSet = litVars bodyLit
          σClause    = [(v, t) | (v, t) <- combined, v `elem`    bodyVarSet]
          σUnit      = [(v, t) | (v, t) <- combined, v `notElem` bodyVarSet]
      in (σClause, σUnit, path)
    eqs   = eqUnits allUnits
    bound = rwBound eqs (litSize bodyLit) (litSize unitLit)

-- Two-sided unification of terms: variables on either side can be bound.
-- Body variables are c-prefixed (lowercase-starting) and unit variables are
-- uppercase-starting, so the two namespaces are always disjoint and
-- dereferencing accumulated bindings is safe to skip.
unifyTerm :: Term -> Term -> Subst -> Maybe Subst
unifyTerm (Var x) t subst
  | Var x == t = Just subst
  | otherwise  = case lookup x subst of
      Nothing -> Just ((x, t) : subst)
      Just t' -> if t' == t then Just subst else Nothing
unifyTerm t (Var y) subst = unifyTerm (Var y) t subst
unifyTerm (Const c1) (Const c2) subst
  | c1 == c2  = Just subst
  | otherwise = Nothing
unifyTerm (App f1 as1) (App f2 as2) subst
  | f1 == f2 && length as1 == length as2 =
      foldl (\acc (a, b) -> acc >>= unifyTerm a b) (Just subst) (zip as1 as2)
  | otherwise = Nothing
unifyTerm _ _ _ = Nothing

pairFold :: (a -> b -> c -> Maybe c) -> [(a, b)] -> c -> Maybe c
pairFold f pairs s = foldl (\acc (a, b) -> acc >>= f a b) (Just s) pairs

unifyAll :: [(Term, Term)] -> Subst -> Maybe Subst
unifyAll = pairFold unifyTerm

unifyLit :: Literal -> Literal -> Subst -> Maybe Subst
unifyLit (Rel n1 ts1) (Rel n2 ts2) subst
  | n1 == n2 && length ts1 == length ts2 = unifyAll (zip ts1 ts2) subst
  | otherwise = Nothing
unifyLit (NRel n1 ts1) (NRel n2 ts2) subst
  | n1 == n2 && length ts1 == length ts2 = unifyAll (zip ts1 ts2) subst
  | otherwise = Nothing
unifyLit (Eq l1 r1) (Eq l2 r2) subst =
  unifyAll [(l1, l2), (r1, r2)] subst
  <|> unifyAll [(l1, r2), (r1, l2)] subst
unifyLit (NEq l1 r1) (NEq l2 r2) subst =
  unifyAll [(l1, l2), (r1, r2)] subst
  <|> unifyAll [(l1, r2), (r1, l2)] subst
unifyLit _ _ _ = Nothing

-- Dispatcher: try unit-as-pattern first (handles ground targets), then
-- two-sided unification (handles non-ground targets / unit variables).
-- Returns Nothing when no unit can prove the target (caller should skip the clause).
bodyLitMatch :: Literal -> [UnitEntry] -> Maybe BodyMatch
bodyLitMatch target units =
  ((\(ue, σUnit, rws)          -> BodyMatch ue σUnit rws [])       <$> findMatchingUnit  target units)
  <|>
  ((\(ue, σUnit, σClause, rws) -> BodyMatch ue σUnit rws σClause)  <$> findBodyLitMatch target units)

-- Fails if any equation has rhs variables absent from lhs (invalid TSTP).
-- Callers must call ensureNamed on any derived equation before it reaches here.
eqUnits :: [UnitEntry] -> [(String, Term, Term)]
eqUnits = concatMap toEq
  where
    toEq ue = case (ueName ue, ueUnit ue) of
      (Just nm, Eq l r) ->
        let extra = filter (`notElem` termVars l) (termVars r)
        in if null extra
           then [(nm, l, r)]
           else error ("eqUnits: " ++ nm ++ " has rhs variables not in lhs: " ++ show extra)
      _ -> []

translateNonUnits :: [(String, Clause, Subst)] -> Literal -> TransM ProofBlock
translateNonUnits nonUnits goalLit = fixpoint
  where
    fixpoint = do
      before <- gets (length . tsUnits)
      mBlock <- oneRound nonUnits
      case mBlock of
        Just block -> return block
        Nothing    -> do
          after <- gets (length . tsUnits)
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

ensureAllEqNamed :: TransM ()
ensureAllEqNamed = do
  units <- gets tsUnits
  forM_ units $ \ue -> case ueUnit ue of
    Eq _ _ -> void (ensureNamed (ueUnit ue))
    _      -> return ()

processNonUnit :: String -> Clause -> Subst -> Literal -> TransM (Maybe ProofBlock)
processNonUnit clauseName (Clause bodyLits mHead) σ0 goalLit = do
  let headLit = fromMaybe (error "processNonUnit: unit clause") mHead
  -- Top-down: if head unifies with goal and all body lits are already provable, build proof.
  case matchLit headLit goalLit of
    Just σHead -> do
      let σ       = σ0 ++ σHead
          targets = map (applySubst σ) bodyLits
      case targets of { _ : _ : _ -> prelemmatize clauseName (tail targets); _ -> return () }
      mResult <- processBody σ bodyLits
      case mResult of
        Nothing         -> bottomUp headLit
        Just (block, _) -> return (Just (appendLine block (Hence goalLit (ByAxiom clauseName))))
    Nothing -> bottomUp headLit
  where
    bottomUp headLit = do
      mResult <- processBody σ0 bodyLits
      case mResult of
        Nothing -> return Nothing   -- body literal unmatched; skip this clause for now
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
                  let freeVs = nub (litVars groundH)
                      -- Variables starting with uppercase came from unit axioms (e.g. X0 from q(b,X0)).
                      -- They need to be instantiated. Variables from freshenClause start lowercase
                      -- and represent clause schemas that can be specialized later by matching.
                      (unitFree, _) = partition (isUpper . head) freeVs
                  if null unitFree
                    then addToUnits (UnitEntry Nothing groundH (Just block'))
                    else forM_ (instantiations unitFree (groundSubtermsLit goalLit)) $ \σ -> do
                           let gh = applySubst σ groundH
                               bl = applySubstBlock σ block'
                           addToUnits (UnitEntry Nothing gh (Just bl))
                  return Nothing

-- BFS for a rewrite path from lit to something matching goal, using ALL equations
-- (including unnamed ones, which get a placeholder "" name for BFS purposes).
-- Returns the path and the substitution from the final match against goal.
tryRwPath :: Literal -> Literal -> [UnitEntry] -> Maybe ([(RwStep, Literal)], Subst)
tryRwPath lit goal units =
  case bfsRewrite rewritePosLit litSize eqs (`matchLit` goal) lit bound of
    Just (σ, path) | not (null path) -> Just (path, σ)
    _                                -> Nothing
  where
    eqs   = [ (fromMaybe "" (ueName ue), l, r)
            | ue     <- units
            , Eq l r <- [ueUnit ue]
            , null (filter (`notElem` termVars l) (termVars r)) ]
    bound = rwBound eqs (litSize lit) (litSize goal)

-- Append a sequence of rw-justified Hence lines to an existing block.
-- Lazily names each equation used via ensureNamed.
extendWithRw :: ProofBlock -> [(RwStep, Literal)] -> TransM ProofBlock
extendWithRw = foldM step
  where
    step blk (RwStep _ (origL, origR) dir, nextLit) = do
      nm <- ensureNamed (Eq origL origR)
      let justDir = if dir == RL then Just RL else Nothing
      return (appendLine blk (Hence nextLit (ByRw nm justDir)))

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

appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"

-- Build a HaveHence block for a unit, appending rewrite steps.
-- When the path ends at a non-ground equation, promote it to an EqChain lemma
-- and return a single Have step; run the inline fold only as a fallback.
makeBlock :: UnitEntry -> [(RwStep, Literal)] -> TransM ProofBlock
makeBlock ue rwPath = case nonGroundEqEnd rwPath of
  Just (finalLit, l, r) -> do
    units <- gets tsUnits
    case findUnitByLit finalLit units of
      Nothing -> do
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

findPath :: [UnitEntry] -> Term -> Term -> Maybe [(RwStep, Term)]
findPath units s t =
  fmap snd (bfsRewrite rewritePos termSize eqs check s bound)
  where
    eqs   = eqUnits units
    bound = maximum (0 : [termSize l | (_, l, _) <- eqs]) + max (termSize s) (termSize t)
    check cur = if cur == t then Just () else Nothing

-- Pre-lemmatize unnamed derived units that are exact matches (σUnit = [],
-- no rewrites).  Skip units whose last derivation step is from the same
-- axiom currently being processed (those are recursive applications and
-- their derivation should stay inlined).
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

-- True when any derivation step of a unit came from this clause.
derivedByClause :: String -> UnitEntry -> Bool
derivedByClause name ue = case ueDeriv ue of
  Just (HaveHence ls) -> any isFromClause ls
  _                   -> False
  where
    isFromClause (Hence _ (ByAxiom n)) = n == name
    isFromClause _                     = False

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
addToUnits ue = do
  units <- gets tsUnits
  case findUnitByLit (ueUnit ue) units of
    Nothing -> modify $ \s -> s { tsUnits = tsUnits s ++ [ue] }
    Just _  -> return ()

groundSubterms :: Term -> [Term]
groundSubterms t@(Const _)  = [t]
groundSubterms t@(App _ ts)
  | null (termVars t) = t : concatMap groundSubterms ts
  | otherwise         = concatMap groundSubterms ts
groundSubterms (Var _) = []

groundSubtermsLit :: Literal -> [Term]
groundSubtermsLit (Rel _ ts)  = concatMap groundSubterms ts
groundSubtermsLit (NRel _ ts) = concatMap groundSubterms ts
groundSubtermsLit (Eq l r)    = groundSubterms l ++ groundSubterms r
groundSubtermsLit (NEq l r)   = groundSubterms l ++ groundSubterms r

instantiations :: [String] -> [Term] -> [Subst]
instantiations freeVs terms =
  foldr (\v acc -> [(v, t) : s | t <- terms, s <- acc]) [[]] (nub freeVs)

findUnitByLit :: Literal -> [UnitEntry] -> Maybe UnitEntry
findUnitByLit lit = find (\ue -> ueUnit ue == lit)

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
matchAll = pairFold matchTerm

-- Handles both E (split_conjunct on CNF) and Vampire (negated_conjecture on FOF).
classifyAxioms :: [T.Unit]
               -> ([AxiomEntry], [UnitEntry], [(String, Clause, Subst)], [Literal])
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
      goalLits  = case (negConjE, negConjV) of
                    ([cl], []) -> [negateGoal cl]
                    ([], [f])  -> negateGoalFOF f
                    _          -> error "classifyAxioms: expected exactly one negated conjecture"
      classify (i, (_, f))
        | isPositiveUnitFOF f =
            let lit = extractUnitFOF f
                nm  = "axiom " ++ show i
            in (AUnit nm lit, Just (UnitEntry (Just nm) lit Nothing), Nothing)
        | otherwise =
            let nm = "axiom " ++ show i
                cl = fofToClause f
            in (ANonUnit nm cl, Nothing, Just (nm, freshenClause cl, []))
      classified = zipWith (curry classify) [(1::Int)..] fofAxioms
      axEntries  = [ax | (ax, _, _) <- classified]
      initUnits  = [u  | (_, Just u, _) <- classified]
      axNonUnits = [nu | (_, _, Just nu) <- classified]
  in (axEntries, initUnits, axNonUnits, goalLits)

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

-- Prefix all variables in a clause with "c" to avoid name collisions with
-- unit variables during body-literal matching.
freshenClause :: Clause -> Clause
freshenClause (Clause bs mh) =
  let allVs = nub (concatMap litVars bs ++ maybe [] litVars mh)
      sub   = [(v, Var ("c" ++ v)) | v <- allVs]
  in Clause (map (applySubst sub) bs) (fmap (applySubst sub) mh)

isFalsum :: T.Clause -> Bool
isFalsum (T.Clause lits) = case toList lits of
  [(_, T.Predicate (T.Reserved (T.Standard T.Falsum)) [])] -> True
  _ -> False

negateGoal :: T.Clause -> Literal
negateGoal (T.Clause lits) = case toList lits of
  [(T.Negative, lit)]                       -> convertLit lit
  [(T.Positive, T.Equality l T.Negative r)] -> Eq (convertTerm l) (convertTerm r)
  _ -> error "negateGoal: unexpected negated conjecture shape"

negateGoalFOF :: T.UnsortedFirstOrder -> [Literal]
negateGoalFOF (T.Negated f) = collectConjuncts f
  where
    collectConjuncts (T.Connected l T.Conjunction r) =
      collectConjuncts l ++ collectConjuncts r
    collectConjuncts (T.Atomic lit) = [convertLit lit]
    collectConjuncts _ = error "negateGoalFOF: unexpected conjunct shape"
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
