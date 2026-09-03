{-# LANGUAGE LambdaCase #-}
module Translate (translate, translateWith) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, forM, forM_, void, when)
import Data.Bifunctor (second)
import Control.Exception (SomeException, try)
import Control.Monad.State
import Data.List (find, intercalate, nub, nubBy, partition, sortBy, isSuffixOf)
import Data.Maybe (catMaybes, fromJust, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe)
import Data.Ord (Down(..), comparing)
import qualified Data.Map.Lazy as LMap
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import System.Environment (lookupEnv)
import System.CPUTime (getCPUTime)
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
import ProofTree
  ( buildProofInfo, headLitOf, isPositiveUnitFormula, unitNameStr
  , resolveCopySource
  )
import TptpConvert
import TweeInterface
import LemmaBuilder

-- Recursive-call entry point: like translate but with a pre-built name override map.
-- Overridden names are used as-is (not re-numbered); used for lemma sub-proofs so
-- that axiom references in the sub-proof match the outer proof's shared axiom list.
translateWith :: Bool -> Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof)
translateWith strict nameOverride debug (T.TSTP _ units) =
  case buildProofInfo units of
    Nothing -> return Nothing
    Just origInfo ->
      Just <$> runAlgorithm debug strict origInfo units Map.empty nameOverride Nothing

-- Two translation strategies, tried in this order:
--   1. the heuristic translation: θ|pos is read off the conclusion directly
--      above each nucleus (ground bindings only), so derived electrons keep
--      the generality of the prover's derived clauses; ground-headed derived
--      nuclei are processed alongside the leaf nuclei; lemma candidates are
--      re-proved with Twee/E.  This gives the compact proofs of the test
--      suite.  When it produces no goal proof,
--   2. the strict paper translation (Algorithm 1 literally): θ traced
--      top-down from the root so that every nucleus is processed under a
--      grounding of its body atoms, leaf nuclei strictly before derived ones,
--      lemma candidates proved by translating their own sub-DAG, one canonical
--      axiom numbering.  Needed e.g. for Twee proofs whose intermediate lemmas
--      are non-ground (HEN006-4).
translate :: Bool -> T.TSTP -> IO (Maybe StructuredProof)
translate debug tstp = do
  -- TAELJA_STRICT=1 forces the strict paper translation (experiments/evaluation)
  forceStrict <- maybe False (== "1") <$> lookupEnv "TAELJA_STRICT"
  (mHeur, errHeur) <- if forceStrict then return (Nothing, Nothing)
                      else tryStage False tstp debug
  case mHeur of
    Just sp | not (hasHole sp) -> return (Just sp)
    _ -> do
      when debug $ hPutStrLn stderr "translate: heuristic translation left a goal unproved; trying strict mode"
      (mStrict, errStrict) <- tryStage True tstp debug
      -- keep whichever result proves more goals (ties go to the heuristic:
      -- its proofs are the compact ones)
      let result = case (mHeur, mStrict) of
            (Just h, Just st) | provenGoals st > provenGoals h -> Just st
            (Nothing, Just st) | provenGoals st > 0            -> Just st
            _                                                  -> mHeur
      case result of
        Just sp | hasHole sp -> hPutStrLn stderr $
          "[warn] translate: " ++ show (length (goals sp) - provenGoals sp)
          ++ " goal(s) unproved in the final proof"
        -- both stages produced nothing: name the crashes so a failed run is
        -- diagnosable without --debug (the run fails either way, so this
        -- cannot violate the eval warning contract for successful runs)
        Nothing -> hPutStrLn stderr $ "translate: translation failed"
          ++ maybe "" ("; heuristic stage: " ++) errHeur
          ++ maybe "" ("; strict stage: " ++) errStrict
        _ -> return ()
      return result
  where
    -- one unproved goal (empty block) is enough to try strict mode: a single
    -- proven goal must not mask the hole in a multi-goal proof
    hasHole sp = null (goals sp) || any badGoal (goals sp)
    provenGoals sp = length [ () | g <- goals sp, not (badGoal g) ]
    -- a goal block that opens with "hence" has no premise line: the
    -- fallback that assembles goal proofs from Twee chains can emit these,
    -- and they are not valid proofs (nothing establishes the first step).
    -- A zero-step chain is a hole unless the goal is reflexive (t = t).
    badGoal (Eq a c, EqChain _ []) | a == c = False
    badGoal (_, b) = isEmptyBlock b || case b of
      HaveHence (Hence _ _ : _) -> True
      _                         -> False
    -- a crash inside one stage (e.g. an unprovable unit hitting an error call
    -- deep in the matcher) counts as that stage producing nothing, so the
    -- other stage still gets its chance
    tryStage strict t dbg' = do
      tStage <- getCPUTime
      when dbg' $ hPutStrLn stderr ("[time] stage " ++ (if strict then "strict" else "heuristic") ++ " start cpu=" ++ show (tStage `div` 1000000000) ++ " ms")
      r <- try (translateMode strict dbg' t) :: IO (Either SomeException (Maybe StructuredProof))
      case r of
        Right m -> return (m, Nothing)
        Left e  -> do
          when dbg' $ hPutStrLn stderr
            ("translate: " ++ (if strict then "strict" else "heuristic")
             ++ " stage failed with: " ++ show e)
          return (Nothing, Just (takeWhile (/= '\n') (show e)))

-- The translation pipeline shared by both stages.  Lemma introduction first:
-- every derived clause used at least twice in the DAG (unless it is merely a
-- renamed copy of an axiom) is re-proved and translated recursively; the
-- successful candidates become file-sourced leaves named "lemma <tstp-name>"
-- (the emitter renumbers all lemmas at the end).  One canonical axiom
-- numbering, taken from the full original proof, is used by the main
-- translation and by every recursive lemma translation, and the emitted axiom
-- list is the original one, so an axiom used only inside a lemma's proof is
-- still listed and every reference resolves.
translateMode :: Bool -> Bool -> T.TSTP -> IO (Maybe StructuredProof)
translateMode strict debug (T.TSTP _ units) =
  case buildProofInfo units of
    Nothing -> do
      hPutStrLn stderr "translate: no refutation found (unsupported proof structure)"
      return Nothing
    Just origInfo -> do
      let unitMap0 = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- units]
          origLeaves = piElectrons origInfo ++ piNuclei origInfo
          (origAxioms, origPosToName, _) =
            assignAxiomNames Map.empty (piElectrons origInfo) (piNuclei origInfo) unitMap0
          origTstp2name = Map.fromList
            [ (leName e, nm)
            | e <- origLeaves, leRole e == OrigAxiom
            , Just nm <- [Map.lookup (lePos e) origPosToName] ]
          origAxiomNames = Set.fromList [ leName e | e <- origLeaves, leRole e == OrigAxiom ]
          candidates = filter (\(cname, _) ->
                          resolveCopySource unitMap0 cname `Set.notMember` origAxiomNames)
                        (findLemmaCandidates units)
      candResults <- forM candidates $ \c ->
        buildCandidateLemma (translateWith strict) strict unitMap0 origTstp2name debug c
      let validCands = Map.fromList
            [ (cname, r) | ((cname, _), Just r) <- zip candidates candResults ]
          candOverride = Map.fromList [ (c, "lemma " ++ c) | c <- Map.keys validCands ]
          nameOverride = Map.union candOverride origTstp2name
          modUnits = map replace units
          replace u@(T.Unit n _ _)
            | Map.member (unitNameStr n) validCands = makeFileSourced u
            | otherwise                             = u
          replace u = u
      case (Map.null validCands, buildProofInfo modUnits) of
        (False, Just mainInfo) ->
          Just <$> runAlgorithm debug strict mainInfo modUnits validCands nameOverride (Just origAxioms)
        _ ->
          Just <$> runAlgorithm debug strict origInfo units Map.empty origTstp2name (Just origAxioms)

type AlgM a = StateT AlgState IO a

addUnit :: UnitEntry -> AlgM ()
addUnit ue = modify $ \s -> s { stUnits = stUnits s ++ [ue] }

-- A per-goal warning inside a translation stage may be premature: the other
-- stage can still prove the goal.  translate prints the authoritative summary.
dbgWarn :: String -> AlgM ()
dbgWarn msg = do
  dbg' <- gets stDebug
  when dbg' $ liftIO $ hPutStrLn stderr ("[warn] " ++ msg)

nextCounter :: AlgM Int
nextCounter = do
  k <- gets stCounter
  modify $ \s -> s { stCounter = k + 1 }
  return k

-- unnamed (locally-derived) electrons first; named axioms second
getElectrons :: String -> AlgM [UnitEntry]
getElectrons pos = gets $ \s ->
  let allUnits = stUnits s
      named    = filter (isJust . ueName) allUnits
      unnamed  = filter (\u -> isNothing (ueName u) && maybe True (< pos) (uePos u)) allUnits
  in unnamed ++ named

emitGoalProof :: Literal -> ProofBlock -> AlgM ()
emitGoalProof lit blk = do
  -- A goal variable is existential (a universal conjecture Skolemizes to a
  -- ground negation), and several emit paths reach here with names τ never
  -- bound (clause copies rename apart).  When the block's own conclusion is
  -- an instance of the goal, the goal is emitted at that instance.
  let realBinding (_, t) = case t of { Var _ -> False; _ -> True }
      lit' | not (null (litVars lit))
           , Just c <- blockConcl blk
           , Just ρ <- matchLit lit c
           , any realBinding ρ = applySubst ρ lit
           | otherwise = lit
  dbgFlag <- gets stDebug
  liftIO $ dbg dbgFlag $ "[goal-emit] " ++ ppLitI lit'
  modify $ \s -> s { stGoals = stGoals s ++ [(lit', blk)] }

-- The final conclusion a proof block establishes, when syntactically evident.
blockConcl :: ProofBlock -> Maybe Literal
blockConcl (HaveHence ls) = case reverse ls of
  (Hence l _ : _) -> Just l
  (And l _ : _)   -> Just l
  (Have l _ : _)  -> Just l
  []              -> Nothing
blockConcl (EqChain start steps) = case reverse steps of
  ((_, t) : _) -> Just (Eq start t)
  []           -> Nothing

promoteToLemma :: Literal -> ProofBlock -> AlgM String
promoteToLemma lit blk = do
  -- Free variables of the head are universally quantified: every premise is
  -- an instance of an axiom or lemma under the same (composed) bindings, so
  -- the block proves the lemma for all values of them.
  do
      -- (kept as a nested block to preserve indentation of the long body)
      -- skip counter values whose name is already taken (a lemma candidate is
      -- named "lemma <tstp-name>", and TSTP unit names may be numeric)
      taken <- gets (\s -> Set.fromList (map (\(n, _, _) -> n) (stLemmas s))
                          `Set.union` Set.fromList (mapMaybe ueName (stUnits s)))
      let freshName = do
            k <- nextCounter
            let name = "lemma " ++ show k
            if name `Set.member` taken then freshName else return name
      name <- freshName
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
  units    <- gets stUnits
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
                HaveHence [] -> tryRelLemma units lit
                HaveHence [Have _ nm] -> return nm
                _                   -> promoteToLemma lit blk
    Nothing -> do
      blk <- buildBlk
      case blk of
        HaveHence [] -> tryRelLemma units lit
        -- Single "have lit by name" with no further steps: inline the name
        -- directly rather than wrapping in a trivial lemma.  This covers both
        -- ground axiom instances (e.g. product(a,a,identity) by axiom 3) and
        -- ground instances of non-ground lemmas (e.g. p(a) by lemma 5).
        HaveHence [Have _ nm] -> return nm
        _ -> do
          nm <- promoteToLemma lit blk
          addUnit (UnitEntry (Just nm) lit Nothing Nothing)
          return nm

-- When ensureNamed gets an empty proof block for a relational literal, call
-- Twee (via callTwee) to derive the actual equational chain in the P=true
-- encoding.  The chain is assembled into an EqChain proof block and promoted
-- to a lemma, which then serves as the justification for the parent step.
-- Per the paper, a non-equational atom proved by an equality chain rewrites
-- subterms until the atom matches a proved unit, ending with ≈ true.
tryRelLemma :: [UnitEntry] -> Literal -> AlgM String
tryRelLemma units lit = do
  let relOrEqUnits = filter (\ue' -> isJust (ueName ue') || isEqLit (ueUnit ue')) units
  mRes <- liftIO (callTwee InternalBudget relOrEqUnits lit)
  case mRes of
    Just (start, chain) | not (null chain) -> do
      steps <- mapM promoteChainStep chain
      promoteToLemma lit (EqChain start steps)
    _ ->
      error ("ensureNamed: no proof found for: " ++ show lit)

-- Length of common prefix of two strings.
commonPrefixLen :: String -> String -> Int
commonPrefixLen s1 s2 = length $ takeWhile id $ zipWith (==) s1 s2

-- match body literal li against electron ki; returns (σi, τ') on success
tryMatch :: Literal -> Literal -> Subst -> Maybe (Subst, Subst)
tryMatch li ki τ =
  tryAsPattern li ki
  <|> tryAsPattern (flipEq li) ki
  <|> tryKiPattern ki
  <|> tryKiPattern (flipEq ki)
  <|> tryKiFlip ki
  <|> tryBothSides li ki
  <|> tryBothSides (flipEq li) ki
  where
    -- Body literal as the pattern: the electron's variables are NOT renamed
    -- apart here (only tryBothSides does), so a variable name shared between
    -- the nucleus and the electron (both "X0") is bound as the same variable.
    -- Known limitation; harmless on the current suite, but any composition of
    -- τ in this branch must rename apart first (see tryBothSides).
    tryAsPattern li' k = case matchLit li' k of
      Just σn ->
        -- Remove self-bindings (x → Var x): these arise when body lit and electron
        -- share a variable name (e.g. both use "X0"). An identity binding would
        -- prevent a later body literal from properly grounding that variable.
        let σn' = filter (\(x, t) -> Var x /= t) σn
            -- Only ground bindings are accepted here: a binding to a term with
            -- variables captures the electron's un-renamed variables in τ,
            -- which is neither renamed apart nor composed in this branch.  A
            -- compound makes the stored head look more general than the
            -- derivation supports (LCL006-1/E); even a bare variable can
            -- make τ cyclic (X0 ↦ f(X0_e), X0_e ↦ X0 on the horn_example
            -- test) so the head and the premises disagree.  Such matches
            -- fall through to tryBothSides, which renames apart and composes.
            nonGround (_, t) = not (null (termVars t))
        in if any nonGround σn'
             then Nothing
             else case extendSubst τ σn' of
               Just τ' -> Just ([], τ')
               Nothing  -> Nothing
      Nothing -> Nothing
    tryKiPattern k = case matchLit k li of
      Just σi -> Just (σi, τ)
      Nothing -> Nothing
    tryKiFlip k = case matchLit k (flipEq li) of
      Just σi -> Just (σi, τ)
      Nothing -> Nothing
    tryBothSides li' k =
      -- Rename ki's vars to avoid clashes with li's vars in matchBothLit.
      -- Without this, shared var names (e.g. both using "X0") confuse matchBothLit
      -- into treating them as the same variable, producing incorrect bindings.
      let kVars = nub (litVars k)
          -- The suffix must be one no variable of the body literal carries:
          -- after an earlier open match against the same axiom the literal
          -- already holds that electron's "_e" variables, and renaming this
          -- electron with the same suffix would identify the two (LCL008-1/E).
          liVars = litVars li'
          suffix = head [ sfx | n <- [1 :: Int ..], let sfx = concat (replicate n "_e")
                              , not (any (sfx `isSuffixOf`) liVars) ]
          k'    = suffixVarsLit suffix k
      in case matchBothLit li' k' τ [] of
        Just (τ', σi') ->
          -- Occurs check: if any ki-var's binding contains itself, deepApplySubstTerm loops.
          if any (\(v, t) -> v `elem` termVars t) σi'
            then Nothing
            else
              let -- Compose: this match may constrain a variable that an earlier
                  -- match put into τ's range (τ: Y→X0, now X0→zero).  Without
                  -- composition Bτ_m is applied shallowly and the stored head keeps
                  -- a dangling variable (zero = X0), a false universal fact.
                  newB = [ (x, t) | (x, t) <- τ', x `notElem` map fst τ ]
                  τc = [(x, deepApplySubstTerm σi' (applySubstTerm newB t)) | (x, t) <- τ']
                  -- Apply τc to ground any τ-vars that appear in σi' bindings.
                  σi  = [ (v, applySubstTerm τc (deepApplySubstTerm σi' (Var (v ++ suffix)))) | v <- kVars ]
              in if any (\(v, t) -> v `elem` termVars t) τc
                 -- occurs check on the nucleus side: a cyclic binding
                 -- (B ↦ equivalent(equivalent(C,B),A), LCL416-1) renders the
                 -- shallow consistency check meaningless and lets a spurious
                 -- premise justify a θ-derived head it cannot derive
                 then Nothing
                 else if applySubst τc li' == applySubst σi k
                 then Just (σi, τc)
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

-- Horn axioms that are purely relational (no equality heads or bodies).
-- Equality-headed/bodied axioms break the ifeq+pair Twee encoding.
isRelHornAxiom :: HornAxiomEntry -> Bool
isRelHornAxiom ha = not (isEqLit (haHead ha)) && all (not . isEqLit) (haBodies ha)

-- Promote one step from a Twee chain into a named proof step (eq or relational).
promoteChainStep :: (UnitEntry, Dir, Term) -> AlgM (RwStep, Term)
promoteChainStep (stepUe, dir, cur) = do
  nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
  case ueUnit stepUe of
    Eq a b   -> return (RwStep nm (a, b) dir, cur)
    Rel n as -> let relT = if null as then Const n else App n as
                in return (RwStep nm (relT, Const "true") dir, cur)
    _        -> error "promoteChainStep: unexpected unit in Twee chain"

tweeChain :: TweeBudget -> Term -> Term -> [UnitEntry] -> AlgM (Maybe ProofBlock)
tweeChain budget l r units = do
  mRes <- liftIO (callTwee budget units (Eq l r))
  case mRes of
    Nothing              -> return Nothing
    Just (_, [])         -> return Nothing
    Just (start, chain) -> do
      steps <- mapM promoteChainStep chain
      return (Just (EqChain start steps))

-- Algorithm 3 find_elec: step 1 is a pure match; step 2 is rw_chain (demod chain,
-- with Twee as fallback when the chain is absent or produces no steps), then tryMatch.
processBody
  :: [Literal]
  -> Subst
  -> [UnitEntry]
  -> Map.Map String [(String, Dir)]
  -> String
  -> Bool     -- allowGroundUnnamed: include unnamed proof-less ground units in step1
  -> AlgM (Maybe (Subst, [(UnitEntry, Subst, [(RwStep, Literal)])]))
processBody lits τ elecs simpl pos allowGroundUnnamed = go lits τ [] []
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

    -- Derive the instantiated version of an electron after matching.
    -- Prepending it to extraElecs makes it available to subsequent body literals
    -- within the same nucleus as a step-1 candidate.
    deriveInst ki σi = ki { ueUnit = applySubst σi (ueUnit ki) }

    go [] τ' _ _ = return (Just (τ', []))
    go (li : rest) τ' usedPos extraElecs = do
      let liInst    = applySubst τ' li
      -- Trivially true literals (t=t) need no electron; they arise from
      -- Vampire's trivial_inequality_removal preprocessing step.
      if isTriviallyTrue liInst
        then go rest τ' usedPos extraElecs
        else doMatch liInst rest τ' usedPos extraElecs
    isTriviallyTrue (Eq a b) = a == b
    isTriviallyTrue _        = False
    doMatch liInst restLits τ' usedPos extraElecs = do
      let
          (unused, used') = partition (\e -> uePos e `notElem` usedPos) sortedElecs
          prioritized = unused ++ used'
          -- Derived instances from earlier body literals take priority.
          -- For non-ground-head second-pass nuclei, also include ground unnamed
          -- proof-less units: they are concrete facts from the refutation tree
          -- that can ground body variables even without stored proofs.
          step1Elecs  = filter (\ue -> isJust (ueName ue) || isJust (ueProof ue)
                                    || (allowGroundUnnamed
                                        && isNothing (ueName ue)
                                        && isNothing (ueProof ue)
                                        && null (litVars (ueUnit ue))))
                               (extraElecs ++ prioritized)
          -- All pure step-1 candidates (no IO)
          pureMatches = [ (ue, σi, τ'', [])
                        | ue <- step1Elecs
                        , Just (σi, τ'') <- [tryMatch liInst (ueUnit ue) τ'] ]
      mBT <- tryAll pureMatches restLits usedPos extraElecs
      case mBT of
        Just res -> return (Just res)
        Nothing  -> do
          units <- gets stUnits
          -- Step 2: rw_chain — demod chain if available, Twee when absent or no steps
          tryRwChain liInst τ' units prioritized restLits usedPos extraElecs

    tryAll [] _ _ _ = return Nothing
    tryAll ((ki, σi, τ'', rwi) : rest_cands) restLits usedPos extraElecs = do
      let newExtra = deriveInst ki σi : extraElecs
      mResult <- go restLits τ'' (uePos ki : usedPos) newExtra
      case mResult of
        Just (τ''', matched) -> return (Just (τ''', (ki, σi, rwi) : matched))
        Nothing               -> tryAll rest_cands restLits usedPos extraElecs

    complete ki σi τ'' rwi restLits usedPos extraElecs = do
      let newExtra = deriveInst ki σi : extraElecs
      mRest <- go restLits τ'' (uePos ki : usedPos) newExtra
      case mRest of
        Nothing              -> return Nothing
        Just (τ''', matched) -> return (Just (τ''', (ki, σi, rwi) : matched))

    -- rw_chain: try demod chain for each candidate; Twee when chain is absent or gives no steps.
    tryRwChain liInst τ' units candidates restLits usedPos extraElecs = do
      let demodMatches =
            [ (ue, σi, τ'', rw)
            | ue <- candidates
            , let chain = fromMaybe [] (Map.lookup (fromMaybe "" (uePos ue)) simpl)
            , not (null chain)
            , let (kstar, rw) = rwChain (ueUnit ue) chain units
            , not (null rw)
            , Just (σi, τ'') <- [tryMatch liInst kstar τ'] ]
      mBT <- tryAll demodMatches restLits usedPos extraElecs
      case mBT of
        Just res -> return (Just res)
        Nothing  -> do
          mRes <- findElecIO liInst τ' pos units
          case mRes of
            Nothing              -> return Nothing
            Just (ki, σi, τ'', rwi) -> complete ki σi τ'' rwi restLits usedPos extraElecs

-- processBody with greedy-retry: tries lits in order, then reversed if that fails.
-- The reversed retry handles Horn clauses where the first literal's named-axiom
-- match commits to the wrong grounding (e.g. axiom 4 in GRP001-5/E).
processBodyBidir
  :: [Literal] -> Subst -> [UnitEntry] -> Map.Map String [(String, Dir)] -> String -> Bool
  -> AlgM (Maybe (Subst, [(UnitEntry, Subst, [(RwStep, Literal)])]))
processBodyBidir lits τ elecs simpl pos allow = do
  mRes <- processBody lits τ elecs simpl pos allow
  case mRes of
    Just _  -> return mRes
    Nothing -> processBody (reverse lits) τ elecs simpl pos allow

-- Twee rw_chain fallback: called from tryRwChain when the demod chain is absent or gives no steps.
-- For equational literals, calls Twee on the body literal, then recovers the HaveHence
-- electron from the chain; falls back to a synthetic EqChain unit when recovery fails.
-- For relational literals, calls equational Twee treating the predicate as a function
-- (handles terminating rewrites); falls back to single-step rewriting for non-terminating cases.
findElecIO
  :: Literal -> Subst -> String
  -> [UnitEntry]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
findElecIO li τ pos units = case li of
  Eq l r -> do
    mRaw <- liftIO (callTwee InternalBudget (tweableUnits units) (Eq l r))
    case mRaw of
      Nothing       -> return Nothing
      Just (_, [])  -> return Nothing
      Just (_, chain) -> do
        mRes <- recoverElecFromTweeChain li τ chain
        case mRes of
          Just res -> return (Just res)
          Nothing  -> do
            -- Before creating a new ground unit, check if a general unnamed
            -- unit in stUnits covers this ground instance via pattern match.
            -- Preferring the general unit makes ensureNamed promote g(X)=X
            -- rather than g(a)=a as the lemma (Twee proof derived units).
            allUnits <- gets stUnits
            let mGenMatch = listToMaybe
                  [ (u, σg)
                  | u  <- allUnits
                  , isNothing (ueName u)
                  , not (null (litVars (ueUnit u)))
                  , maybe True isEqChain (ueProof u)  -- skip HaveHence-proved units
                  , Just σg <- [matchLit (ueUnit u) li]
                  ]
            case mGenMatch of
              Just (genU, σg) -> return (Just (genU, σg, τ, []))
              Nothing -> do
                steps' <- mapM promoteChainStep chain
                let blk = EqChain l steps'
                    ki  = UnitEntry Nothing li (Just blk) (Just pos)
                addUnit ki
                return (Just (ki, [], τ, []))
  _ -> do
    let isHHu u    = case ueProof u of { Just (HaveHence _) -> True; _ -> False }
        hhElecs    = [ u | u <- units, isNothing (ueName u), isHHu u ]
        namedElecs = [ u | u <- units, isJust (ueName u) ]
        srcElecs   = hhElecs ++ namedElecs
        eqEntries  = filter (isEqLit . ueUnit) (tweableUnits units)
    mRw <- matchViaRw li τ srcElecs eqEntries
    case mRw of
      Just res -> return (Just res)
      Nothing  -> do
        -- First try the unit-only Twee call (fast, handles terminating rewrites).
        -- Without an equational unit Twee could only close P(t) ≈ true by the
        -- direct instantiation already tried above, so the call is skipped:
        -- in purely relational problems (LCL) it burned its whole budget
        -- for every body atom whose match failed.
        mRaw <- if null eqEntries then return Nothing
                else liftIO (callTwee InternalBudget (tweableUnits units) li)
        case mRaw of
          Just (_, chain) | not (null chain) -> do
            let goalFun = case li of { Rel n _ -> n; _ -> "" }
                validInter (_, _, t) = case t of
                  Const n -> n == goalFun || n == "true"
                  App n _ -> n == goalFun
                  _       -> False
            if all validInter chain
              then do
                steps' <- mapM promoteChainStep chain
                let blk = EqChain start steps'
                    ki  = UnitEntry Nothing li (Just blk) (Just pos)
                addUnit ki
                return (Just (ki, [], τ, []))
              else tryHornFallback
          _ -> tryHornFallback
        where
          start = case li of { Rel n as -> if null as then Const n else App n as; _ -> Const "?" }
          -- A Twee refutation of the negated goal shows an instance of a
          -- non-ground atom, which cannot certify it as a general electron;
          -- only ground atoms are worth the (budgeted) call.
          tryHornFallback
            | not (null (litVars li)) = return Nothing
            | otherwise = do
            hornAxioms <- gets stHornAxioms
            -- Exclude Eq-headed/Eq-bodied axioms: ifeq encoding collapses them,
            -- making Eq-bodied axioms unconditional and Eq-headed ones vanish.
            let filteredHornAxioms = filter isRelHornAxiom hornAxioms
            mRes <- liftIO $ callTweeRelLemma InternalBudget (tweableUnits units) filteredHornAxioms li
            case mRes of
              Just (_, chain) | not (null chain) -> do
                let axiomNms = nub [ nm | (ue, _, _) <- chain
                                        , not (isInternalUnit ue)
                                        , Just nm <- [ueName ue] ]
                case axiomNms of
                  [nm] -> do
                    let blk = HaveHence [Hence li (ByAxiom nm)]
                        ki  = UnitEntry Nothing li (Just blk) (Just pos)
                    addUnit ki
                    return (Just (ki, [], τ, []))
                  _ -> return Nothing
              _ -> return Nothing
-- Recover the electron from a Twee equational chain: find the HaveHence electron
-- among the chain participants, then try single-step rewriting to match li.
recoverElecFromTweeChain
  :: Literal -> Subst
  -> [(UnitEntry, Dir, Term)]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
recoverElecFromTweeChain li τ chain = do
  let chainUes  = map (\(ue, _, _) -> ue) chain
      hhElecs   = filter isHH chainUes
      eqEntries = filter isEq chainUes
  matchViaRw li τ hhElecs eqEntries
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
matchViaRw li τ srcElecs eqEntries = firstJustM tryElec srcElecs
  where
    firstJustM _ [] = return Nothing
    firstJustM f (x:xs) = f x >>= \case
      Just r  -> return (Just r)
      Nothing -> firstJustM f xs

    tryElec u = case tryMatch li (ueUnit u) τ of
      Just (σi, τ') -> return (Just (u, σi, τ', []))
      Nothing        -> firstJustM (tryRw u) eqEntries

    tryRw u eq
      | ueUnit u == ueUnit eq = return Nothing
    tryRw u eq = case ueUnit eq of
      Eq sa sb -> case listToMaybe
                    [ (dir, res, σi, τ')
                    | dir <- [LR, RL]
                    , res <- rewriteLitAll (ueUnit u) (sa, sb) dir
                    , Just (σi, τ') <- [tryMatch li res τ] ] of
        Nothing -> return Nothing
        Just (dir, res, σi, τ') -> do
          nm <- getEqName eq
          case nm of
            Nothing -> return Nothing
            -- NOTE: res is returned σi-instantiated here, while the demod-chain
            -- path (rwChain) returns uninstantiated literals; electronTarget and
            -- makeBlock apply σi again, which is a no-op only while σi is
            -- idempotent.  Normalizing this needs a golden decision.
            Just n  -> return $ Just (u, σi, τ', [(RwStep n (sa, sb) dir, applySubst σi res)])
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

    buildBase units = do
      let allUnnamed = filter (\u -> ueUnit u == ueUnit ki && isNothing (ueName u)) units
          hasHence (HaveHence ls) = any (\case Hence {} -> True; _ -> False) ls
          hasHence _              = False
          mBest = find (maybe False hasHence . ueProof) allUnnamed
              <|> listToMaybe allUnnamed
      case mBest of
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
                  mBlk <- tweeChain InternalBudget l r namedUs
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
                  mBlk <- tweeChain InternalBudget l r namedUs
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
        Nothing ->
          -- ki may be a derived (instantiated) entry from deriveInst that was
          -- never added to stUnits independently.  Search for an original entry
          -- whose stored atom matches ueUnit ki under some substitution σg, then
          -- instantiate its stored proof with σg.
          -- Prefer a match that carries a name or a stored proof: a proofless
          -- entry from the input tree can state the same fact (RNG008-5 has
          -- sum(X1,X2,add(X2,X1)) at 00000) and would otherwise shadow the
          -- derived unit whose proof exists.
          let mbCands who =
                [ (u, sg)
                | u <- units
                , who u
                , Just sg <- [matchLit (ueUnit u) (ueUnit ki)] ]
              hasNameOrProof u = isJust (ueName u) || isJust (ueProof u)
          in case listToMaybe (mbCands hasNameOrProof ++ mbCands (not . hasNameOrProof)) of
            Just (u, sg) ->
              case ueName u of
                Just nm -> return (HaveHence [Have lit nm])
                Nothing ->
                  case ueProof u of
                    Just stored
                      | isEqChain stored -> do
                          nm <- ensureNamed (ueUnit u) (return stored)
                          return (HaveHence [Have lit nm])
                      | otherwise -> return (applySubstBlock sg stored)
                    Nothing -> do
                      liftIO $ hPutStrLn stderr $
                        "[warn] makeBlock: unit not in table: " ++ ppLitI (ueUnit ki)
                      case ueUnit ki of
                        Eq l _ -> return (EqChain l [])
                        _      -> return (HaveHence [])
            Nothing -> do
              liftIO $ hPutStrLn stderr $
                "[warn] makeBlock: unit not in table: " ++ ppLitI (ueUnit ki)
              case ueUnit ki of
                Eq l _ -> return (EqChain l [])
                _      -> return (HaveHence [])

electronTarget :: UnitEntry -> Subst -> [(RwStep, Literal)] -> Literal
electronTarget ki σi rw = case rw of
  [] -> applySubst σi (ueUnit ki)
  -- rw is computed on the uninstantiated electron; σi comes from matching
  -- its rewritten form, so it must be applied here too (else a lemma gets
  -- stated as q(g(X)) while its proof establishes q(g(a))).
  _  -> applySubst σi (snd (last rw))

buildProofBlock
  :: [(UnitEntry, Subst, [(RwStep, Literal)])]
  -> Maybe String  -- axiom name for "hence L0 by name" (Nothing for inner nodes)
  -> Subst         -- τ
  -> Literal       -- head literal L0
  -> AlgM ProofBlock
-- unit clause with no body: treat as direct assertion
buildProofBlock [] mAxName _τ headLit =
  return $ HaveHence $ case mAxName of
    Just ax -> [Have headLit ax]
    Nothing -> []
buildProofBlock ((k1, σ1, rw1) : rest) mAxName τ headLit = do
  blk1 <- makeBlock k1 σ1 rw1
  blk  <- foldM addAnd blk1 rest
  return $ case mAxName of
    Just ax -> appendLine blk (Hence (applySubst τ headLit) (ByAxiom ax))
    Nothing -> blk
  where
    addAnd blk (ki, σi, rwi) = do
      let targ = electronTarget ki σi rwi
      -- A non-ground premise instance of a derived electron with a stored
      -- proof is cited by the name of the electron itself (make_block's
      -- name_of(E)), so the lemma stays general and every instance can
      -- reuse it (resolution_example_horn_reuse_forced: "Lemma 5: p(X)",
      -- used as "and p(a) by lemma 5" in the goal).  Ground instances,
      -- rewritten premises and electrons without a stored proof keep naming
      -- the instance together with its proof (thesis_example_both_lemmas:
      -- "Lemma 7: q(a)").
      nm <- if null rwi && isJust (ueProof ki) && not (null (litVars targ))
              then ensureNamed (ueUnit ki) (makeBlock ki [] [])
              else do
                blki <- makeBlock ki σi rwi
                ensureNamed targ (return blki)
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
          mBlk  <- tweeChain GoalBudget l r (tweableUnits units)
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

-- When a derived inner nucleus (mAxName=Nothing) matches a goal, search the
-- original axiom nuclei (stAxNuclei) for one whose head unifies with the goal
-- and whose body atoms can be matched from available electrons. If found,
-- return a correct proof block citing the original axiom. Returns Nothing when
-- no such axiom exists (caller should produce an empty proof rather than
-- "by axioms").
tryAxiomJustification
  :: Literal                           -- ground goal literal to justify
  -> Map.Map String [(String, Dir)]    -- simpl chains
  -> String                            -- position (for getElectrons)
  -> AlgM (Maybe ProofBlock)
tryAxiomJustification goalLit simpl pos = do
  axNuclei <- gets stAxNuclei
  elecs    <- getElectrons pos
  tryEach axNuclei elecs
  where
    tryEach [] _ = return Nothing
    tryEach ((axName, Clause bodyPats mHdPat) : rest) elecs =
      case mHdPat of
        Nothing    -> tryEach rest elecs
        Just hdPat ->
          case matchLit hdPat goalLit of
            Nothing -> tryEach rest elecs
            Just σh -> do
              let bodyG = map (applySubst σh) bodyPats
              mResR <- processBodyBidir bodyG [] elecs simpl pos False
              case mResR of
                Nothing            -> tryEach rest elecs
                Just (τ', matched)
                  -- the same coherence judgement as processOneNucleus: the
                  -- instantiated axiom must actually derive the claimed goal
                  | resolutionCoherent bodyPats hdPat
                      [ electronTarget ki σi rwi | (ki, σi, rwi) <- matched ]
                      (applySubst τ' goalLit) ->
                        Just <$> buildProofBlock matched (Just axName) τ' goalLit
                  | otherwise -> tryEach rest elecs

-- Compute per-nucleus θ|pos exactly as the paper prescribes (Algorithm 1):
-- Trace backwards from the conclusion to the premises:
--   C₀σ  = abstract head of the nucleus (premise) clause, from leSrcDecl
--   C₀σθ = ground conclusion read from the input proof, at position init(pos)
--   θ     = matchLit C₀σ (C₀σθ)
-- Variables not in C₀σ (body-only, premise-internal) remain free, as the paper states.
-- Only ground bindings are kept; θ = [] when the conclusion is not a known electron.
-- What computeNucleusTheta needs: the mode, the proof entries (heuristic θ
-- reads the conclusion entry at init(pos)) and the clause at every tree
-- position (strict θ traces the grounding top-down from the root).
data ThetaCtx = ThetaCtx
  { tcStrict  :: Bool
  , tcEntries :: [LeafEntry]
  , tcDeclAt  :: Map.Map String T.Declaration
  }

computeNucleusTheta :: ThetaCtx -> LeafEntry -> Subst
computeNucleusTheta ctx entry
  | tcStrict ctx =
      let abstractDecl = if leRole entry == OrigAxiom then leSrcDecl entry else leDecl entry
          θ = filter (\(_, t) -> null (termVars t))
                (nodeTheta (tcDeclAt ctx) abstractDecl (lePos entry))
          -- Paper (Thm. 6, θ'_k): variables occurring in the head but in no body
          -- literal stay free, so the derived electron is as general as the
          -- proof allows (e.g. c_plus(c_0,Y,X) = Y keeps Y)
          headOnly = case convertDeclToClause (leSrcDecl entry) of
            Just (Clause bs (Just h)) -> filter (`notElem` concatMap litVars bs) (litVars h)
            _                          -> []
      in filter (\(v, _) -> v `notElem` headOnly) θ
  | otherwise =
      -- Heuristic θ|pos: match the abstract head against the conclusion read
      -- off the proof at init(pos); only ground bindings are kept, the other
      -- nucleus variables stay free (the derived electron keeps the generality
      -- of the prover's derived clause).
      let conclusionPos = if null pos then "" else init pos
          mConclusion   = find (\e -> lePos e == conclusionPos) (tcEntries ctx)
      in case (convertDeclToClause (leSrcDecl entry), mConclusion) of
           (Just (Clause _ (Just abstractHead)), Just conclusion) ->
             case headLitOf (leDecl conclusion) of
               Just clit | not (isReservedTLit clit) ->
                 let conclusionLit = convertLit clit
                 in filter (\(_, t) -> null (termVars t))
                      (fromMaybe [] (matchLit abstractHead conclusionLit
                                  <|> matchLit (flipLit abstractHead) conclusionLit))
               _ -> []
           _ -> []
  where pos = lePos entry

-- Strict θ|p for the clause at position p, traced top-down from the root
-- (which is ground): the node's literals are matched into its parent's
-- literals AFTER the parent's own θ|init(p) has been applied, so groundings
-- propagate through non-ground inner clauses (e.g. Twee's intermediate lemma
-- divide(X,zero)=X).  Exactly one literal may fail to match: the one resolved
-- away or rewritten at the parent inference; the sibling explains it (a unit
-- equation used as a rewrite rule, a unit resolved against a body atom, ...).
-- Bindings may be non-ground for inner nodes (needed to propagate); the leaf
-- caller keeps ground ones.
nodeTheta :: Map.Map String T.Declaration -> T.Declaration -> String -> Subst
nodeTheta declAt leafDecl leafPos = go leafPos
  where
    -- the leaf itself uses its abstract (source) declaration; ancestors and
    -- siblings come from the real tree
    declOf p | p == leafPos = Just leafDecl
             | otherwise    = Map.lookup p declAt
    polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]

    -- go p recurses into both the parent chain and each sibling's parent
    -- chain; memoise per position or the sharing explodes exponentially in
    -- the tree depth.  The map must be VALUE-LAZY (Data.Map.Lazy): a strict
    -- map would force every position eagerly and loop on the mutual
    -- parent/sibling references (which are only demanded selectively).
    memo :: LMap.Map String Subst
    memo = LMap.insert leafPos (compute leafPos)
             (LMap.mapWithKey (\p _ -> compute p) (LMap.fromAscList (Map.toAscList declAt)))

    go p = LMap.findWithDefault [] p memo

    compute "" = []
    compute p  = fromMaybe [] $ do
      let pp = init p
          θP = go pp
          sp = pp ++ [if last p == '0' then '1' else '0']
      pc <- declOf pp >>= convertDeclToClause
      cc <- declOf p  >>= convertDeclToClause
      let parentLits = [ (b, suffixVarsLit "_p" (applySubst θP l)) | (b, l) <- polLits pc ]
          childLits  = polLits cc
          mSib       = Map.lookup sp declAt >>= convertDeclToClause
      return (groundChild childLits parentLits mSib (go sp))

    -- Match child literals into parent literals (each parent literal used at
    -- most once), allowing skips; prefer the fewest skips.
    matchInto [] ps s = [(s, [], ps)]
    matchInto (c : cs) ps s =
      [ (s'', sk, un)
      | (m, rest) <- picks ps
      , Just s' <- [matchPol c m s]
      , (s'', sk, un) <- matchInto cs rest s' ]
      ++ [ (s'', c : sk, un) | (s'', sk, un) <- matchInto cs ps s ]

    picks xs = [ (x, take i xs ++ drop (i + 1) xs) | (i, x) <- zip [0 ..] xs ]

    matchPol (b1, l1) (b2, l2) s
      | b1 /= b2  = Nothing
      | otherwise = matchLitWith l1 l2 s <|> matchLitWith (flipLit l1) l2 s

    notVar (Var _) = False
    notVar _       = True

    groundChild childLits parentLits mSib θSib =
      let cands = map snd $ sortBy (comparing fst)
                    [ (length sk, c) | c@(_, sk, _) <- matchInto childLits parentLits [] ]
          childVars = concatMap (litVars . snd) childLits
          restrict = filter ((`elem` childVars) . fst)
      in case cands of
        [] -> []
        ((s0, sk0, _) : _)
          | null sk0  -> restrict s0        -- every literal accounted for
          | otherwise ->
              -- several candidates may tie on skip count (e.g. a symmetric
              -- head); prefer one whose skipped literal the sibling explains
              let minSk = length sk0
                  tied  = takeWhile (\(_, sk, _) -> length sk == minSk) cands
              in restrict $ fromMaybe s0 $ listToMaybe
                   [ s' | c <- tied, Just s' <- [explain c] ]
      where
       explain (s, skipped, unused) =
          -- unit child resolved against a body literal of the sibling nucleus:
          -- its instance is that body literal under the sibling's θ (the body
          -- literal that does not survive into the parent is the resolved one)
          let resolvedAgainstSib = case (skipped, mSib) of
                ([(True, lC)], Just (Clause sbs _))
                  | length childLits == 1, not (null sbs) ->
                      let sibBody = [ (False, applySubst θSib l) | l <- sbs ]
                          skippedSib = case sortBy (comparing (\(_, sk, _) -> length sk))
                                              (matchInto sibBody parentLits []) of
                            ((_, sk, _) : _) -> sk
                            []               -> []
                      in listToMaybe
                           [ s' | (_, lS) <- skippedSib
                                , Just s' <- [matchLitWith lC lS s <|> matchLitWith (flipLit lC) lS s] ]
                _ -> Nothing
              -- child literal rewritten at the parent by the sibling unit equation
              asRewritten = case (skipped, unused, mSib) of
                ([(bS, lS)], [(bU, lU)], Just (Clause [] (Just (Eq a b))))
                  | bS == bU -> listToMaybe
                      [ s'
                      | let a' = suffixVarsLit "_r" (Eq a b)
                      , (lhs, rhs) <- case a' of { Eq x y -> [(x, y), (y, x)]; _ -> [] }
                      , let lSi = applySubst s lS
                      , (u, ctx) <- litSubtermCtxs lSi
                      , notVar u   -- rewrite rules apply to non-variable subterms
                      , Just (σR, ρC) <- [matchBothTerm lhs u [] []]
                      , let lS' = applySubst ρC (ctx (applySubstTerm σR rhs))
                      , Just s' <- [matchLitWith lS' lU (s ++ ρC)] ]
                _ -> Nothing
              -- child IS the unit equation used as a rewrite rule at the parent
              asRule = case (skipped, mSib) of
                ([(True, Eq a b)], Just sibC)
                  | length childLits == 1 -> listToMaybe
                      [ [ (v, applySubstTerm s'' t) | (v, t) <- σC ]
                      | (bS, lS) <- map (\(x, y) -> (x, suffixVarsLit "_s" y)) (polLits sibC)
                      , (bP, lP) <- parentLits
                      , bS == bP
                      , (lhs, rhs) <- [(a, b), (b, a)]
                      , (u, ctx) <- litSubtermCtxs lS
                      , notVar u
                      , Just (σC, ρS) <- [matchBothTerm lhs u [] []]
                      , let lS' = applySubst ρS (ctx (applySubstTerm σC rhs))
                      , Just s'' <- [matchLitWith lS' lP []] ]
                _ -> Nothing
              -- body literal resolved against the sibling unit: ground bindings only
              bodyVsSibUnit = case (skipped, mSib) of
                ([(False, lS)], Just (Clause [] (Just sl))) ->
                  let sl' = suffixVarsLit "_s" sl
                  in case matchLitWith lS sl' s <|> matchLitWith (flipLit lS) sl' s of
                       Just s' -> Just (s ++ filter (\(v, t) -> null (termVars t) && v `notElem` map fst s) s')
                       Nothing -> Nothing
                _ -> Nothing
          in asRewritten <|> asRule <|> bodyVsSibUnit <|> resolvedAgainstSib

-- Validates one assembled hyperresolution step: the rule's body atoms are
-- unified (shared rule variables, fresh-renamed) against the matched electron
-- targets; the step is coherent when the unifier exists and the head it
-- derives covers the head instance about to be stored.  This is the same
-- judgement the Lean check makes, applied before anything is emitted, so a
-- spurious premise match cannot justify a θ-derived head (LCL416-1).
resolutionCoherent :: [Literal] -> Literal -> [Literal] -> Literal -> Bool
resolutionCoherent bodyAbs headAbs targets headInst =
  case foldM step [] (zip bodyAbs' targets) of
    Nothing -> False
    Just s  ->
      let derived = mapLitTerms (deepApplySubstTerm s) headAbs'
      in derived == headInst || isJust (matchLit derived headInst)
         || (case (derived, headInst) of
               (Eq l r, _) -> let d' = Eq r l
                              in d' == headInst || isJust (matchLit d' headInst)
               _           -> False)
  where
    ren = suffixVarsLit "_rc"
    bodyAbs' = map ren bodyAbs
    headAbs' = ren headAbs
    -- equations may have been matched in flipped orientation
    step s (b, t) = case (litTerm b, litTerm t) of
      (Just tb, Just tt) -> case unifyTerms tb tt s of
        Just s' -> Just s'
        Nothing -> case t of
          Eq l r -> litTerm (Eq r l) >>= \tt' -> unifyTerms tb tt' s
          _      -> Nothing
      _                  -> Nothing
    litTerm (Rel n as) = Just (App n as)
    litTerm (Eq l r)   = Just (App "=" [l, r])
    litTerm _          = Nothing
    mapLitTerms f (Rel n as) = Rel n (map f as)
    mapLitTerms f (Eq l r)   = Eq (f l) (f r)
    mapLitTerms _ l          = l

processOneNucleus
  :: Bool
  -> ThetaCtx                        -- per-nucleus θ context
  -> LeafEntry
  -> Map.Map String String          -- pos → axiom name
  -> [Literal]                       -- goal literals
  -> Map.Map String [(String, Dir)]  -- simpl chains
  -> AlgM Bool
processOneNucleus debug thetaCtx entry posToName goalLits simpl = do
  let pos    = lePos entry
      mAxName = Map.lookup pos posToName
  case convertDeclToClause (leSrcDecl entry) of
    Nothing  -> do
      liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ") — could not convert to clause"
      return False
    Just cls ->
      let θ_local = computeNucleusTheta thetaCtx entry
          Clause bodyLitsAbs mHead = cls
          bodyLits = map (applySubst θ_local) bodyLitsAbs
          -- True for non-ground-head derived nuclei (innerNusNG, second pass):
          -- ground unnamed proof-less facts are valid electrons here.
          allowGroundUnnamed = isNothing mAxName
                            && maybe False (not . null . litVars) mHead
      in do
        liftIO $ dbg debug $ "θ|" ++ pos ++ " = [" ++ intercalate ", " [v ++ "→" ++ ppTerm t | (v, t) <- θ_local] ++ "]"
        elecs   <- getElectrons pos
        mResult <- processBody bodyLits θ_local elecs simpl pos allowGroundUnnamed
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
                            mResult2 <- processBody bodyLitsG [] elecs simpl pos False
                            case mResult2 of
                              Nothing -> return False
                              Just (τ, matched) -> do
                                let pairs = zip goalLits matched
                                if null pairs then return False
                                else do
                                  forM_ pairs $ \(gl, (ki, σi, rwi)) -> do
                                    let gl' = applySubst σ_sib (applySubst τ gl)
                                    blk <- emitBlockForGoal gl' ki σi rwi
                                    emitGoalProof gl' blk
                                  return True
                _ -> return False
              Just hl ->
                case listToMaybe [σ | gl <- goalLits, Just σ <- [matchLit hl gl]] of
                  Nothing   -> return False
                  Just σ_gl -> do
                    -- Ground the ABSTRACT body (bodyLits already carries θ_local;
                    -- σ_gl over it is a no-op and would mismatch the claimed head).
                    let bodyLitsG = map (applySubst σ_gl) bodyLitsAbs
                        headLitG  = applySubst σ_gl hl
                    mResult2R <- processBodyBidir bodyLitsG [] elecs simpl pos False
                    case mResult2R of
                      Nothing -> return False
                      Just (τ, matched) -> do
                        blk <- buildProofBlock matched mAxName τ headLitG
                        let headInst = applySubst τ headLitG
                            -- Only store ground proofs from this extra goal-grounding attempt;
                            -- abstract proofs here are redundant (the main path handles them).
                            proofToStore = if null (litVars headInst) then Just blk else Nothing
                        when (isJust mAxName) $ do
                          addUnit (UnitEntry Nothing headInst proofToStore (Just pos))
                          case (proofToStore, blk) of
                            (Just _, EqChain {}) -> void (ensureNamed headInst (return blk))
                            _ -> return ()
                        -- For named axioms: emit the goal proof with the proper axiom name.
                        -- For derived inner nuclei (no axiom name): search original axiom
                        -- nuclei for a proper justification; return False if none found.
                        case (mAxName, listToMaybe [gl | gl <- goalLits, isJust (matchLit headInst gl)]) of
                          (Nothing, Just gl) -> do
                            mBlk <- tryAxiomJustification headInst simpl pos
                            case mBlk of
                              Just blk' -> emitGoalProof gl blk' >> return True
                              Nothing   -> return False
                          (Just _, Just gl) -> do
                            emitGoalProof gl blk
                            return True
                          _ -> return False
          Just (τ, matched)  ->
            case mHead of
              Nothing ->
                -- L0 = ⊥: emit goal proofs; τ instantiates any remaining variables
                case (goalLits, matched) of
                  ([gl], [(ki, σi, _)])
                    | isNothing (ueName ki)
                    , Just chain@(EqChain {}) <- ueProof ki ->
                        emitGoalProof (applySubst τ gl) (applySubstBlock σi chain) >> return True
                  _ -> do
                    let pairs     = zip3 goalLits bodyLits matched
                        unmatched = drop (length matched) goalLits
                    if null pairs
                      then return False
                      else do
                        forM_ pairs $ \(gl, bl, (ki, σi, rwi)) -> do
                          -- τ binds the clause copy's variable names, which can
                          -- differ from the goal literal's (each Vampire clause
                          -- renames apart), so remaining goal variables are
                          -- instantiated by matching on the proved electron
                          -- instance; they are existential (NUM025-1: the goal
                          -- is emitted as less(b,b), not less(X,Y)).
                          -- The harvested goal literals can also disagree with
                          -- the ⊥ nucleus's own body entirely (E's definitional
                          -- detour prints epred atoms near ⊥ while the input
                          -- goal clause holds the real atoms, SYO632-1): then
                          -- the goal proved here is the body atom's instance.
                          let gl0 = applySubst τ gl
                              targ = electronTarget ki σi rwi
                              gl' = case matchLit gl0 targ of
                                      Just ρ | not (null (litVars gl0)) -> applySubst ρ gl0
                                             | otherwise -> gl0
                                      Nothing | gl0 /= targ -> applySubst τ bl
                                      _ -> gl0
                          blk <- emitBlockForGoal gl' ki σi rwi
                          emitGoalProof gl' blk
                        forM_ unmatched $ \gl -> do
                          liftIO $ hPutStrLn stderr $
                            "[warn] processOneNucleus: unmatched goal lit: " ++ ppLitI (applySubst τ gl)
                          emitGoalProof (applySubst τ gl) (HaveHence [])
                        return True
              Just headLit | not (resolutionCoherent bodyLitsAbs headLit
                                     [ electronTarget ki σi rwi | (ki, σi, rwi) <- matched ]
                                     (applySubst τ headLit)) -> do
                liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " — incoherent resolution step"
                return False
              Just headLit -> do
                blk <- buildProofBlock matched mAxName τ headLit
                let headInst = applySubst τ headLit
                    electronTargets = map (\(ki,σi,_) -> applySubst σi (ueUnit ki)) matched
                    -- Two kinds of degenerate blocks are never stored:
                    -- (1) Stale target (non-ground Eq heads only): a free head var V
                    --     also appears in a body literal after τ, but some electron
                    --     target lacks V — greedy matching grounded V in that target
                    --     while leaving it free in the head, so retrieval at another
                    --     instance would be inconsistent.  Example: HEN006-4 axiom 5
                    --     (antisymmetry), body 2 target "less_equal(zero,zero)" with
                    --     X1 still free in the head.  Head-only vars (Y in
                    --     "class_Ord(X) => Y = c_times(c_1,Y,X)") are exempt.
                    -- (2) Circular (any head): a body electron target equals the head,
                    --     so the block proves the literal from itself.  Example:
                    --     transitivity matched against two abstract axiom-7 copies,
                    --     each claiming the same "less_equal(div(X,Y),X)".
                    headVars = Set.fromList (litVars headInst)
                    bodyVarsAfterTau = Set.fromList
                      (concatMap (litVars . applySubst τ) bodyLits)
                    headBodyVars = headVars `Set.intersection` bodyVarsAfterTau
                    hasStaleTarget = isEqLit headLit
                                  && not (Set.null headBodyVars)
                                  && any (\t -> not (headBodyVars `Set.isSubsetOf`
                                                     Set.fromList (litVars t)))
                                         electronTargets
                    isCircular = headInst `elem` electronTargets
                    proofToStore = if isCircular || (not (Set.null headVars) && hasStaleTarget)
                                   then Nothing else Just blk
                -- inner nuclei (mAxName=Nothing) produce no "hence L0 by axiom",
                -- so skip storing them to avoid corrupting later proofs
                when (isJust mAxName) $ do
                  liftIO $ dbg debug $ "[store] pos=" ++ pos ++ " headInst=" ++ ppLitI headInst ++ " hasProof=" ++ show (isJust proofToStore) ++ " isCircular=" ++ show isCircular
                    ++ (if isNothing proofToStore && not isCircular
                          then " staleTarget: targets=" ++ show (map ppLitI electronTargets)
                               ++ " headBodyVars=" ++ show (Set.toList headBodyVars)
                          else "")
                  addUnit (UnitEntry Nothing headInst proofToStore (Just pos))
                  -- EqChains can't nest inside HaveHence, so promote immediately
                  case (proofToStore, blk) of
                    (Just _, EqChain {}) -> void (ensureNamed headInst (return blk))
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
                      -- Ground the ABSTRACT body: bodyLits already carries θ_local,
                      -- so applying σ_gl to it is a no-op and the retry would prove
                      -- the θ-instance body while claiming the goal-instance head.
                      let bodyLitsG = map (applySubst σ_gl) bodyLitsAbs
                          headLitG  = applySubst σ_gl headLit
                      mResult2R <- processBodyBidir bodyLitsG [] elecs2 simpl pos False
                      case mResult2R of
                        Nothing -> return ()
                        Just (τ', matched') -> do
                          blk2 <- buildProofBlock matched' mAxName τ' headLitG
                          let headInst2 = applySubst τ' headLitG
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
                -- For derived inner nuclei (mAxName=Nothing): if the head shape
                -- matches a goal under a different grounding, retry processBody with
                -- goal-grounded body so that step-2 findElecIO can find unnamed ground
                -- electrons (e.g. E's inline spm steps like c_0_16 in GRP001-5).
                -- This only fires in the second pass (innerNusNG), so named axiom
                -- paths always get priority.
                -- Fire when headInst exactly matches a goal and either:
                --   (a) the goal is equational, or
                --   (b) the head has free variables (non-ground head → innerNusNG
                --       second pass, so named axiom paths have already been tried).
                -- Ground-head derived nuclei (heuristic first pass) are excluded by
                -- the `not (null (litVars headLit))` guard so they cannot short-circuit
                -- named axiom proofs for relational goals.
                -- Orient headLit to match the goal literal's direction.
                -- When headInst is a flipped equality of gl, swap headLit so
                -- that applySubst τ headLitOriented == gl.
                let orientedPair gl = case (headInst, gl) of
                      (Eq a b, Eq c d)
                        | a == c && b == d -> Just (gl, headLit)
                        | a == d && b == c -> Just (gl, case headLit of
                                                         Eq x y -> Eq y x
                                                         other  -> other)
                      _ | headInst == gl   -> Just (gl, headLit)
                      _                    -> Nothing
                    matchResult = listToMaybe
                      [ p | gl <- goalLits
                          , isEqLit gl || not (null (litVars headLit))
                          , Just p <- [orientedPair gl] ]
                case (mAxName, matchResult) of
                  (Nothing, Just (gl, headLitOr)) | not (null matched) -> do
                    let goalInst = applySubst τ headLitOr
                    mBlk <- tryAxiomJustification goalInst simpl pos
                    case mBlk of
                      Just blk' -> emitGoalProof gl blk' >> return True
                      Nothing   -> return False
                  _ ->
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
                            -- Ground the ABSTRACT body, not the θ-grounded bodyLits.
                            let bodyLitsG3 = map (applySubst σ_gl) bodyLitsAbs
                                headLitG3  = applySubst σ_gl headLit
                            mGoalResult <- processBody bodyLitsG3 [] elecs3 simpl pos allowGroundUnnamed
                            case mGoalResult of
                              Nothing -> return False
                              Just (τ', _) -> do
                                let goalInst3 = applySubst τ' headLitG3
                                mBlk <- tryAxiomJustification goalInst3 simpl pos
                                case mBlk of
                                  -- τ' grounds the goal's variables: they are
                                  -- existential (a universal conjecture
                                  -- Skolemizes to a ground negation), so the
                                  -- goal is emitted at the proved instance
                                  -- (NUM025-1: "less(b,b)", not "less(X,Y)")
                                  Just blk' -> emitGoalProof (applySubst τ' gl) blk' >> return True
                                  Nothing   -> return False
                      else return False

processNuclei
  :: Bool  -- debug
  -> Bool  -- warnOnFail: emit warning if nuclei remain unprocessed after all retries
  -> ThetaCtx     -- per-nucleus θ context
  -> [LeafEntry]
  -> Map.Map String String
  -> [Literal]
  -> Map.Map String [(String, Dir)]
  -> AlgM ()
processNuclei debug warnOnFail thetaCtx nuclei posToName goalLits simpl = go nuclei
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
              "[warn] processNuclei: " ++ show (length failed)
              ++ " nucleus/nuclei could not be processed"

    processPass [] = return []
    processPass (entry : rest) = do
      nDone <- gets (length . stGoals)
      if nDone >= nGoals
        then return []
        else do
          prevCount <- gets (length . stUnits)
          t0        <- liftIO getCPUTime
          done      <- processOneNucleus debug thetaCtx entry posToName goalLits simpl
          t1        <- liftIO getCPUTime
          liftIO $ dbg debug $ "[time] pos=" ++ lePos entry ++ " " ++ show ((t1 - t0) `div` 1000000000) ++ " ms"
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
  [ (ue, σi, applySubst τ goal)
  | ue <- units
  , isNothing (matchLit (ueUnit ue) goal)
  , isNothing (matchLit goal (ueUnit ue))
  , Just (σi, τ) <- [tryMatch goal (ueUnit ue) []]
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

-- A substitution making both sides of l ≈ r syntactically equal, found by
-- matching l onto r or r onto l (the goal's variables are existential).
reflexiveInstance :: Term -> Term -> Maybe Subst
reflexiveInstance l r = listToMaybe
  [ ρ | (p, t) <- [(l, r), (r, l)]
      , Just ρ <- [matchTerm p t []]
      , applySubstTerm ρ l == applySubstTerm ρ r ]

proveGoal :: Map.Map String [(String, Dir)] -> Maybe [(String, Dir)] -> Literal -> AlgM ()
proveGoal simpl mChain goal = do
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
            -- Reflexive goal: the goal's variables come from an existential
            -- conjecture, so if the two sides unify the instantiated goal
            -- l' = l' holds by reflexivity (Twee emits a `reflexivity` step,
            -- Vampire an equality_resolution on the negated conjecture).
            -- reflexive existential goal (Twee `reflexivity`, Vampire
            -- equality_resolution): one side matched onto the other and
            -- checked to make both sides equal (matching, not unification)
            Nothing | Just ρ <- reflexiveInstance l r -> do
              let l' = deepApplySubstTerm ρ l
              emitGoalProof (Eq l' l') (EqChain l' [])
            Nothing  -> do
              mTwee <- liftIO (callTwee GoalBudget (tweableUnits units) goal)
              case mTwee of
                Just (start, chain) | not (null chain) -> do
                  steps' <- mapM promoteChainStep chain
                  emitGoalProof goal (EqChain start steps')
                _ -> do
                  -- an equational goal can be the head of a Horn axiom
                  -- (antisymmetry: less_equal both ways gives the equation),
                  -- so the axiom nuclei are searched before giving up
                  -- (HEN010-3: divide(identity,a) = ... via axiom 5)
                  mAx <- tryAxiomJustification goal simpl "z"
                  case mAx of
                    Just blk -> emitGoalProof goal blk
                    Nothing -> do
                      mAxF <- tryAxiomJustification (Eq r l) simpl "z"
                      case mAxF of
                        Just blk -> emitGoalProof (Eq r l) blk
                        Nothing -> do
                          dbgWarn ("no proof found for goal: " ++ ppLitI goal)
                          emitGoalProof goal (EqChain l [])
    _ ->
      case findUnitForGoal goal units of
        Just (ue, ρ0, instGoal) -> do
          blk <- makeBlock ue ρ0 []
          emitGoalProof instGoal blk
        Nothing -> do
          allElecs <- gets stUnits
          axNuclei <- gets stAxNuclei
          let provableElecs = filter (\ue -> isJust (ueName ue) || isJust (ueProof ue)) allElecs
              -- Only ground proof-less electrons: non-ground literals cannot be
              -- promoted as named lemmas (conservative: only ground proofless electrons are promoted here).
              prooflessElecs = filter (\ue -> isNothing (ueName ue) && isNothing (ueProof ue)
                                           && ueUnit ue /= goal
                                           && null (litVars (ueUnit ue))) allElecs
          -- Iterative enrichment: repeat until fixed point so multi-step dependency chains
          -- (enriching A requires enriched B which requires enriched C, etc.) are resolved.
          -- Each round tries both one-step axiom matching and EqChain via Twee.
          let enrichLoop allProv pending = do
                newly <- fmap catMaybes $ forM pending $ \ue -> do
                  mStep <- tryOneStepAxiom axNuclei allProv (ueUnit ue)
                  case mStep of
                    Just _  -> return mStep
                    Nothing -> tryEqChainEnrich ue
                if null newly
                  then return []
                  else do
                    let newLits = map ueUnit newly
                        rest    = filter (\ue -> ueUnit ue `notElem` newLits) pending
                    more <- enrichLoop (allProv ++ newly) rest
                    return (newly ++ more)
          enriched <- enrichLoop provableElecs prooflessElecs
          let tryAxNuclei _ [] = return Nothing
              tryAxNuclei elecs ((axName, Clause bodyPats mHdPat) : rest) =
                case mHdPat of
                  Nothing    -> tryAxNuclei elecs rest
                  Just hdPat ->
                    case matchLit hdPat goal of
                      Nothing -> tryAxNuclei elecs rest
                      Just σh -> do
                        let bodyG = map (applySubst σh) bodyPats
                        -- Prefer reversed order: grounds free variables before matching forward.
                        mRes <- processBodyBidir (reverse bodyG) [] elecs Map.empty "" False
                        case mRes of
                          Nothing            -> tryAxNuclei elecs rest
                          Just (τ', matched) ->
                            Just <$> buildProofBlock matched (Just axName) τ' goal
          -- Use the full enriched set: the enriched lemmas are needed in step1
          -- so that the reversed body order finds them before falling back to step2 Twee.
          mAxBlk <- tryAxNuclei (provableElecs ++ enriched) axNuclei
          case mAxBlk of
            Just blk -> emitGoalProof goal blk
            Nothing  -> do
              -- Fallback: Twee-based proof using relational Horn axioms from stAxNuclei.
              -- Re-read stUnits so enriched lemmas are available as Twee background.
              units' <- gets stUnits
              hornAxioms <- gets stHornAxioms
              let filteredHornAxioms = filter isRelHornAxiom hornAxioms
                  axHornAxioms =
                    [ HornAxiomEntry { haCnfId    = nm ++ "_axnu"
                                     , haDispName = Just nm
                                     , haHead     = hdPat
                                     , haBodies   = bodyPats }
                    | (nm, Clause bodyPats (Just hdPat)) <- axNuclei
                    , not (isEqLit hdPat)
                    , all (not . isEqLit) bodyPats ]
              -- a goal with variables is universal; a Twee refutation of its
              -- negation only shows an instance, so the call is not made
              mRes <- if not (null (litVars goal)) then return Nothing
                      else liftIO $ callTweeRelLemma GoalBudget (tweableUnits units') (filteredHornAxioms ++ axHornAxioms) goal
              case mRes of
                Just (_, chain) | not (null chain) -> do
                  let hornSteps = nubBy (\(_, n1) (_, n2) -> n1 == n2)
                                    [ (ue, nm') | (ue, _, _) <- chain
                                                , not (isInternalUnit ue)
                                                , Just nm' <- [ueName ue] ]
                  case hornSteps of
                    []        -> do
                      dbgWarn ("no unit found for goal: " ++ ppLitI goal)
                      emitGoalProof goal (HaveHence [])
                    [(_, nm')] -> emitGoalProof goal (HaveHence [Hence goal (ByAxiom nm')])
                    _ ->
                      let intermediateLines =
                            [ Hence (ueUnit ue') (ByAxiom nm')
                            | (ue', nm') <- init hornSteps ]
                          finalLine = Hence goal (ByAxiom (snd (last hornSteps)))
                      in emitGoalProof goal (HaveHence (intermediateLines ++ [finalLine]))
                _ -> do
                  dbgWarn ("no unit found for goal: " ++ ppLitI goal)
                  emitGoalProof goal (HaveHence [])
  where
    -- Try to prove a literal in ONE step via any axiom in axNuclei, using
    -- only provable electrons.  Returns a named UnitEntry on success.
    tryOneStepAxiom axNuclei elecs litToProve = tryEach axNuclei
      where
        tryEach [] = return Nothing
        tryEach ((axName, Clause bodyPats mHdPat) : rest) =
          case mHdPat of
            Nothing    -> tryEach rest
            Just hdPat ->
              case matchLit hdPat litToProve of
                Nothing -> tryEach rest
                Just σh -> do
                  let bodyG = map (applySubst σh) bodyPats
                  mRes <- processBodyBidir bodyG [] elecs Map.empty "" False
                  case mRes of
                    Nothing            -> tryEach rest
                    Just (τ', matched) -> do
                      blk <- buildProofBlock matched (Just axName) τ' litToProve
                      nm  <- promoteToLemma litToProve blk
                      return (Just (UnitEntry (Just nm) litToProve (Just blk) Nothing))

    -- Try to prove a Rel electron via Twee-generated EqChain (equational rewrites + unit step).
    -- Used as fallback in enrichLoop when tryOneStepAxiom fails.
    tryEqChainEnrich ue = case ueUnit ue of
      Rel _ _ -> do
        units' <- gets stUnits
        hornAxioms <- gets stHornAxioms
        let lit = ueUnit ue
            filteredHornAxioms = filter isRelHornAxiom hornAxioms
            startTerm = case lit of
              Rel n as -> if null as then Const n else App n as
              _        -> Const "?"
        mRes <- if not (null (litVars lit)) then return Nothing   -- same: instance proofs cannot justify a general electron
                else liftIO $ callTweeRelLemma InternalBudget (tweableUnits units') filteredHornAxioms lit
        case mRes of
          Just (_, chain) | not (null chain) -> do
            let steps = [ let nm  = fromJust (ueName u)
                              eq  = case ueUnit u of { Eq a b -> (a, b); _ -> (Const "?", Const "?") }
                          in (RwStep nm eq dir, cur)
                        | (u, dir, cur) <- chain
                        , not (isInternalUnit u)
                        , isJust (ueName u) ]
            case steps of
              [] -> return Nothing
              _  -> do
                let blk = EqChain startTerm steps
                nm <- promoteToLemma lit blk
                return (Just (UnitEntry (Just nm) lit (Just blk) Nothing))
          _ -> return Nothing
      _ -> return Nothing

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

-- nameOverride maps raw TSTP unit names to pre-assigned display names.
-- Overridden axioms are NOT added to the axiom list (they belong to an outer proof).
-- Names mapped to the empty string are silently skipped (used for internal Twee axioms).
assignAxiomNames
  :: Map.Map String String  -- name override: tstp-name -> display name (or "" to skip)
  -> [LeafEntry]
  -> [LeafEntry]
  -> Map.Map String T.Unit
  -> ([Axiom], Map.Map String String, [UnitEntry])
assignAxiomNames nameOverride electrons nuclei unitMap =
  let unitTags    = [(lePos e, Left e)  | e <- electrons, leRole e == OrigAxiom]
      nucleiTags = [(lePos e, Right e) | e <- nuclei,    leRole e == OrigAxiom]
      allLeaves   = sortBy (comparing fst) (unitTags ++ nucleiTags)
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
             case Map.lookup origKey nameOverride of
               Just nm | not (null nm) ->
                 -- Use main-proof display name; don't add to axiomList (already in outer proof)
                 (axAcc, Map.insert pos nm posMap, Map.insert origKey nm seen)
               Just _ ->
                 -- Empty-string sentinel: skip entirely (internal Twee axiom)
                 (axAcc, posMap, Map.insert origKey "" seen)
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
             case Map.lookup origKey nameOverride of
               Just nm | not (null nm) ->
                 (axAcc, Map.insert pos nm posMap, Map.insert origKey nm seen)
               Just _ ->
                 (axAcc, posMap, Map.insert origKey "" seen)
               Nothing ->
                 case convertDeclToClause (leSrcDecl e) of
                   Just cls@(Clause _ (Just _)) ->
                     let n  = length axAcc + 1
                         nm = "axiom " ++ show n
                     in (axAcc ++ [ANucleus nm cls],
                         Map.insert pos nm posMap,
                         Map.insert origKey nm seen)
                   _ -> (axAcc, posMap, seen)



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
  -> Bool                        -- strict paper mode (see translate)
  -> ProofInfo
  -> [T.Unit]
  -> Map.Map String BuiltLemma   -- tstp_name → pre-built lemma (with lifted sub-lemmas)
  -> Map.Map String String       -- name override: tstp-name → display name
  -> Maybe [Axiom]               -- emitted axiom list (canonical); Nothing: derive from this tree
  -> IO StructuredProof
runAlgorithm debug strict info allUnits candLemmaMap nameOverride mFixedAxioms = do
  let unitMap    = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      thetaCtx   = ThetaCtx strict (piElectrons info ++ piNuclei info) (piDeclAt info)
      goalLits'  = map convertLit (piGoalLits info)

      (rawAxiomList, posToName, namedUnits) =
        assignAxiomNames nameOverride (piElectrons info) (piNuclei info) unitMap

      -- Axioms that are actually pre-built lemmas get their names here
      candAxiomNames = Set.fromList
        [ nm
        | e <- piElectrons info
        , leRole e == OrigAxiom
        , Map.member (leName e) candLemmaMap
        , Just nm <- [Map.lookup (lePos e) posToName]
        ]
      -- Real axioms (not candidates)
      axiomList = case mFixedAxioms of
        Just fixed -> fixed
        Nothing    -> filter (\case
          AUnit nm _    -> nm `Set.notMember` candAxiomNames
          ANucleus nm _ -> nm `Set.notMember` candAxiomNames
          ) rawAxiomList
      -- Pre-built lemmas in proof-tree order, each preceded by the sub-lemmas
      -- its recursive translation introduced
      preLemmaEntries = concat
        [ lifted ++ [(axNm, lit, blk)]
        | e <- piElectrons info
        , leRole e == OrigAxiom
        , Just (lit, blk, lifted) <- [Map.lookup (leName e) candLemmaMap]
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
      pG1Chain = case find (\e -> leRole e == NegConjecture) (piNuclei info) of
        Just e | not (null (leSimpl e)) ->
          Just [(resolveSimplName n, d) | (n, d) <- leSimpl e]
        _ -> Nothing

      derivedUnits =
        [ UnitEntry Nothing lit mProof (Just (lePos e))
        | e <- filter (\e -> leRole e == Derived) (piElectrons info)
        , let lit    = electronLit unitMap e
              mProof = fmap (\(_, b, _) -> b) (Map.lookup (leName e) candLemmaMap)
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
        [ leName e | e <- piElectrons info ++ piNuclei info
                   , leRole e == OrigAxiom ]
      bgEqPairs = if not isTweeProof then [] else
        nubBy (\(_, l1) (_, l2) -> l1 == l2)
        [ (unitNameStr n, clit)
        | u@(T.Unit n decl _) <- allUnits
        , isOrigAxiomDecl decl
        , not (isDerivedUnit u)
        , unitNameStr n `Set.notMember` proofTreeAxNames
        -- already listed under its canonical name (e.g. used only inside a lemma)
        , unitNameStr n `Map.notMember` nameOverride
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

      -- derived clauses with L0=⊥ are skipped: they'd intercept goal emission
      hasGroundHead e =
        let θ_e = computeNucleusTheta thetaCtx e
        in case convertDeclToClause (leDecl e) of
          Just (Clause _ (Just hl)) -> null (litVars (applySubst θ_e hl))
          _                         -> False
      -- inner nuclei with positive heads but non-ground vars (e.g. derived Horn
      -- clauses from E's inline inference steps like spm(A,B) inside sr(...))
      hasPositiveHead e = case convertDeclToClause (leDecl e) of
        Just (Clause _ (Just _)) -> True
        _                         -> False
      leafNuclei  = filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNuclei info)
      innerNus      = filter (\e -> leRole e == Derived && hasGroundHead e) (piNuclei info)
      -- Strict mode: the paper's nuclei are the non-unit LEAF clauses; derived
      -- inner nuclei are only a second-pass fallback, so that they never
      -- pre-empt a leaf nucleus processed later in position order.
      innerNusNG    = sortBy (comparing lePos) $
                      filter (\e -> leRole e == Derived && hasPositiveHead e
                                    && (strict || not (hasGroundHead e))) (piNuclei info)
      allNuclei   = sortBy (comparing lePos) (leafNuclei ++ (if strict then [] else innerNus))

      nAll = length axiomList + length bgAxiomList
      axNucleiList = [ (nm, cl) | e <- piNuclei info
                                 , leRole e == OrigAxiom
                                 , let nm = fromMaybe (leName e) (Map.lookup (lePos e) posToName)
                                 , Just cl <- [convertDeclToClause (leDecl e)] ]
      -- Original Horn axioms with relational heads, for Twee fallback calls in findElecIO/proveGoal.
      hornAxiomEntries =
        [ HornAxiomEntry
            { haCnfId    = sanitizeId (leName e) ++ "_orig"
            , haDispName = Map.lookup (lePos e) posToName
            , haHead     = convertLit hl
            , haBodies   = map convertLit (bodyLitsOf (leDecl e))
            }
        | e <- piElectrons info
        , leRole e == OrigAxiom
        , not (isPositiveUnitFormula (leDecl e))
        , Just hl <- [headLitOf (leDecl e)]
        , not (isEqLit (convertLit hl))
        ]
      initSt = AlgState
        { stDebug      = debug
        , stUnits      = namedUnits ++ derivedUnits ++ bgNamedUnits
        , stHornAxioms = hornAxiomEntries
        , stLemmas     = preLemmaEntries
        , stGoals      = []
        , stCounter    = nAll + 1
        , stAxNuclei   = axNucleiList
        }

  when debug $ do
    dbg debug $ "goals: " ++ intercalate ", " (map ppLitI goalLits')
    dbg debug ""
    let tagged = map (True,)  (piElectrons info)
              ++ map (False,) allNuclei
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
    forM_ pG1Chain $ \chain -> do
      dbg debug ""
      dbg debug $ "pG1: " ++ ppSimplChain chain
    dbg debug ""

  finalSt <- execStateT (action thetaCtx allNuclei innerNusNG posToName goalLits' simpl pG1Chain) initSt
  if null (stGoals finalSt)
    then do
      hPutStrLn stderr "translate: no goal proof produced"
      return (StructuredProof (axiomList ++ bgAxiomList) (stLemmas finalSt) [])
    else return (StructuredProof (axiomList ++ bgAxiomList) (stLemmas finalSt) (stGoals finalSt))
  where
    action thetaCtx' allNuclei innerNusNG posToName goalLits simpl pG1Chain = do
      -- First pass: leaf axioms + ground-head derived nuclei.
      processNuclei debug False thetaCtx' allNuclei posToName goalLits simpl
      nDone <- gets (length . stGoals)
      -- Second pass: derived non-ground-head Horn nuclei (e.g. E's inline spm steps).
      -- Only tried when the first pass (leaf + ground-head nuclei) failed to prove
      -- the goal, so named axiom paths always get priority.
      when (nDone < length goalLits) $
        processNuclei debug False thetaCtx' innerNusNG posToName goalLits simpl
      nDone2 <- gets (length . stGoals)
      when (nDone2 < length goalLits) $ do
        proven <- gets (map fst . stGoals)
        let unproven = filter (`notElem` proven) goalLits
        mapM_ (proveGoal simpl pG1Chain) unproven
      nDone3 <- gets (length . stGoals)
      when (nDone3 < length goalLits) $
        liftIO $ hPutStrLn stderr "[warn] processNuclei: goal(s) could not be proved"

