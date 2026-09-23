{-# LANGUAGE LambdaCase #-}
module Translate (translate, translateWith) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, forM, forM_, unless, void, when)
import Data.Bifunctor (second)
import Control.Exception (ErrorCall, SomeException, finally, try)
import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Control.Monad.State
import Data.Either (fromRight)
import Data.List (find, inits, intercalate, nub, nubBy, partition, sortBy, isSuffixOf, tails)
import Data.Maybe (catMaybes, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe, maybeToList)
import Data.Ord (Down(..), comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import Data.IORef (IORef, modifyIORef', newIORef, readIORef, writeIORef)
import GHC.Clock (getMonotonicTime)
import System.IO.Unsafe (unsafePerformIO)
import System.CPUTime (getCPUTime)
import System.Timeout (timeout)
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
import PropRes (expandPropRes)
import ProofTree
  ( buildProofInfo, conjectureHypotheses, inlineAtomCongruences, headLitOf, isDerivedUnit, isFileSrc, isOrigAxiomDecl, isPositiveUnitFormula, unitNameStr
  , resolveCopySource
  )
import TptpConvert
import TweeInterface
import LemmaBuilder
import Theta (ThetaCtx (..), computeNucleusTheta, sharedNodeTheta, resolutionCoherent, derivedHead, explainStatus)
import Debug (dbg, ppLitI, ppClauseI, ppSimplChain, subrunDepth)

-- Rescue mode re-proves derived units mid-translation and retries ancestors
-- broadly.  It is off for the first attempt, so successful translations are
-- unchanged and pay nothing.  translate turns it on under a wall-clock budget
-- only for a second attempt after an incomplete result.  It is process-global
-- because nested runs must share one budget.
{-# NOINLINE rescueEnabled #-}
rescueEnabled :: IORef Bool
rescueEnabled = unsafePerformIO (newIORef False)

{-# NOINLINE rescueDeadline #-}
rescueDeadline :: IORef Double
rescueDeadline = unsafePerformIO (newIORef 0)

-- Unit names whose re-proof is currently being built somewhere up the call
-- stack.  A candidate's sub-problem contains the candidate itself as its
-- root, so without this guard the recursive translation would re-prove its
-- own root with the identical sub-problem, looping until the budget is gone.
{-# NOINLINE reproveInProgress #-}
reproveInProgress :: IORef (Set.Set String)
reproveInProgress = unsafePerformIO (newIORef Set.empty)

-- enabled and within the budget
rescueActive :: IO Bool
rescueActive = do
  en <- readIORef rescueEnabled
  if not en then return False else do
    dl  <- readIORef rescueDeadline
    now <- getMonotonicTime
    return (now < dl)

-- Recursive entry point, like translate but with a prebuilt name override map.
-- Overridden names are used as they are, so a lemma sub-proof cites the outer
-- proof's axiom list.
translateWith :: Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof)
translateWith nameOverride debug (T.TSTP _ units) = do
  case buildProofInfo units of
    Left _         -> return Nothing
    Right origInfo ->
      Just <$> runAlgorithm debug origInfo units Map.empty nameOverride Nothing

-- Recursive entry point for re-proving derived units mid-run.  A failure
-- inside the sub-run counts as no proof, and the re-proved unit only needs
-- some complete sub-proof.
translateCatching :: Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof)
translateCatching nameOverride debug tstp = do
  r <- try (translateWith nameOverride debug tstp)
         :: IO (Either ErrorCall (Maybe StructuredProof))
  return (fromRight Nothing r)

translate :: Bool -> T.TSTP -> IO (Either String StructuredProof)
translate debug tstp@(T.TSTP _ units) =
  fmap withTypes <$> translateUntyped debug (eraseSorts tstp)
  where
    -- a typed proof keeps its units as read, so the TPTP output can be typed too
    typed = [ () | T.Unit _ (T.Typing _ _) _ <- units ]
    withTypes sp
      | null typed = sp
      | otherwise  = sp { spInput = (spInput sp) { inTyped = units } }

translateUntyped :: Bool -> T.TSTP -> IO (Either String StructuredProof)
translateUntyped debug tstp = do
  writeIORef rescueEnabled False
  fallbackSecs <- startFallbackBudget
  r1@(mRes1, err1) <- runOnce
  (mRes, err) <- case mRes1 of
    Just _  -> return r1
    Nothing -> do
      -- incomplete, so make one more attempt with re-proving on, within
      -- TAELJA_RESCUE_TIMEOUT seconds (30 by default)
      budget <- timeoutSecsFromEnv "TAELJA_RESCUE_TIMEOUT" 30
      now    <- getMonotonicTime
      writeIORef rescueDeadline (now + fromIntegral budget)
      writeIORef rescueEnabled True
      when debug $ hPutStrLn stderr "translate: incomplete result; retrying with re-proving enabled"
      (mRes2, err2) <- runOnce
      return $ case mRes2 of
        Just _  -> (mRes2, err2)
        Nothing -> (Nothing, err2 <|> err1)
  -- both attempts produced nothing, so name the failure to make the run
  -- diagnosable without --debug
  spent <- fallbackBudgetSpent
  let failure = "translation failed"
        ++ (if spent then "; the fallback budget of " ++ show fallbackSecs ++ " s for Twee and E calls is spent" else "")
        ++ maybe "" ("; " ++) err
  return (maybe (Left failure) Right mRes)
  where
    -- a crash (e.g. an unprovable unit hitting an error call deep in the
    -- matcher) counts as no proof, with its message as the reason
    runOnce = do
      tStage <- getCPUTime
      when debug $ hPutStrLn stderr ("[time] start cpu=" ++ show (tStage `div` 1000000000) ++ " ms")
      r <- try (translateMode debug tstp) :: IO (Either SomeException (Either String StructuredProof))
      case r of
        Right (Right sp)     -> return (Just sp, Nothing)
        Right (Left reason)  -> return (Nothing, Just reason)
        Left e  -> do
          when debug $ hPutStrLn stderr ("translate: failed with: " ++ show e)
          return (Nothing, Just (takeWhile (/= '\n') (show e)))

-- The translation.  Lemma introduction comes first.  Every
-- derived clause used at least twice, unless it only copies an axiom, is
-- re-proved and translated recursively into a leaf named "lemma <tstp-name>".
-- The main translation and every lemma share one axiom numbering from the full
-- proof, and the emitted axiom list is the original one, so an axiom used only
-- inside a lemma is still listed.
translateMode :: Bool -> T.TSTP -> IO (Either String StructuredProof)
translateMode debug (T.TSTP _ units0) = do
  let units = expandPropRes (inlineAtomCongruences units0)
  depth <- subrunDepth
  when (depth == 0) clearLemmaCache
  case buildProofInfo units of
    Left reason -> return (Left reason)
    Right origInfo -> do
      let unitMap0 = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- units]
          origLeaves = piElectrons origInfo ++ piNuclei origInfo
          (origAxioms, origPosToName, _) =
            assignAxiomNames Map.empty negationConj (map convertLit (piGoalLits origInfo)) (piElectrons origInfo) (piNuclei origInfo) unitMap0
          negationConj = case conjectureHypotheses units of
            Just (_, cons) -> not (null cons)
            Nothing        -> False
          -- A source unit that clausifies to several axioms is remembered
          -- under one key per clause, since the display name belongs to the
          -- clause and not to the unit.  MGT001+1 states two axioms with the
          -- same body and different heads in one formula, and naming them by
          -- the unit alone made a step cite the other one.
          namedOrig =
            [ (leName e, k, nm)
            | (e, k) <- [ (e, electronNameKey unitMap0 e) | e <- piElectrons origInfo ]
                     ++ [ (e, nucleusNameKey e)           | e <- piNuclei origInfo ]
            , leRole e == OrigAxiom
            , Just nm <- [Map.lookup (lePos e) origPosToName] ]
          uniqueNames tagged = Map.fromList
            [ (src, nm)
            | (src, nms) <- Map.toList (Map.fromListWith Set.union tagged)
            , [nm] <- [Set.toList nms] ]
          origTstp2name = Map.union
            (uniqueNames [ (k, Set.singleton nm)      | (_, k, nm) <- namedOrig ])
            (uniqueNames [ (src, Set.singleton nm)    | (src, _, nm) <- namedOrig ])
          origAxiomNames = Set.fromList [ leName e | e <- origLeaves, leRole e == OrigAxiom ]
          -- An axiom or a hypothesis the conjecture grants is stated, not
          -- proved, so it is no lemma candidate.  LCL888+1/E's hypothesis
          -- esk3_0 = ==>(esk3_0, esk2_0) became a lemma whose one rewrite
          -- step cited that lemma itself.
          candidates = filter (\(cname, _) ->
                          resolveCopySource unitMap0 cname `Set.notMember` origAxiomNames
                          && cname `Set.notMember` origAxiomNames)
                        (findLemmaCandidates units)
      -- A candidate lemma is an optimisation, so a failing sub-translation inlines
      -- that step instead of abandoning the proof.  Without this catch the first
      -- throwing candidate ends the whole run.  The cost is that every candidate
      -- runs to completion, and HEN010-3/vampire goes from 13 s to 147 s.
      candResults <- forM candidates $ \c -> do
        r <- liftIO (try (buildCandidateLemma translateWith unitMap0 origTstp2name debug c))
        case r of
          Right v -> return v
          Left e  -> do
            when debug $ liftIO $ hPutStrLn stderr
              ("buildCandidateLemma: " ++ fst c ++ " failed, inlining instead: " ++ show (e :: ErrorCall))
            return Nothing
      let builtCands =
            [ (cname, r) | ((cname, _), Just r) <- zip candidates candResults ]
          -- A candidate's sub-proof may rest on a file axiom the outer
          -- refutation never used, which it numbered in its own run.  Those
          -- axioms are given outer numbers here and the lifted blocks are
          -- renamed to match, so the emitted proof states every axiom it
          -- cites (LCL126-1/E re-proves through q_3).  Identical axioms
          -- introduced by several candidates share one outer number.
          origNames = Set.fromList (map axiomDisplayName origAxioms)
          mergeCands accA []                            = (accA, [])
          mergeCands accA ((cname, (l, blk, lifted, own)) : rest) =
            let (accA', ren) = foldl addOne (accA, Map.empty) own
                addOne (as, m) a =
                  case find (sameAxiomStatement a) (origAxioms ++ as) of
                    Just existing ->
                      (as, Map.insert (axiomDisplayName a) (axiomDisplayName existing) m)
                    Nothing ->
                      let nm = nextOuterName (origAxioms ++ as)
                      in (as ++ [renameAxiom nm a], Map.insert (axiomDisplayName a) nm m)
                rn n         = Map.findWithDefault n n ren
                blk'         = renameRefsBlock rn blk
                lifted'      = [ (n, ll, renameRefsBlock rn bb) | (n, ll, bb) <- lifted ]
                (restA, restC) = mergeCands accA' rest
            in (restA, (cname, (l, blk', lifted', [])) : restC)
          nextOuterName as =
            head [ nm | i <- [1 :: Int ..], let nm = "axiom " ++ show i
                 , nm `Set.notMember` origNames
                 , nm `notElem` map axiomDisplayName as ]
          (extraAxioms, mergedCands) = mergeCands [] builtCands
          validCands   = Map.fromList mergedCands
          allAxioms    = origAxioms ++ extraAxioms
          candOverride = Map.fromList [ (c, "lemma " ++ c) | c <- Map.keys validCands ]
          nameOverride = Map.union candOverride origTstp2name
          modUnits = map replace units
          replace u@(T.Unit n _ _)
            | Map.member (unitNameStr n) validCands = makeFileSourced u
            | otherwise                             = u
          replace u = u
          -- the input units behind the axioms, for the TPTP output
          input = ProofInput
            { inAxiomUnits = Map.fromList
                [ (nm, u) | e <- origLeaves, leRole e == OrigAxiom
                          , Just nm <- [Map.lookup (lePos e) origPosToName]
                          , Just u <- [Map.lookup (leName e) unitMap0] ]
            , inAxiomLeaves = Map.fromList
                [ (nm, leUnit e) | e <- origLeaves, leRole e == OrigAxiom
                                 , Just nm <- [Map.lookup (lePos e) origPosToName] ]
            , inGeneralized = []
            , inHypotheses = Map.fromList
                [ (nm, leUnit e) | e <- origLeaves, leHyp e
                                 , Just nm <- [Map.lookup (lePos e) origPosToName] ]
            , inConjecture = listToMaybe
                [ u | u@(T.Unit _ (T.Formula (T.Standard T.Conjecture) _) _) <- units ]
            , inUnits = units
            , inTyped = []
            , inNegated = negatedHyps
            }
          -- the hypotheses that the conjecture's negated conclusion supplied
          negatedHyps = case conjectureHypotheses units of
            Just (_, cons) | not (null cons) ->
              [ nm | e <- origLeaves, leHyp e
                   , Just nm <- [Map.lookup (lePos e) origPosToName]
                   , Just c <- [convertDeclToClause (leDecl e)]
                   , any (`clauseInstance` c) cons ]
            _ -> []
          withInput sp = checkChains (tightenChains (generalizeGoals (negationGoal (sp { spInput = input }))))
      -- A hypothesis the proof assumed must be granted by the conjecture, or
      -- the emitted theorem would be stronger than the conjecture states.  A
      -- positive clause from a negative position of the conjecture, as
      -- ? [Y] : ! [X] : (p(Y) => p(X)) yields, makes the refutation a case
      -- split, which no direct Horn proof presents.
      -- A hypothesis promising a witness is granted only at a term the
      -- prover's Skolemization named, so a witness variable must stand for a
      -- symbol the problem does not state.
      let problemSyms = Set.fromList
            [ f | T.Unit n d _ <- units, isFileSrc unitMap0 (unitNameStr n)
                , f <- fst (declSymbols d) ]
          witnessNamed sigma = and
            [ introduced t | (v, t) <- sigma, isWitnessVar v ]
          introduced t = case t of
            App f _ -> Set.notMember f problemSyms
            Const c -> Set.notMember c problemSyms
            Var _   -> False
          grants g c = maybe False witnessNamed (clauseInstanceSubst g c)
      case conjectureHypotheses units of
        Just (ante, cons) -> let granted = ante ++ cons in
          forM_ [ e | e <- origLeaves, leHyp e ] $ \e ->
            case convertDeclToClause (leDecl e) of
              Just c | not (any (\g -> grants g c) granted) ->
                error ("unsupported conjecture, its negation yields the positive clause "
                       ++ leUnit e ++ " from a negative position, so its proof is a case split")
              _ -> return ()
        Nothing -> return ()
      case (Map.null validCands, buildProofInfo modUnits) of
        (False, Right mainInfo) ->
          Right . withInput <$> runAlgorithm debug mainInfo modUnits validCands nameOverride (Just allAxioms)
        _ ->
          Right . withInput <$> runAlgorithm debug origInfo units Map.empty origTstp2name (Just origAxioms)

-- A conjecture whose conclusion is a negation is proved by assuming the
-- negated formula and deriving $false, so the goal is that one derivation.
-- The refutation's goal atoms are the body of the axiom that closed it, and
-- each got a block ending in the derivation of $false and a contradiction
-- line, of which the first block up to $false is kept.
negationGoal :: StructuredProof -> StructuredProof
negationGoal sp
  | null (inNegated (spInput sp)) = sp
  | otherwise = case [ b | (l, b) <- goals sp, l == falsumLit ] of
      b : _ -> sp { goals = [(falsumLit, b)] }
      []    -> case goals sp of
        -- a goal block built by the contradiction route derives $false and
        -- then restates the goal, and that derivation is the proof shown.
        -- Any other block proves an atom and not the negation, so the
        -- proof is not one of the conjecture, as PUZ129+2/Twee's block
        -- ending on property1(s,healthy,pos) was not.
        (_, blk) : _
          | blk' <- dropContradiction blk, blockConcludes falsumLit blk' ->
              sp { goals = [(falsumLit, blk')] }
          | otherwise ->
              error "the derivation of $false from the negated conclusion is not shown"
        []           -> sp
  where
    dropContradiction (HaveHence ls) = HaveHence (reverse (dropWhile isContra (reverse ls)))
    dropContradiction b              = b
    isContra (Hence _ ByContradiction) = True
    isContra _                         = False

-- The Skolem terms of a negated conjecture stand for its universal
-- variables, a constant for one under no existential quantifier and a
-- function term for one under some.  A term of the goal headed by a symbol
-- that occurs in no input unit is such a term, and when no axiom or lemma
-- mentions the symbol either the theorem holds for every value of the term,
-- so it is a variable again in the printed goal and in the hypotheses that
-- share it.  A Skolem term of the hypotheses alone stays, since a hypothesis
-- is a clause of its own and a variable there would be quantified within it,
-- while a free term ranges over the whole theorem.
-- Every printed chain step must be a rewrite by the statement it cites, as
-- the assembled proof states it.  The search may have rewritten with a
-- unit's original clause while the lemma promoted for it states the
-- instance the proof stored, and then the printed step cites a statement
-- that does not make it, as GRP658+1's lemma for f295 did.  A citation of
-- a hypothesis is stated by its clause, and a name the proof does not state
-- is left to the checkers.
checkChains :: StructuredProof -> StructuredProof
checkChains sp = case [ (n, rw, prev, cur) | (n, blk) <- blocks, Just (rw, prev, cur) <- [unjustified blk] ] of
    []            -> sp
    (n, rw, prev, cur) : _ ->
      error ("the chain of " ++ n ++ " has a step by " ++ rwName rw
             ++ " that the statement of " ++ rwName rw ++ " does not make: "
             ++ ppLitI (Eq prev cur) ++ " by " ++ maybe "?" (ppLitI . uncurry Eq) (Map.lookup (rwName rw) stated))
  where
    blocks = [ (n, b) | (n, _, b) <- lemmas sp ]
          ++ [ ("goal " ++ show i, b) | (i, (_, b)) <- zip [1 :: Int ..] (goals sp) ]
    stated = Map.fromList $
      [ (n, (a, b)) | AUnit n (Eq a b) <- axioms sp ]
      ++ [ (n, (a, b)) | (n, Eq a b, _) <- lemmas sp ]
    unjustified (EqChain start steps) = listToMaybe
      [ (rw, prev, cur) | ((rw, cur), prev) <- zip steps (start : map snd steps)
                        , Just eq <- [Map.lookup (rwName rw) stated]
                        , not (chainStepJustified eq prev cur) ]
    unjustified _ = Nothing

-- Bind the variables a rewrite chain introduces and its next step fixes, in
-- every lemma and goal block.  It runs on the assembled proof, where the
-- blocks state variables and no longer Theorem 1's fresh constants.
tightenChains :: StructuredProof -> StructuredProof
tightenChains sp = sp
  { lemmas = [ (n, l, tighten b) | (n, l, b) <- lemmas sp ]
  , goals  = [ (l, tighten b)    | (l, b)    <- goals sp ] }
  where
    tighten (EqChain start steps) = uncurry EqChain (tightenChainVars start steps)
    tighten b                      = b

generalizeGoals :: StructuredProof -> StructuredProof
generalizeGoals sp
  | null fresh = sp
  | otherwise  = sp { axioms = map renAx (axioms sp)
                    , goals  = [ (applyTermSubstLit sub l, applyTermSubstBlock sub b) | (l, b) <- goals sp ]
                    , spInput = (spInput sp) { inGeneralized = [ (v, t) | (t, Var v) <- sub ] } }
  where
    hypNames = Map.keysSet (inHypotheses (spInput sp))
    isHyp ax = Set.member (axiomDisplayName ax) hypNames
    axSyms (AUnit _ l)                 = litSymbols l
    axSyms (ANucleus _ (Clause bs mh)) = concatMap litSymbols bs ++ maybe [] litSymbols mh
    used  = Set.fromList (concatMap axSyms (filter (not . isHyp) (axioms sp))
                          ++ concat [ litSymbols l ++ blockSymbols b | (_, l, b) <- lemmas sp ]
                          ++ concat [ fs ++ ps | T.Unit _ d ann <- inUnits (spInput sp), isInputAnn ann
                                               , let (fs, ps) = declSymbols d ])
    isInputAnn Nothing                      = True
    isInputAnn (Just (T.File _ _, _))       = True
    isInputAnn _                            = False
    skolemHeaded t = case t of
      Const c -> Set.notMember c used && not (isRigidConst c)
      App f _ -> Set.notMember f used
      Var _   -> False
    -- the maximal such subterms of the goals
    maximal t | skolemHeaded t = [t]
              | App _ ts <- t  = concatMap maximal ts
              | otherwise      = []
    fresh0 = nub (concat [ maximal t | (l, _) <- goals sp, t <- foldLiteralTerms (: []) l ])
    -- A hypothesis may hold another instance of the same Skolem symbol, as
    -- SYN731+1/E's hypothesis p(Z,A,esk1_2(Z,A)) does beside the goal's
    -- esk1_2(X,X).  Reading the goal's term as a variable would then claim
    -- more than the proof shows, so such a symbol keeps its term.
    hypTerms = concat [ foldLiteralTerms subterms l
                      | ax <- axioms sp, isHyp ax, l <- axLits ax ]
    axLits (AUnit _ l)                 = [l]
    axLits (ANucleus _ (Clause bs mh)) = bs ++ maybeToList mh
    subterms t = t : case t of { App _ ts -> concatMap subterms ts; _ -> [] }
    headOf (Const c) = c
    headOf (App f _) = f
    headOf _         = ""
    loose = [ headOf t | t <- hypTerms, headOf t `elem` map headOf fresh0, t `notElem` fresh0 ]
    fresh = [ t | t <- fresh0, headOf t `notElem` loose ]
    sub   = [ (t, Var (name i t)) | (i, t) <- zip [1 :: Int ..] fresh ]
    name _ (Const c)  = "Sk_" ++ c
    name i (App f _)  = "Sk_" ++ f ++ "_" ++ show i
    name i _          = "Sk_" ++ show i
    renAx ax | isHyp ax = case ax of
                 AUnit n l                 -> AUnit n (applyTermSubstLit sub l)
                 ANucleus n (Clause bs mh) -> ANucleus n (Clause (map (applyTermSubstLit sub) bs) (fmap (applyTermSubstLit sub) mh))
             | otherwise = ax

-- The step layer.  A justification that cannot be established fails with
-- throwError, the state keeps every sound fact found before the failure, and
-- the enclosing nucleus or goal route emits nothing.  Plain error is reserved
-- for invariant violations.
type AlgM a = ExceptT String (StateT AlgState IO) a

-- The unit table holds each fact once, since duplicates multiply the
-- branching of every later premise search.
-- Theorem 1's fresh constants stand for variables the derivation never
-- determines.  They are rigid only while their nucleus is justified, and the
-- resulting fact holds for every value, so entries are stated with variables
-- again.  Doing it here keeps rc_ constants out of the table by construction.
addUnit :: UnitEntry -> AlgM ()
addUnit ue0 = modify $ \s ->
  let ue = ue0 { ueUnit = unrigidLit (ueUnit ue0)
               , ueProof = fmap unrigidBlock (ueProof ue0) } in
  let same u = ueName u == ueName ue && isJust (ueProof u) == isJust (ueProof ue)
               && isJust (matchLit (ueUnit u) (ueUnit ue)) && isJust (matchLit (ueUnit ue) (ueUnit u))
  in if any same (stUnits s) then s else s { stUnits = stUnits s ++ [ue] }

-- Run a translation step and report its failure instead of propagating it.
-- State changes made before the failure are kept.
attempt :: AlgM a -> AlgM (Either String a)
attempt = lift . runExceptT

nextCounter :: AlgM Int
nextCounter = do
  k <- gets stCounter
  modify $ \s -> s { stCounter = k + 1 }
  return k

-- unnamed locally derived electrons first, then named axioms
getElectrons :: String -> AlgM [UnitEntry]
getElectrons pos = gets $ \s ->
  let allUnits = stUnits s
      named    = filter (isJust . ueName) allUnits
      unnamed  = filter (\u -> isNothing (ueName u) && maybe True (< pos) (uePos u)) allUnits
  in unnamed ++ named

-- Whether a set of emitted goal literals could all be instances of the
-- conjecture's own goal literals (the template) under one shared
-- substitution.  Their free variables are existential (a universal
-- conjecture Skolemizes to a ground negation), so this unifies rather than
-- matches, exactly as the end-of-run invariant in runAlgorithm does.
goalsConsistentWith :: [Literal] -> [Literal] -> Bool
goalsConsistentWith template emitted =
  let emittedTagged  = [ suffixVarsLit ("_g" ++ show i) g | (i, g) <- zip [1 :: Int ..] emitted ]
      conjGoals      = map (suffixVarsLit "_c") template
      unifiesWith σ g = listToMaybe [ σ' | l <- conjGoals, Just σ' <- [unifyLits l g σ] ]
  in isJust (foldM unifiesWith [] emittedTagged)

emitGoalProof :: Literal -> ProofBlock -> AlgM ()
emitGoalProof lit blk = do
  -- A goal variable is existential (a universal conjecture Skolemizes to a
  -- ground negation), and several emit paths reach here with names thn never
  -- bound (clause copies rename apart).  When the block's own conclusion is
  -- an instance of the goal, the goal is emitted at that instance.
  let realBinding (_, t) = case t of { Var _ -> False; _ -> True }
      lit' | not (null (litFree lit))
           , Just c <- blockConcl blk
           , Just ρ <- matchLit lit c
           , any realBinding ρ = applySubst ρ lit
           | otherwise = lit
  dbgFlag <- gets stDebug
  liftIO $ dbg dbgFlag $ "[goal-emit] " ++ ppLitI lit'
  template <- gets stGoalTemplate
  existing <- gets (map fst . stGoals)
  -- Several code paths match a nucleus head against the goal template and emit
  -- here, and nothing else stops two of them grounding a shared template
  -- variable differently, as on SYN602-1.  Refusing here abandons the
  -- inconsistent path, so the search tries another derivation for that goal.
  axNuclei <- gets stAxNuclei
  -- a goal proved at a fresh constant holds for every value of it
  let litG = unrigidLit lit'
      blk' = orientToGoal axNuclei litG (unrigidBlock blk)
  -- a goal proved twice is one goal, as s__Object(s__Denmark) reached from
  -- both s__Object(X2) and s__Object(X6) on CSR117+1/E, and counting it twice
  -- would pass a conjecture with a conjunct left unproved
  if any (\e -> isJust (matchLit e litG) && isJust (matchLit litG e)) existing
    then return ()
  else if goalsConsistentWith template (existing ++ [litG])
    then modify $ \s -> s { stGoals = stGoals s ++ [(litG, blk')] }
    else throwError ("emitGoalProof: " ++ ppLitI litG
                      ++ " is inconsistent with an already-proven goal")

-- The goal block ends with the goal itself.  A conclusion that is the goal
-- equation read the other way round, as E prints b = a for a = b, is
-- re-oriented when the cited axiom derives that orientation from the same
-- premises too.  Otherwise the block is left as it is.
orientToGoal :: [(String, Clause)] -> Literal -> ProofBlock -> ProofBlock
orientToGoal axs goal@(Eq l r) blk@(HaveHence ls)
  | (Hence (Eq l' r') (ByAxiom nm) : older) <- reverse ls
  , l' == r, r' == l
  , Just (Clause bodyAbs (Just headAbs)) <- lookup nm axs
  , let (recent, rest) = break isHence older
        prems = reverse (map lineLit recent) ++ take 1 (map lineLit rest)
  , resolutionCoherent bodyAbs headAbs prems goal
  = HaveHence (init ls ++ [Hence goal (ByAxiom nm)])
  | otherwise = blk
  where
    isHence (Hence _ _) = True
    isHence _           = False
    lineLit (Have x _)  = x
    lineLit (And x _)   = x
    lineLit (Hence x _) = x
orientToGoal _ _ blk = blk

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
promoteToLemma lit blk
  | isEmptyBlock blk = error ("promoteToLemma: no proof for " ++ ppLitI lit)
  | otherwise = do
  -- Free head variables are universal.  Every premise is an axiom or lemma
  -- instance under the same bindings, so the block proves the lemma for all
  -- values.
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

-- promotes to a lemma if unnamed and runs buildBlk for a proof when needed.
-- An empty HaveHence block, returned when Twee cannot prove a derived relational
-- unit, is never promoted to a named lemma.  A named fact is stated with
-- variables rather than the fresh constants rigid while it was derived, which
-- matches the unit table the lookup below compares against.
ensureNamed :: Literal -> AlgM ProofBlock -> AlgM String
ensureNamed lit0 buildBlk0 = do
  let lit = unrigidLit lit0
      buildBlk = unrigidBlock <$> buildBlk0
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
                HaveHence [Have _ nm] -> return nm
                _                     -> promoteToLemma lit blk
    Nothing -> do
      blk <- buildBlk
      case blk of
        -- A single "have lit by name" is cited by name directly rather than wrapped
        -- in a trivial lemma.  This covers ground axiom instances and ground instances
        -- of non-ground lemmas.
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
tryRelLemma :: [UnitEntry] -> Literal -> Maybe String -> AlgM String
tryRelLemma units lit mPos = do
  let relOrEqUnits = filter (\ue' -> isJust (ueName ue') || isEqLit (ueUnit ue')) units
  mRes <- liftIO (callTwee InternalBudget relOrEqUnits lit)
  case mRes of
    Just (start, chain) | not (null chain) -> do
      steps <- mapM promoteChainStep chain
      promoteToLemma lit (EqChain start steps)
    _ -> do
      -- last resort, re-prove the unit from its ancestry like lemma introduction
      -- does, when its position is known
      mRe <- case mPos of
        Nothing  -> return Nothing
        Just pos -> do
          reprove <- gets stReprove
          liftIO (reprove pos)
      case mRe of
        Just bl -> do
          (glit, gblk) <- absorbReprove bl
          promoteToLemma glit gblk
        Nothing ->
          throwError ("ensureNamed: no proof found for: " ++ show lit)

-- Take over a re-proof's own axioms.  A sub-proof may rest on a file axiom the
-- input refutation never used, numbered inside its own run, and that number
-- means something else out here.  Each such axiom gets an outer number, reusing
-- one for the same statement, and the block and sub-lemmas are renamed to match.
-- Returns the lemma's statement and its block.
absorbReprove :: (Literal, ProofBlock, [(String, Literal, ProofBlock)], [Axiom])
              -> AlgM (Literal, ProofBlock)
absorbReprove (glit, gblk, subs, own) = do
  base  <- gets stBaseAxioms
  extra <- gets stExtraAxioms
  let addOne (as, m) a =
        case find (sameAxiomStatement a) (base ++ as) of
          Just existing ->
            (as, Map.insert (axiomDisplayName a) (axiomDisplayName existing) m)
          Nothing ->
            let nm = head [ n | i <- [1 :: Int ..], let n = "axiom " ++ show i
                          , n `notElem` map axiomDisplayName (base ++ as) ]
            in (as ++ [renameAxiom nm a], Map.insert (axiomDisplayName a) nm m)
      (extra', ren) = foldl addOne (extra, Map.empty) own
      rn n          = Map.findWithDefault n n ren
      gblk'         = renameRefsBlock rn gblk
      subs'         = [ (n, l, renameRefsBlock rn b) | (n, l, b) <- subs ]
  modify $ \st -> st { stExtraAxioms = extra', stLemmas = stLemmas st ++ subs' }
  -- A re-proof names the outer candidate lemmas it rests on as the outer run
  -- does, and one the tree never used as an electron is stated here, as
  -- lemma c_0_13 cited by the re-proof of c_0_36 on SWW967+1/E
  let cited stated = [ n | b <- gblk' : [ b' | (_, _, b') <- stated ], n <- blockRefNames b ]
      addCited = do
        st <- get
        let stated  = stLemmas st
            missing = nub [ n | n <- cited stated, n `notElem` [ m | (m, _, _) <- stated ]
                              , Map.member n (stCandLemmas st) ]
        unless (null missing) $ do
          put st { stLemmas = stated ++ concat [ es | n <- missing, Just es <- [Map.lookup n (stCandLemmas st)] ] }
          addCited
  addCited
  return (glit, gblk')

-- A non-ground atom's variables as fresh constants (for a prover call that
-- reads goal variables existentially), with the map that lifts them back.
skolemizeLitFresh :: Literal -> (Literal, [(String, Term)])
skolemizeLitFresh li =
  let pairs = [ (v, "skv_" ++ v) | v <- nub (litVars li) ]
  in ( applySubst [ (v, Const c) | (v, c) <- pairs ] li
     , [ (c, Var v) | (v, c) <- pairs ] )

-- Match body atom li against electron ki, giving σi.
-- Only the electron's variables may be bound.  Under θ the body atom is ground
-- up to fresh constants a match may not instantiate, so the electron is the
-- pattern and the body atom the target, in either equation orientation.  The
-- paper's τ was needed only while θ left body variables free.
tryMatch :: Literal -> Literal -> Maybe Subst
tryMatch li ki = matchLit ki li <|> matchLit (flipEq ki) li
  where
    flipEq (Eq l r) = Eq r l
    flipEq x        = x

-- The equation a chain step names, either a display name or the TSTP name of a
-- derived unit equation.
chainEqLookup :: AlgM (String -> Maybe (Term, Term))
chainEqLookup = do
  units <- gets stUnits
  eqs   <- gets stEqByName
  return (\nm -> findEqByName nm units <|> Map.lookup nm eqs)

-- The citation of a chain step.  A display name stays, and a derived unit is
-- justified and named here, so no rewrite step cites an internal name.
citeChainSteps :: [(RwStep, a)] -> AlgM [(RwStep, a)]
citeChainSteps = mapM cite
  where
    cite (rw, c) = do
      units <- gets stUnits
      let eqLit = uncurry Eq (rwEq rw)
          variantOf a b = isJust (matchLit a b) && isJust (matchLit b a)
          -- a named unit stating this equation (either orientation)
          isVariant u = variantOf (ueUnit u) eqLit || variantOf (ueUnit u) (flipLit eqLit)
          named = listToMaybe [ u | u <- units, isVariant u, isJust (ueName u) ]
          -- a derived unit proved under the nucleus that produced it, possibly
          -- the other way round from the prover's own statement of it
          proved = listToMaybe [ u | u <- units, isVariant u, isJust (ueProof u) ]
          -- the step's direction is read against the cited statement
          oriented u nm
            | variantOf (ueUnit u) eqLit = rw { rwName = nm }
            | otherwise = rw { rwName = nm, rwEq = (snd (rwEq rw), fst (rwEq rw)), rwDir = flipDir (rwDir rw) }
      case named of
        Just u | Just nm <- ueName u -> return (oriented u nm, c)
        _ -> case proved of
          Just u -> do
            nm <- ensureNamed (ueUnit u) (makeBlock u [] [])
            return (oriented u nm, c)
          Nothing -> do
            nameToPos <- gets stNameToPos
            case Map.lookup (rwName rw) nameToPos >>= \p -> find ((== Just p) . uePos) units of
              Nothing -> throwError ("rewrite step cites an unknown unit: " ++ rwName rw)
              -- The unit is stored as the instance the proof derived, which
              -- a demodulation may have simplified further, and a lemma
              -- states that instance.  The step applied the prover's clause,
              -- so the two must state one equation, or the lemma would be
              -- cited for a step it does not make, as GRP658+1's
              -- mult(rd(X,mult(X,X)),X) = rd(Y,Y) was for f295.
              Just u
                | isVariant u -> do
                    nm <- ensureNamed (ueUnit u) (makeBlock u [] [])
                    return (oriented u nm, c)
                | otherwise ->
                    throwError ("rewrite step by " ++ rwName rw ++ " is stated as "
                                ++ ppLitI (ueUnit u) ++ ", not as the equation it applied")

-- raw derived electrons with no proof are excluded since Twee cannot justify them later
tweableUnits :: [UnitEntry] -> [UnitEntry]
tweableUnits = filter (\u -> isJust (ueName u) || isJust (ueProof u))

-- Horn axioms that are purely relational (no equality heads or bodies).
-- Equality-headed/bodied axioms break the ifeq+pair Twee encoding.
isRelHornAxiom :: HornAxiomEntry -> Bool
isRelHornAxiom ha = not (isEqLit (haHead ha)) && not (any isEqLit (haBodies ha))

-- Promote one step from a Twee chain into a named proof step (eq or relational).
promoteChainStep :: (UnitEntry, Dir, Term) -> AlgM (RwStep, Term)
promoteChainStep (stepUe, dir, cur) = do
  nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
  return (RwStep nm (unitEquation (ueUnit stepUe)) dir, cur)

tweeChain :: TweeBudget -> Term -> Term -> [UnitEntry] -> AlgM (Maybe ProofBlock)
tweeChain budget l r units = do
  mRes <- liftIO (callTwee budget units (Eq l r))
  case mRes of
    Nothing              -> return Nothing
    Just (_, [])         -> return Nothing
    Just (start, chain) -> do
      steps <- mapM promoteChainStep chain
      return (Just (EqChain start steps))

-- Algorithm 3 find_elec.  Step 1 is a pure match, and step 2 is rw_chain with
-- Twee as fallback when the demodulation chain is absent or empty, then tryMatch.
processBody
  :: [Literal]
  -> Subst
  -> [UnitEntry]
  -> Map.Map String [(String, Dir)]
  -> String
  -> Bool     -- include unnamed proof-less ground units in step 1
  -> AlgM (Maybe (Subst, [(UnitEntry, Subst, [(RwStep, Literal)])]))
processBody = processBodyAccept (\_ _ -> True)

type Matched = [(UnitEntry, Subst, [(RwStep, Literal)])]

-- The premise instances a match establishes.
targetsOf :: Matched -> [Literal]
targetsOf matched = [ electronTarget ki σi rwi | (ki, σi, rwi) <- matched ]

-- processBody whose solutions must pass a predicate on the complete match,
-- the coherence of the hyperresolution step.  A rejected solution backtracks
-- to the next candidate.
processBodyAccept
  :: (Subst -> Matched -> Bool)
  -> [Literal] -> Subst -> [UnitEntry] -> Map.Map String [(String, Dir)] -> String -> Bool
  -> AlgM (Maybe (Subst, Matched))
processBodyAccept accept lits thn elecs simpl pos allowGroundUnnamed = do
  failedRef <- liftIO (newIORef Set.empty)
  processBodyWith accept failedRef lits thn elecs simpl pos allowGroundUnnamed

-- processBody with a memo of failed sub-searches.  A search with the same
-- remaining literals, the same premises so far and the same unit table fails
-- again.
processBodyWith
  :: (Subst -> Matched -> Bool)
  -> IORef (Set.Set (String, Int))
  -> [Literal] -> Subst -> [UnitEntry] -> Map.Map String [(String, Dir)] -> String -> Bool
  -> AlgM (Maybe (Subst, Matched))
processBodyWith accept failedRef lits thn elecs simpl pos allowGroundUnnamed = goMemo lits thn [] [] []
  where
    -- acc holds the premises matched so far, innermost first.
    -- A premise whose electron variable was identified with a nucleus variable is
    -- fine while that variable stays free, since premise and head share it.  When a
    -- later body literal grounds it the two diverge.  The premise is emitted general
    -- and its variable must then be fresh, or inlined into a lemma it reads as the
    -- lemma's bound variable and the step is unverifiable, as on SYN163-1.
    finish thn' acc =
      let matched = map freshenGrounded (reverse acc)
          usedVars = concatMap litVars lits
                  ++ concat [ litVars (ueUnit ki) ++ map fst σi ++ concatMap (termVars . snd) σi
                            | (ki, σi, _) <- acc ]
                  ++ concatMap (termVars . snd) thn'
          suffix = head [ sfx | n <- [1 :: Int ..], let sfx = concat (replicate n "_e")
                              , not (any (sfx `isSuffixOf`) usedVars) ]
          -- A nucleus variable mentioned in an electron binding identifies an electron
          -- variable with it.  Once a later match binds that nucleus variable, the
          -- general premise must not share its letter with the instantiated conclusion.
          -- So the nucleus variable is renamed to a fresh universal inside the binding,
          -- whether it is the whole binding (SYN163-1/E) or nested in a term
          -- (LCL430-2/Vampire).  tryBothSides binds an electron variable to its own
          -- renamed copy, which is not a nucleus variable and keeps its name.
          nucleusVars = concatMap litVars lits
          grounded    = [ (w, w ++ suffix) | w <- nub nucleusVars, isJust (lookup w thn') ]
          freshenGrounded (ki, σi, rwi) =
            (ki, [ (x, renameTerm grounded t) | (x, t) <- σi ], rwi)
      in return (if accept thn' matched then Just (thn', matched) else Nothing)
    searchKey thn' ls usedPos extra acc = do
      n <- gets (length . stUnits)
      return (show (map (applySubst thn') ls, map ueUnit extra, usedPos, targetsOf (reverse acc)), n)
    goMemo [] thn' _ _ acc = finish thn' acc
    goMemo ls thn' usedPos extra acc = do
      key    <- searchKey thn' ls usedPos extra acc
      failed <- liftIO (readIORef failedRef)
      if Set.member key failed
        then return Nothing
        else do
          r <- go ls thn' usedPos extra acc
          when (isNothing r) $ liftIO (modifyIORef' failedRef (Set.insert key))
          return r

    -- Three tiers.  First the direct sibling electron for the outermost body
    -- literal, then unnamed derived electrons nearest first, then named axiom
    -- electrons nearest first.
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

    go [] thn' _ _ acc = finish thn' acc
    go (li : rest) thn' usedPos extraElecs acc = do
      let liInst    = applySubst thn' li
      -- Trivially true literals t = t need no electron.  They come from Vampire's
      -- trivial_inequality_removal.
      if isTriviallyTrue liInst
        then go rest thn' usedPos extraElecs acc
        else doMatch liInst rest thn' usedPos extraElecs acc
    isTriviallyTrue (Eq a b) = a == b
    isTriviallyTrue _        = False
    doMatch liInst restLits thn' usedPos extraElecs acc = do
      let
          (unused, used') = partition (\e -> uePos e `notElem` usedPos) sortedElecs
          prioritized = unused ++ used'
          -- Instances derived from earlier body literals come first.  Second-pass
          -- nuclei with non-ground heads also take ground unnamed proof-less units, as
          -- concrete facts of the refutation that can ground body variables.
          step1Elecs  = filter (\ue -> isJust (ueName ue) || isJust (ueProof ue)
                                    || (allowGroundUnnamed
                                        && isNothing (ueName ue)
                                        && isNothing (ueProof ue)
                                        && null (litFree (ueUnit ue))))
                               (extraElecs ++ prioritized)
          -- All pure step-1 candidates (no IO)
          pureMatches = [ (ue, σi, thn', [])
                        | ue <- step1Elecs
                        , Just σi <- [tryMatch liInst (ueUnit ue)] ]
      dbgFlag <- gets stDebug
      liftIO $ dbg dbgFlag $ "[match] " ++ ppLitI liInst ++ " step1="
        ++ show [ fromMaybe (fromMaybe "" (uePos ue)) (ueName ue) ++ ":" ++ ppLitI (ueUnit ue) | (ue, _, _, _) <- pureMatches ]

      mBT <- tryAll pureMatches restLits usedPos extraElecs acc
      case mBT of
        Just res -> return (Just res)
        Nothing  -> do
          units <- gets stUnits
          -- Step 2 is rw_chain, the demodulation chain if present and Twee otherwise
          tryRwChain liInst thn' units prioritized restLits usedPos extraElecs acc

    tryAll [] _ _ _ _ = return Nothing
    tryAll ((ki, σi, thn'', rwi) : rest_cands) restLits usedPos extraElecs acc = do
      mResult <- complete ki σi thn'' rwi restLits usedPos extraElecs acc
      case mResult of
        Just res -> return (Just res)
        Nothing  -> tryAll rest_cands restLits usedPos extraElecs acc

    complete ki σi thn'' rwi restLits usedPos extraElecs acc =
      let newExtra = deriveInst ki σi : extraElecs
      in goMemo restLits thn'' (uePos ki : usedPos) newExtra ((ki, σi, rwi) : acc)

    -- rw_chain tries the demodulation chain for each candidate and Twee when it is absent or empty.
    tryRwChain liInst thn' units candidates restLits usedPos extraElecs acc = do
      eqOf <- chainEqLookup
      let demodMatches =
            [ (ue, σi, thn', rw)
            | ue <- candidates
            , let chain = maybe [] (\p -> Map.findWithDefault [] p simpl) (uePos ue)
            , not (null chain)
            , Just (kstar, rw) <- [rwChain eqOf (ueUnit ue) chain]
            , Just σi <- [tryMatch liInst kstar] ]
      mBT <- tryAll demodMatches restLits usedPos extraElecs acc
      case mBT of
        Just res -> return (Just res)
        Nothing  -> do
          mRes <- findElecIO liInst thn' pos units
          case mRes of
            Nothing              -> return Nothing
            Just (ki, σi, thn'', rwi) -> complete ki σi thn'' rwi restLits usedPos extraElecs acc

-- processBody with a greedy retry that tries literals in order, then reversed.
-- The reversed retry handles Horn clauses where the first literal's axiom match
-- commits to the wrong grounding, as axiom 4 in GRP001-5/E.
processBodyBidir
  :: [Literal] -> Subst -> [UnitEntry] -> Map.Map String [(String, Dir)] -> String -> Bool
  -> AlgM (Maybe (Subst, Matched))
processBodyBidir = processBodyBidirAccept (\_ _ -> True)

processBodyBidirAccept
  :: (Subst -> Matched -> Bool)
  -> [Literal] -> Subst -> [UnitEntry] -> Map.Map String [(String, Dir)] -> String -> Bool
  -> AlgM (Maybe (Subst, Matched))
processBodyBidirAccept accept lits thn elecs simpl pos allow = do
  mRes <- processBodyAccept accept lits thn elecs simpl pos allow
  case mRes of
    Just _  -> return mRes
    Nothing -> processBodyAccept accept (reverse lits) thn elecs simpl pos allow

-- Twee rw_chain fallback, used when the demodulation chain is absent or empty.
-- An equational literal calls Twee on the literal and recovers the electron
-- from the chain, falling back to a synthetic EqChain unit.  A relational
-- literal calls Twee with the predicate read as a function, falling back to
-- single-step rewriting when rewriting does not terminate.
findElecIO
  :: Literal -> Subst -> String
  -> [UnitEntry]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
findElecIO li thn pos units = case li of
  Eq l r -> do
    mRaw <- liftIO (callTwee InternalBudget (tweableUnits units) (Eq l r))
    case mRaw of
      Nothing       -> return Nothing
      Just (_, [])  -> return Nothing
      Just (_, chain) -> do
        mRes <- recoverElecFromTweeChain li thn chain
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
                  , not (null (litFree (ueUnit u)))
                  , maybe True isEqChain (ueProof u)  -- skip HaveHence-proved units
                  , Just σg <- [matchLit (ueUnit u) li]
                  ]
            case mGenMatch of
              Just (genU, σg) -> return (Just (genU, σg, thn, []))
              Nothing -> do
                steps' <- mapM promoteChainStep chain
                let blk = EqChain l steps'
                    ki  = UnitEntry Nothing li (Just blk) (Just pos)
                addUnit ki
                return (Just (ki, [], thn, []))
  _ -> do
    let hhElecs    = [ u | u <- units, isNothing (ueName u), hasHenceProof u ]
        namedElecs = [ u | u <- units, isJust (ueName u) ]
        srcElecs   = hhElecs ++ namedElecs
        eqEntries  = filter (isEqLit . ueUnit) (tweableUnits units)
    mRw <- matchViaRw li thn srcElecs eqEntries
    case mRw of
      Just res -> return (Just res)
      Nothing  -> do
        -- First try the fast unit-only Twee call.  Without an equational unit Twee
        -- could only close P(t) ≈ true by the instantiation already tried, so the call
        -- is skipped, since in relational problems like LCL it burned its budget for
        -- every failed body atom.  A non-ground atom is a universal claim, so its
        -- variables become fresh constants for the call.  Twee reads goal variables
        -- existentially, and the chain is lifted back afterwards.
        let (liSk, undoSk) = skolemizeLitFresh li
        mRaw <- if null eqEntries then return Nothing
                else liftIO (callTwee InternalBudget (tweableUnits units) liSk)
        case fmap (second (map (\(u, d, t) -> (u, d, applyConstSubstTerm undoSk t)))) mRaw of
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
                return (Just (ki, [], thn, []))
              else tryHornThenReprove
          _ -> tryHornThenReprove
        where
          start = atomTerm li
          -- A Twee refutation shows only an instance of a non-ground atom, which cannot
          -- certify a general electron, so only ground atoms get the budgeted call.
          tryHornThenReprove = do
            mH <- tryHornFallback
            case mH of
              Just r  -> return (Just r)
              Nothing -> tryReproveElec
          -- last resort, an unnamed proof-less derived unit matching the body atom is
          -- re-proved from its ancestry and promoted to a lemma, since its nucleus may
          -- have been skipped before its own premises had proofs
          tryReproveElec = do
            reprove <- gets stReprove
            let cands = [ (u, pos', σi, thn)
                        | u <- units
                        , isNothing (ueName u), isNothing (ueProof u)
                        , Just pos' <- [uePos u]
                        , Just σi <- [tryMatch li (ueUnit u)] ]
                tryOne (u, pos', σi, thnU) = do
                  mRe <- liftIO (reprove pos')
                  case mRe of
                    Nothing -> return Nothing
                    Just bl -> do
                      (glit, gblk) <- absorbReprove bl
                      nm <- promoteToLemma glit gblk
                      return (Just (u { ueName = Just nm }, σi, thnU, []))
                goRe [] = return Nothing
                goRe (c:cs) = tryOne c >>= maybe (goRe cs) (return . Just)
            dbgFlag <- gets stDebug
            liftIO $ dbg dbgFlag $ "[reprove-elec] " ++ ppLitI li ++ " candidates="
              ++ show [ pos' | (_, pos', _, _) <- cands ]
            goRe cands
          tryHornFallback = do
            hornAxioms <- gets stHornAxioms
            -- Exclude axioms with equational heads or bodies.  The ifeq encoding makes
            -- equational bodies unconditional and equational heads vanish.
            let filteredHornAxioms = filter isRelHornAxiom hornAxioms
                -- variables as fresh constants, as for callTwee above
                (liSk, _) = skolemizeLitFresh li
            mRes <- liftIO $ callTweeRelLemma InternalBudget (tweableUnits units) filteredHornAxioms liSk
            case mRes of
              Just (_, chain) | not (null chain) -> do
                let axiomNms = nub [ nm | (ue, _, _) <- chain
                                        , not (isInternalUnit ue)
                                        , Just nm <- [ueName ue] ]
                -- A Horn axiom matched by its head alone says nothing about
                -- its premises, and the chain discharged them through units
                -- it does not name, so citing it would print "hence L by
                -- axiom N" with no premise stated.  Only a unit rule is a step.
                case axiomNms of
                  [nm] | not (any (\ha -> haDispName ha == Just nm && not (null (haBodies ha))) hornAxioms) -> do
                    let blk = HaveHence [Hence li (ByAxiom nm)]
                        ki  = UnitEntry Nothing li (Just blk) (Just pos)
                    addUnit ki
                    return (Just (ki, [], thn, []))
                  _ -> return Nothing
              _ -> return Nothing
-- Recover the electron from a Twee equational chain by finding the HaveHence
-- electron among its participants, then try single-step rewriting to match li.
recoverElecFromTweeChain
  :: Literal -> Subst
  -> [(UnitEntry, Dir, Term)]
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
recoverElecFromTweeChain li thn chain = do
  let chainUes  = map (\(ue, _, _) -> ue) chain
      hhElecs   = filter hasHenceProof chainUes
      eqEntries = filter isEq chainUes
  matchViaRw li thn hhElecs eqEntries
  where
    isEq ue = case ueUnit ue of { Eq _ _ -> True; _ -> False }

-- For each candidate electron, try (a) direct match and (b) single-step rewriting
-- with each available equation, checking if the result matches li.
-- Fallback for cases Twee cannot handle (e.g. non-terminating rewrite rules).
matchViaRw
  :: Literal -> Subst
  -> [UnitEntry]  -- candidate electrons (HaveHence or named)
  -> [UnitEntry]  -- candidate equation units
  -> AlgM (Maybe (UnitEntry, Subst, Subst, [(RwStep, Literal)]))
matchViaRw li thn srcElecs eqEntries = firstJustM tryElec srcElecs
  where
    firstJustM _ [] = return Nothing
    firstJustM f (x:xs) = f x >>= \case
      Just r  -> return (Just r)
      Nothing -> firstJustM f xs

    tryElec u = case tryMatch li (ueUnit u) of
      Just σi -> return (Just (u, σi, thn, []))
      Nothing        -> firstJustM (tryRw u) eqEntries

    tryRw u eq
      | ueUnit u == ueUnit eq = return Nothing
    tryRw u eq = case ueUnit eq of
      Eq sa sb -> case listToMaybe
                    [ (dir, res, σi, thn)
                    | dir <- [LR, RL]
                    , res <- rewriteLitAll (ueUnit u) (sa, sb) dir
                    , Just σi <- [tryMatch li res] ] of
        Nothing -> return Nothing
        Just (dir, res, σi, thnR) -> do
          nm <- getEqName eq
          case nm of
            Nothing -> return Nothing
            -- res is σi-instantiated here while the rwChain path returns uninstantiated
            -- literals.  electronTarget and makeBlock apply σi again, a no-op only while σi
            -- is idempotent.  Normalizing this needs a golden decision.
            Just n  -> return $ Just (u, σi, thnR, [(RwStep n (sa, sb) dir, applySubst σi res)])
      _ -> return Nothing

    getEqName eq = case ueName eq of
      Just n  -> return (Just n)
      Nothing -> case ueProof eq of
        Just _  -> Just <$> ensureNamed (ueUnit eq) (makeBlock eq [] [])
        Nothing -> return Nothing

-- rwSteps come from rwChain on the uninstantiated electron, and σi is applied
-- so the output reads "hence p(a)" rather than "hence p(X)"
makeBlock :: UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
makeBlock ki σi rwSteps = do
  units <- gets stUnits
  base  <- buildBase units
  rwStepsInst <- citeChainSteps (map (second (applySubst σi)) rwSteps)
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
                  return (instantiateBlock (ueUnit unnamed) σi stored)
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
                          else return (instantiateBlock (ueUnit genU) σg stored)
                    _ -> namedCase units
        Nothing -> namedCase units

    namedCase units =
      case find (\u -> ueUnit u == ueUnit ki) units of
        Just u ->
          case ueName u of
            Just nm -> return (HaveHence [Have lit nm])
            Nothing -> do
              -- unnamed unit with no stored proof, so try to name it via Twee
              case ueUnit u of
                Eq l r -> do
                  let namedUs = filter (isJust . ueName) units
                  mBlk <- tweeChain InternalBudget l r namedUs
                  case mBlk of
                    Just blk -> do
                      nm <- ensureNamed (ueUnit u) (return blk)
                      return (HaveHence [Have lit nm])
                    Nothing -> do
                      -- Twee cannot derive it from named units alone, so re-prove it from its
                      -- ancestry as lemma introduction would
                      mRe <- case uePos u of
                        Nothing  -> return Nothing
                        Just pos -> do
                          reprove <- gets stReprove
                          liftIO (reprove pos)
                      case mRe of
                        Just bl -> do
                          (glit, gblk) <- absorbReprove bl
                          nm <- promoteToLemma glit gblk
                          return (HaveHence [Have lit nm])
                        Nothing ->
                          -- no justification, so the step fails and the other stage or the rescue
                          -- pass gets its chance
                          throwError ("makeBlock: cannot prove unnamed eq unit: " ++ ppLitI (ueUnit ki))
                _ -> do
                  let namedUnits = filter (isJust . ueName) units
                      mNamed = listToMaybe
                        [ nm | nu <- namedUnits
                             , Just nm <- [ueName nu]
                             , Just _  <- [matchLit (ueUnit nu) lit] ]
                  case mNamed of
                    Just nm -> return (HaveHence [Have lit nm])
                    Nothing -> do
                      nm <- tryRelLemma units lit (uePos u)
                      return (HaveHence [Have lit nm])
        Nothing ->
          -- ki may be an instance from deriveInst never added to stUnits on its own.
          -- Search for an original entry whose atom matches it under some σg and
          -- instantiate its stored proof with σg.  Prefer an entry with a name or proof,
          -- since a proofless entry can state the same fact and shadow the derived unit
          -- whose proof exists, as on RNG008-5.
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
                      | otherwise -> return (instantiateBlock (ueUnit u) sg stored)
                    Nothing ->
                      throwError ("makeBlock: unit not in table: " ++ ppLitI (ueUnit ki))
            Nothing ->
              throwError ("makeBlock: unit not in table: " ++ ppLitI (ueUnit ki))

electronTarget :: UnitEntry -> Subst -> [(RwStep, Literal)] -> Literal
electronTarget ki σi rw = case rw of
  [] -> applySubst σi (ueUnit ki)
  -- rw is computed on the uninstantiated electron and σi comes from its
  -- rewritten form, so σi is applied here too.  Otherwise a lemma is stated as
  -- q(g(X)) while its proof shows q(g(a)).
  _  -> applySubst σi (snd (last rw))

buildProofBlock
  :: [Literal]     -- the rule's body atoms, as the axiom states them
  -> [(UnitEntry, Subst, [(RwStep, Literal)])]
  -> Maybe String  -- axiom name for "hence L0 by name" (Nothing for inner nodes)
  -> Subst         -- thn
  -> Literal       -- head literal L0
  -> AlgM ProofBlock
-- unit clause with no body, asserted directly by the named axiom.  Without a
-- name nothing justifies the literal.
-- thn is applied here as on every other line of a block.  The raw head still
-- has variables θ binds, and asserting it uninstantiated claims more than the
-- axiom gives, as on RNG038-1 which Lean rightly rejects.
buildProofBlock _ [] mAxName thn headLit = case mAxName of
  Just ax -> return (HaveHence [Have (applySubst thn headLit) ax])
  Nothing -> throwError ("buildProofBlock: unjustified unit " ++ ppLitI (applySubst thn headLit))
buildProofBlock bodyAbs (m1@(k1, σ1, rw1) : rest) mAxName thn headLit = do
  blk1 <- makeBlock k1 σ1 rw1
  blk  <- foldM addAnd blk1 rest
  return $ case mAxName of
    Just ax -> appendLine blk (Hence concl (ByAxiom ax))
    Nothing -> blk
  where
    -- An equation holds up to symmetry, so θ may orient the head either way.  The
    -- conclusion is printed as it follows from the premises this block cites, so
    -- applying the named axiom reproduces it, as the Lean check does.
    concl = case derivedHead bodyAbs headLit
                   [ electronTarget ki σi rwi | (ki, σi, rwi) <- m1 : rest ] of
      Just d | d == flipLit headInst -> d
      _                              -> headInst
      where headInst = applySubst thn headLit
    addAnd blk (ki, σi, rwi) = do
      let targ = electronTarget ki σi rwi
      -- A non-ground premise instance of a derived electron with a stored proof is
      -- cited by the electron's own name, so the lemma stays general and every
      -- instance reuses it, as "p(a) by lemma 5" for "Lemma 5 p(X)".  Ground
      -- instances, rewritten premises and electrons without a stored proof name the
      -- instance with its proof.
      nm <- if null rwi && isJust (ueProof ki) && not (null (litFree targ))
              then ensureNamed (ueUnit ki) (makeBlock ki [] [])
              else do
                blki <- makeBlock ki σi rwi
                ensureNamed targ (return blki)
      return (appendLine blk (And targ nm))

-- Equational goals use an EqChain from the electron or Twee, and so do
-- relational goals with a Twee chain.  Other relational goals use HaveHence.
-- A non-empty rwi forces HaveHence so "hence … by rw" is preserved.
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
              -- the coherence judgement of processOneNucleus, so the instantiated axiom
              -- must derive the claimed goal
              let coherentA thn' m = resolutionCoherent bodyPats hdPat (targetsOf m) (applySubst thn' goalLit)
              mResR <- processBodyBidirAccept coherentA bodyG [] elecs simpl pos False
              dbgFlag <- gets stDebug
              case mResR of
                Nothing            -> tryEach rest elecs
                Just (thn', matched) -> do
                  liftIO $ dbg dbgFlag $ "[axjust] " ++ axName ++ " for " ++ ppLitI goalLit
                    ++ " premises=" ++ show (map ppLitI (targetsOf matched))
                  Just <$> buildProofBlock bodyPats matched (Just axName) thn' goalLit

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
  -- a negated conjecture clause keeps the negated formula as its source,
  -- which is no clause when it negates a universal, as Twee's
  -- ~ ! [X] : leq(X, ...) on KLE137+1, and then the clause the leaf states
  -- is the nucleus
  -- Its body equations are oriented as the conjecture states them, since
  -- the prover may have turned them round, and the goal is stated as the
  -- conjecture does.
  let leafCls = orientToGoals <$> convertDeclToClause (leDecl entry)
      orientToGoals (Clause bs mh) = Clause (map orientLit bs) mh
      statesGoal l = any (\g -> isJust (matchLit l g) || isJust (matchLit g l)) goalLits
      orientLit l@(Eq a b)
        | statesGoal l          = l
        | statesGoal (Eq b a)   = Eq b a
      orientLit l = l
  case convertDeclToClause (leSrcDecl entry) <|> leafCls of
    Nothing  -> do
      liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ") — could not convert to clause"
      return False
    Just cls ->
      let θ_local = computeNucleusTheta thetaCtx entry
          Clause bodyLitsAbs mHead = cls
          bodyLits = map (applySubst θ_local) bodyLitsAbs
          -- True for second-pass derived nuclei with non-ground heads, where ground
          -- unnamed proof-less facts are valid electrons
          allowGroundUnnamed = isNothing mAxName
                            && maybe False (not . null . litFree) mHead
      in do
        elecs   <- getElectrons pos
        let coherentStep thn' matched = case mHead of
              Just headLit -> resolutionCoherent bodyLitsAbs headLit (targetsOf matched) (applySubst thn' headLit)
              Nothing      -> True
        mResult <- processBodyAccept coherentStep bodyLits θ_local elecs simpl pos allowGroundUnnamed
        forM_ mResult $ \(thn'', m) -> liftIO $ dbg debug $ "[matched] pos=" ++ pos ++ " premises="
          ++ show (map ppLitI (targetsOf m)) ++ " head=" ++ maybe "-" (ppLitI . applySubst thn'') mHead
        case mResult of
          Nothing -> do
            liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ")"
                ++ "  body=[" ++ intercalate ", " (map ppLitI bodyLits) ++ "] — no matching electron found"
            -- If the head matches a goal literal, instantiate its free variables and
            -- retry processBody.
            case mHead of
              -- For a negated conjecture whose body literal has free variables, match the
              -- sibling derived electron to ground them, then retry so a rewriting match can
              -- be found.
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
                              Just (thn, matched) -> do
                                let pairs = zip goalLits matched
                                if null pairs then return False
                                else do
                                  blks <- forM pairs $ \(gl, (ki, σi, rwi)) -> do
                                    let gl' = applySubst σ_sib (applySubst thn gl)
                                    blk <- emitBlockForGoal gl' ki σi rwi
                                    return (gl', blk)
                                  -- the one body atom answers one goal, which
                                  -- need not be the first, so a block that
                                  -- concludes another atom is not emitted
                                  if all (uncurry blockConcludes) blks
                                    then do
                                      forM_ blks (uncurry emitGoalProof)
                                      return True
                                    else return False
                _ -> return False
              Just hl ->
                case listToMaybe [σ | gl <- goalLits, Just σ <- [matchLit hl gl]] of
                  Nothing   -> return False
                  Just σ_gl -> do
                    -- Ground the abstract body.  bodyLits already carries θ_local, so σ_gl over
                    -- it is a no-op and would mismatch the claimed head.
                    let bodyLitsG = map (applySubst σ_gl) bodyLitsAbs
                        headLitG  = applySubst σ_gl hl
                    let coherentG thn' m = resolutionCoherent bodyLitsAbs hl (targetsOf m) (applySubst thn' headLitG)
                    mResult2R <- processBodyBidirAccept coherentG bodyLitsG [] elecs simpl pos False
                    case mResult2R of
                      Nothing -> return False
                      Just (thn, matched) -> do
                        blk <- buildProofBlock bodyLitsAbs matched mAxName thn headLitG
                        let headInst = applySubst thn headLitG
                            -- Only store ground proofs from this extra goal-grounding attempt, since
                            -- the main path handles the abstract ones.
                            proofToStore = if null (litFree headInst) then Just blk else Nothing
                        when (isJust mAxName) $ do
                          addUnit (UnitEntry Nothing (unrigidLit headInst) (fmap unrigidBlock proofToStore) (Just pos))
                          case (proofToStore, blk) of
                            (Just _, EqChain {}) -> void (ensureNamed (unrigidLit headInst) (return (unrigidBlock blk)))
                            _ -> return ()
                        -- A named axiom emits the goal proof under its name.  A derived inner
                        -- nucleus searches the original axiom nuclei for a justification and
                        -- returns False if none is found.
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
          Just (thn, matched)  ->
            case mHead of
              -- ⊥ from a clause other than the negated conjecture means the axioms are
              -- contradictory, and every goal follows vacuously from $false
              Nothing | leRole entry /= NegConjecture, Just _ <- mAxName -> do
                blk <- buildProofBlock bodyLitsAbs matched mAxName thn falsumLit
                forM_ goalLits $ \gl ->
                  emitGoalProof gl (appendLine blk (Hence gl ByContradiction))
                return True
              Nothing ->
                -- ⊥, so emit goal proofs with thn instantiating any remaining variables
                case (goalLits, matched) of
                  ([gl], [(ki, σi, _)])
                    | isNothing (ueName ki)
                    , Just chain@(EqChain {}) <- ueProof ki ->
                        emitGoalProof (applySubst thn gl) (instantiateBlock (ueUnit ki) σi chain) >> return True
                  _ -> do
                    let pairs     = zip3 goalLits bodyLits matched
                        unmatched = drop (length matched) goalLits
                    if null pairs
                      then return False
                      else do
                        forM_ pairs $ \(gl, bl, (ki, σi, rwi)) -> do
                          -- thn binds the clause copy's variable names, which can differ from the
                          -- goal literal's, so remaining goal variables are instantiated by matching
                          -- the proved electron.  They are existential, so NUM025-1 emits less(b,b).
                          -- The goal literals can also disagree with the ⊥ nucleus's body entirely, as
                          -- when E prints epred atoms near ⊥ on SYO632-1.  Then the goal proved here is
                          -- the body atom's instance.
                          let gl0 = applySubst thn gl
                              targ = electronTarget ki σi rwi
                              gl' = case matchLit gl0 targ of
                                      Just ρ | not (null (litFree gl0)) -> applySubst ρ gl0
                                             | otherwise -> gl0
                                      Nothing | gl0 /= targ -> applySubst thn bl
                                      _ -> gl0
                          blk <- emitBlockForGoal gl' ki σi rwi
                          emitGoalProof gl' blk
                        forM_ unmatched $ \gl ->
                          throwError ("processOneNucleus: unmatched goal lit: " ++ ppLitI (applySubst thn gl))
                        return True
              Just headLit -> do
                blk0 <- buildProofBlock bodyLitsAbs matched mAxName thn headLit
                let headInst0 = applySubst thn headLit
                    nucChain  = Map.findWithDefault [] pos (tcSimpl thetaCtx)
                -- a demodulation the prover folded into this inference becomes explicit
                -- rewrite steps, and the derived unit is the conclusion the proof shows
                eqOf <- chainEqLookup
                (headInstA, blk) <- case rwChain eqOf headInst0 nucChain of
                  Just (h', steps) | not (null nucChain) -> do
                    steps' <- citeChainSteps steps
                    return (h', foldl applyRwLine blk0 steps')
                  _ -> return (headInst0, blk0)
                let electronTargets = map (\(ki,σi,_) -> applySubst σi (ueUnit ki)) matched
                    -- An equation head holds up to symmetry, and θ may orient
                    -- it either way (axiom "g(X) = g(Y) => X = Y" read off the
                    -- prover's own flipped body).  The block cites its premises
                    -- in one orientation, so the head is printed as it follows
                    -- from exactly those, and the step reads correctly.
                    headInst = case derivedHead bodyLitsAbs headLit electronTargets of
                      Just d | d == flipLit headInstA -> d
                      _                               -> headInstA
                    -- Two kinds of degenerate block are never stored.
                    -- A stale target, only for non-ground equational heads, has a free head
                    -- variable in a body literal that some electron target lacks, so greedy
                    -- matching grounded it there and retrieval elsewhere would be inconsistent.
                    -- HEN006-4 axiom 5 is an example.  Head-only variables are exempt.
                    -- A circular block has a body target equal to the head, so it proves the
                    -- literal from itself, as transitivity over two copies of axiom 7 did.
                    headVars = Set.fromList (litFree headInst)
                    bodyVarsAfterTau = Set.fromList
                      (concatMap (litFree . applySubst thn) bodyLits)
                    headBodyVars = headVars `Set.intersection` bodyVarsAfterTau
                    hasStaleTarget = isEqLit headLit
                                  && not (Set.null headBodyVars)
                                  && any (\t -> not (headBodyVars `Set.isSubsetOf`
                                                     Set.fromList (litFree t)))
                                         electronTargets
                    isCircular = headInst `elem` electronTargets
                    proofToStore = if isCircular || (not (Set.null headVars) && hasStaleTarget)
                                   then Nothing else Just blk
                -- inner nuclei (mAxName=Nothing) produce no "hence L0 by axiom",
                -- so skip storing them to avoid corrupting later proofs
                when (isJust mAxName) $ do
                  liftIO $ dbg debug $ "[store] pos=" ++ pos ++ " head=" ++ ppLitI headInst
                    ++ (if isJust proofToStore then "" else " (no proof)")
                  addUnit (UnitEntry Nothing (unrigidLit headInst) (fmap unrigidBlock proofToStore) (Just pos))
                  -- EqChains can't nest inside HaveHence, so promote immediately
                  case (proofToStore, blk) of
                    (Just _, EqChain {}) -> void (ensureNamed (unrigidLit headInst) (return (unrigidBlock blk)))
                    _ -> return ()
                -- Extra goal-grounding attempt.  The natural match may store a unit with a
                -- goal's head shape but other ground terms, as axiom 11 emits 0≤f-k while the
                -- goal is 0≤f-g.  If the head also matches a goal literal under another
                -- grounding σ_gl, retry processBody with the goal-grounded body so the goal
                -- unit is stored too.
                when (isJust mAxName) $ do
                  elecs2 <- getElectrons pos
                  let altGoalPairs = [ (σ, gl) | gl <- goalLits
                                                , not (isEqLit gl)
                                                , Just σ <- [matchLit headLit gl]
                                                , applySubst σ headLit /= headInst ]
                  case altGoalPairs of
                    [] -> return ()
                    ((σ_gl, _) : _) -> do
                      -- Ground the abstract body.  bodyLits already carries θ_local, so σ_gl over
                      -- it is a no-op and the retry would prove the θ instance while claiming the
                      -- goal instance.
                      let bodyLitsG = map (applySubst σ_gl) bodyLitsAbs
                          headLitG  = applySubst σ_gl headLit
                          coherentG thn' m = resolutionCoherent bodyLitsAbs headLit (targetsOf m) (applySubst thn' headLitG)
                      mResult2R <- processBodyBidirAccept coherentG bodyLitsG [] elecs2 simpl pos False
                      case mResult2R of
                        Nothing -> return ()
                        Just (thn', matched') -> do
                          blk2 <- buildProofBlock bodyLitsAbs matched' mAxName thn' headLitG
                          let headInst2 = applySubst thn' headLitG
                          addUnit (UnitEntry Nothing (unrigidLit headInst2) (Just (unrigidBlock blk2)) (Just pos))
                          case blk2 of
                            EqChain {} -> void (ensureNamed headInst2 (return blk2))
                            _ -> return ()
                          -- If the grounded head matches the goal, emit the proof now.
                          case listToMaybe [gl' | gl' <- goalLits
                                               , isJust (matchLit headInst2 gl')] of
                            Just gl' -> emitGoalProof gl' blk2
                            Nothing  -> return ()
                -- A nucleus whose head matches a goal under another grounding retries
                -- processBody with the goal-grounded body, so findElecIO can find unnamed
                -- ground electrons like E's inline spm steps in GRP001-5.  It fires only
                -- when the head instance matches a goal that is equational or the head
                -- has free variables.  The guard on litVars keeps ground-head nuclei from
                -- short-circuiting named axiom proofs of relational goals.
                -- headLit is flipped when needed so applySubst thn of it equals the goal.
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
                          , isEqLit gl || not (null (litFree headLit))
                          , Just p <- [orientedPair gl] ]
                case (mAxName, matchResult) of
                  (Nothing, Just (gl, headLitOr)) | not (null matched) -> do
                    let goalInst = applySubst thn headLitOr
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
                              Just (thn', _) -> do
                                let goalInst3 = applySubst thn' headLitG3
                                mBlk <- tryAxiomJustification goalInst3 simpl pos
                                case mBlk of
                                  -- thn' grounds the goal's variables.  They are existential, since a
                                  -- universal conjecture Skolemizes to a ground negation, so the goal is
                                  -- emitted at the proved instance, as less(b,b) on NUM025-1
                                  Just blk' -> emitGoalProof (applySubst thn' gl) blk' >> return True
                                  Nothing   -> return False
                      else return False

-- The goal literals no emitted goal proves.  An emitted goal proves one it
-- unifies with, in either orientation, since goals are emitted with their
-- fresh constants as variables again.  Counting emitted goals instead would
-- pass a conjunct proved twice for one proved never.
openGoalsOf :: [Literal] -> AlgM [Literal]
openGoalsOf goalLits = do
  emitted <- gets (map fst . stGoals)
  let proves e0 g = let e = suffixVarsLit "_e" e0
                    in isJust (unifyLits g e []) || isJust (unifyLits (flipLit g) e [])
  return (nub [ g | g <- goalLits, not (any (`proves` g) emitted) ])

processNuclei
  :: Bool  -- debug
  -> ThetaCtx     -- per-nucleus θ context
  -> [LeafEntry]
  -> Map.Map String String
  -> [Literal]
  -> Map.Map String [(String, Dir)]
  -> AlgM ()
processNuclei debug thetaCtx nuclei posToName goalLits simpl = do
  -- θ is one substitution over the whole tree, shown once with each binding
  -- tagged by the position its variable belongs to.
  -- inferences the replay could not account for exactly.  A failing nucleus
  -- almost always sits under one of these
  when debug $ do
    let st = tcStatus thetaCtx
    liftIO $ dbg True $ "replay: " ++ show (length [ () | (_, k) <- st, k == "strict" ]) ++ " strict"
      ++ concat [ ", " ++ p ++ "=" ++ k | (p, k) <- st, k /= "strict" ]
  when debug $ liftIO $ dbg True $ "θ = {"
    ++ intercalate ", " [ v ++ "@" ++ lePos e ++ "→" ++ ppTerm t
                        | e <- nuclei, (v, t) <- computeNucleusTheta thetaCtx e ] ++ "}"
  go nuclei
  where
    go [] = return ()
    go pending = do
      open0 <- openGoalsOf goalLits
      unless (null open0) $ do
        prevCount <- gets (length . stUnits)
        failed    <- processPass pending
        newCount  <- gets (length . stUnits)
        open2     <- openGoalsOf goalLits
        -- Retry only if new units were derived and the goal is still unproved.
        -- This handles Vampire FOF proofs where axiom leaves appear at deeper
        -- positions than refutation-chain inner nodes (string-sort ordering
        -- puts inner nodes first, but axioms may depend on each other).
        when (newCount > prevCount && not (null open2) && not (null failed)) $
          go failed

    processPass [] = return []
    processPass (entry : rest) = do
      open1 <- openGoalsOf goalLits
      if null open1
        then return []
        else do
          prevCount <- gets (length . stUnits)
          res       <- attempt (processOneNucleus debug thetaCtx entry posToName goalLits simpl)
          done      <- case res of
            Right d  -> return d
            Left msg -> do
              liftIO $ dbg debug $ "[skip] pos=" ++ lePos entry ++ " — " ++ msg
              return False
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
  -- bidirectional tryMatch handles free goal variables, and is only tried when
  -- one-way matching in both directions failed
  [ (ue, σi, goal)
  | ue <- units
  , isNothing (matchLit (ueUnit ue) goal)
  , isNothing (matchLit goal (ueUnit ue))
  , Just σi <- [tryMatch goal (ueUnit ue)]
  ]

-- reconstruct an equational proof from the demod chain at p_{G₁}
splitChain :: Term -> Term -> [(String, Dir)] -> (String -> Maybe (Term, Term)) -> ([(RwStep, Term)], [String])
splitChain l r chain eqOf =
    let result = if curL == curR then reverse leftSteps ++ reverseRight (reverse rightSteps) else []
    in (result, dropped)
  where
    (leftSteps, rightSteps, curL, curR, dropped) = foldl step ([], [], l, r, []) (reverse chain)

    step (ls, rs, accL, accR, drp) (nm, dir) =
      case eqOf nm of
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
      chainSteps <- case mChain of
            Just chain -> do
              eqOf <- chainEqLookup
              let (steps, dropped) = splitChain l r chain eqOf
              dbgFlag <- gets stDebug
              forM_ dropped $ \nm -> liftIO $ dbg dbgFlag ("[chain] step not replayable: " ++ nm)
              citeChainSteps steps
            Nothing    -> return []
      if not (null chainSteps)
        then emitGoalProof goal (EqChain l chainSteps)
        else do
          us <- gets stUnits
          let mDerivedUnit = listToMaybe
                [ u | u <- us
                    , isNothing (ueName u)
                    , isJust (tryMatch goal (ueUnit u))
                    , Just (HaveHence {}) <- [ueProof u] ]
          mDerivedBlk <- case mDerivedUnit of
            Nothing -> return Nothing
            Just u  -> Just <$> makeBlock u [] []
          case mDerivedBlk of
            Just blk -> emitGoalProof goal blk
            -- A reflexive goal comes from an existential conjecture, so if one side
            -- matches onto the other the instantiated goal holds by reflexivity.  Twee
            -- emits a reflexivity step and Vampire an equality_resolution here.
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
                  -- an equational goal can be the head of a Horn axiom such as antisymmetry,
                  -- so the axiom nuclei are searched before giving up, as on HEN010-3
                  mAx <- tryAxiomJustification goal simpl "z"
                  case mAx of
                    Just blk -> emitGoalProof goal blk
                    Nothing -> do
                      mAxF <- tryAxiomJustification (Eq r l) simpl "z"
                      case mAxF of
                        Just blk -> emitGoalProof (Eq r l) blk
                        Nothing ->
                          throwError ("no proof found for goal: " ++ ppLitI goal)
    _ -> do
      -- find_elec's second step, a proved unit rewritten into the goal by
      -- proved equations, as Twee's c29 on SEU303+1 rewrites
      -- finite(relation_image(a,relation_dom(a))) by the equation c13
      mRw <- if isJust (findUnitForGoal goal units) || not (null (litFree goal))
               then return Nothing
               else do
                 let srcElecs = [ u | u <- units, isNothing (ueName u), hasHenceProof u ] ++ [ u | u <- units, isJust (ueName u) ]
                 matchViaRw goal [] srcElecs (filter (isEqLit . ueUnit) (tweableUnits units))
      case findUnitForGoal goal units of
        Just (ue, ρ0, instGoal) -> do
          blk <- makeBlock ue ρ0 []
          emitGoalProof instGoal blk
        Nothing | Just (ki, σi, _, rwi) <- mRw -> do
          blk <- makeBlock ki σi rwi
          emitGoalProof goal blk
        Nothing -> do
          allElecs <- gets stUnits
          axNuclei <- gets stAxNuclei
          let provableElecs = filter (\ue -> isJust (ueName ue) || isJust (ueProof ue)) allElecs
              -- Only ground proof-less electrons, since non-ground literals cannot be
              -- promoted as named lemmas.
              prooflessElecs = filter (\ue -> isNothing (ueName ue) && isNothing (ueProof ue)
                                           && ueUnit ue /= goal
                                           && null (litFree (ueUnit ue))) allElecs
          -- Enrich to a fixed point so multi-step dependency chains are resolved.
          -- Each round tries one-step axiom matching and an EqChain via Twee.
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
                        -- Prefer reversed order, which grounds free variables before matching forward.
                        mRes <- processBodyBidir (reverse bodyG) [] elecs Map.empty "" False
                        case mRes of
                          Nothing            -> tryAxNuclei elecs rest
                          Just (thn', matched) ->
                            Just <$> buildProofBlock bodyPats matched (Just axName) thn' goal
          -- Use the full enriched set, so the reversed body order finds enriched lemmas
          -- in step 1 before falling back to Twee in step 2.
          mAxBlk <- tryAxNuclei (provableElecs ++ enriched) axNuclei
          case mAxBlk of
            Just blk -> emitGoalProof goal blk
            Nothing  -> do
              -- Fall back to Twee with the relational Horn axioms of stAxNuclei, re-reading
              -- stUnits so enriched lemmas serve as background.
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
                    , not (any isEqLit bodyPats) ]
              -- a goal with variables is universal and a Twee refutation shows only an
              -- instance, so the call is not made
              mRes <- if not (null (litFree goal)) then return Nothing
                      else liftIO $ callTweeRelLemma GoalBudget (tweableUnits units') (filteredHornAxioms ++ axHornAxioms) goal
              case mRes of
                Just (_, chain) | not (null chain) -> do
                  let hornSteps = nubBy (\(_, n1) (_, n2) -> n1 == n2)
                                    [ (ue, nm') | (ue, _, _) <- chain
                                                , not (isInternalUnit ue)
                                                , Just nm' <- [ueName ue] ]
                  -- The chain shows only that the goal follows from the cited rules, not a
                  -- hyperresolution derivation.  A single unit rule the goal instantiates is a
                  -- valid step and nothing else is.  A Horn axiom matched by its head alone says
                  -- nothing about its premises, so citing it would print an unjustified "have
                  -- GOAL by axiom N".  LCL359-1 collapsed a 5-step modus ponens chain that way.
                  let isUnitRule nm =
                        maybe True (\(Clause bs _) -> null bs) (lookup nm axNuclei)
                        && not (any (\ha -> haDispName ha == Just nm && not (null (haBodies ha))) hornAxioms)
                  case hornSteps of
                    [(ue', nm')] | isJust (matchLit (ueUnit ue') goal), isUnitRule nm' ->
                      emitGoalProof goal (HaveHence [Have goal nm'])
                    _ -> throwError ("no unit found for goal: " ++ ppLitI goal)
                _ -> throwError ("no unit found for goal: " ++ ppLitI goal)
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
                  let coherentO thn' m = resolutionCoherent bodyPats hdPat (targetsOf m) (applySubst thn' litToProve)
                  mRes <- processBodyBidirAccept coherentO bodyG [] elecs Map.empty "" False
                  case mRes of
                    Nothing            -> tryEach rest
                    Just (thn', matched) -> do
                      blk <- buildProofBlock bodyPats matched (Just axName) thn' litToProve
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
            startTerm = atomTerm lit
        mRes <- if not (null (litFree lit)) then return Nothing   -- instance proofs cannot justify a general electron
                else liftIO $ callTweeRelLemma InternalBudget (tweableUnits units') filteredHornAxioms lit
        -- A chain through a Horn rule carries the encoding's own steps, and
        -- with those left out the remaining steps do not follow one another
        -- and a rule is cited by its head alone, so only a chain of named
        -- units is a proof.
        case mRes of
          Just (_, chain)
            | not (null chain)
            , all (\(u, _, _) -> not (isInternalUnit u) && isJust (ueName u)) chain -> do
                let steps = [ (RwStep nm (unitEquation (ueUnit u)) dir, cur)
                            | (u, dir, cur) <- chain, Just nm <- [ueName u] ]
                    blk   = EqChain startTerm steps
                nm <- promoteToLemma lit blk
                return (Just (UnitEntry (Just nm) lit (Just blk) Nothing))
          _ -> return Nothing
      _ -> return Nothing

-- use the general source formula for OrigAxiom, falling back to the derived
-- literal when resolveSourceName traced through rewriting to an unrelated source
-- A unit whose stored proof is a have/hence block, which a chain may inline.
hasHenceProof :: UnitEntry -> Bool
hasHenceProof u = case ueProof u of { Just (HaveHence _) -> True; _ -> False }

-- The key an axiom's display name is remembered under, its source unit and
-- the clause it states, so one unit clausifying to several axioms keeps them
-- apart.
electronNameKey :: Map.Map String T.Unit -> LeafEntry -> String
electronNameKey unitMap e =
  leName e ++ "#" ++ clauseKey (Clause [] (Just (electronLit unitMap e)))

nucleusNameKey :: LeafEntry -> String
nucleusNameKey e =
  leName e ++ "#" ++ maybe "" clauseKey (convertDeclToClause (leSrcDecl e))

electronLit :: Map.Map String T.Unit -> LeafEntry -> Literal
electronLit unitMap e = case leRole e of
  OrigAxiom ->
    case Map.lookup (leName e) unitMap of
      Just (T.Unit _ srcDecl _) | Just srcLit <- headLitOf srcDecl ->
        let converted = convertLit srcLit
            flipped   = flipLit converted
        in case matchLit converted derivedLit <|> matchLit flipped derivedLit of
             Just _ -> converted  -- derived is an instance (possibly flipped) of source
             Nothing -> derivedLit  -- unrelated, since resolveSourceName traced through rewriting
      _ -> derivedLit
  _ -> derivedLit
  where
    derivedLit = case headLitOf (leDecl e) of
      Just lit -> convertLit lit
      Nothing  -> error ("electronLit: no head literal for " ++ leName e)

axiomDisplayName :: Axiom -> String
axiomDisplayName (AUnit n _)    = n
axiomDisplayName (ANucleus n _) = n

renameAxiom :: String -> Axiom -> Axiom
renameAxiom n (AUnit _ l)    = AUnit n l
renameAxiom n (ANucleus _ c) = ANucleus n c

-- Two axioms state the same thing when their statements agree up to variable
-- renaming, so a file axiom pulled in by two different candidate sub-proofs
-- gets one outer number rather than two.
sameAxiomStatement :: Axiom -> Axiom -> Bool
sameAxiomStatement (AUnit _ a) (AUnit _ b) =
  isJust (matchLit a b) && isJust (matchLit b a)
sameAxiomStatement (ANucleus _ (Clause b1 h1)) (ANucleus _ (Clause b2 h2)) =
  length b1 == length b2
    && and (zipWith variantLit b1 b2)
    && case (h1, h2) of
         (Just x, Just y) -> variantLit x y
         (Nothing, Nothing) -> True
         _ -> False
  where variantLit x y = isJust (matchLit x y) && isJust (matchLit y x)
sameAxiomStatement _ _ = False

-- nameOverride maps raw TSTP unit names to pre-assigned display names.
-- Overridden axioms are NOT added to the axiom list (they belong to an outer proof).
-- Names mapped to the empty string are silently skipped (used for internal Twee axioms).
assignAxiomNames
  :: Map.Map String String  -- TSTP name to display name, or empty to skip
  -> Bool                   -- the conjecture's conclusion is a negation, so a headless axiom stating the goals is listed
  -> [Literal]              -- goal literals, and a headless nucleus stating them is the goal clause
  -> [LeafEntry]
  -> [LeafEntry]
  -> Map.Map String T.Unit
  -> ([Axiom], Map.Map String String, [UnitEntry])
assignAxiomNames nameOverride negationConj goalLits0 electrons nuclei unitMap =
  let unitTags    = [(lePos e, Left e)  | e <- electrons, leRole e == OrigAxiom]
      nucleiTags = [(lePos e, Right e) | e <- nuclei,    leRole e == OrigAxiom]
      allLeaves   = sortBy (comparing fst) (unitTags ++ nucleiTags)
      (axiomList, posToName, _) = foldl step ([], Map.empty, Map.empty) allLeaves
      namedUnits =
        [ UnitEntry (Map.lookup (lePos e) posToName) (electronLit unitMap e) Nothing (Just (lePos e))
        | e <- electrons, leRole e == OrigAxiom ]
  in (axiomList, posToName, namedUnits)
  where
    -- an axiom is one clause of one source unit, so a FOF unit that
    -- clausifies to several clauses gives several axioms
    step (axAcc, posMap, seen) (pos, Left e) =
      let origKey = leName e
          lit     = electronLit unitMap e
          seenKey = electronNameKey unitMap e
      in case Map.lookup seenKey seen of
           -- An internal unit is recorded under the empty sentinel.  A later occurrence
           -- is skipped like the first, or the step prints a nameless "by".
           Just existingName | not (null existingName) ->
             (axAcc, Map.insert pos existingName posMap, seen)
           Just _ -> (axAcc, posMap, seen)
           Nothing ->
             case Map.lookup seenKey nameOverride <|> Map.lookup origKey nameOverride of
               Just nm | not (null nm) ->
                 -- Use the main proof's display name, which is already in the outer axiom list
                 (axAcc, Map.insert pos nm posMap, Map.insert seenKey nm seen)
               Just _ ->
                 -- The empty sentinel marks an internal Twee axiom, which is skipped
                 (axAcc, posMap, Map.insert seenKey "" seen)
               Nothing ->
                 let nm = freshAxiomName axAcc
                 in (axAcc ++ [AUnit nm lit],
                     Map.insert pos nm posMap,
                     Map.insert seenKey nm seen)

    step (axAcc, posMap, seen) (pos, Right e) =
      -- leSrcDecl preserves the original body-literal order and equation direction
      let origKey = leName e
          seenKey = nucleusNameKey e
      in case Map.lookup seenKey seen of
           -- An internal unit is recorded under the empty sentinel.  A later occurrence
           -- is skipped like the first, or the step prints a nameless "by".
           Just existingName | not (null existingName) ->
             (axAcc, Map.insert pos existingName posMap, seen)
           Just _ -> (axAcc, posMap, seen)
           Nothing ->
             case Map.lookup seenKey nameOverride <|> Map.lookup origKey nameOverride of
               Just nm | not (null nm) ->
                 (axAcc, Map.insert pos nm posMap, Map.insert seenKey nm seen)
               Just _ ->
                 (axAcc, posMap, Map.insert seenKey "" seen)
               Nothing ->
                 -- a headless clause stating the goals is the negated conjecture and gets
                 -- no axiom name, while any other headless clause is a negative fact and is
                 -- named like every other axiom
                 case convertDeclToClause (leSrcDecl e) of
                   Just cls@(Clause bs mh)
                     -- a hypothesis the conjecture grants is named even when
                     -- it reads like the negated conjecture, as SYN929+1's
                     -- p(Y) => $false from ~ ? [Y] : p(Y) does
                     | isJust mh || not (all isGoal bs) || leHyp e ->
                     let nm = freshAxiomName axAcc
                     in (axAcc ++ [ANucleus nm cls],
                         Map.insert pos nm posMap,
                         Map.insert seenKey nm seen)
                   _ -> (axAcc, posMap, seen)
    isGoal l = any (\g -> isJust (matchLit g l) || isJust (matchLit l g)) goalLits
    -- A headless file clause stating the goals is normally the negated
    -- conjecture, as in UEQ problems.  When the conjecture concludes a
    -- negation it is the axiom the proof closes with, listed like any other.
    goalLits | negationConj = []
             | otherwise    = goalLits0

    -- The next unused "axiom N".  Counting axAcc is wrong because leaves named
    -- by nameOverride are left out of it, so a sub-run with all outer axioms
    -- overridden would reuse "axiom 1", as LCL126-1/E did.  Every name the
    -- override can produce is reserved.
    freshAxiomName axAcc =
      head [ nm
           | i <- [1 :: Int ..]
           , let nm = "axiom " ++ show i
           , nm `Set.notMember` takenNames
           , nm `notElem` map axiomDisplayName axAcc ]
    takenNames = Set.fromList (filter (not . null) (Map.elems nameOverride))


runAlgorithm
  :: Bool
  -> ProofInfo
  -> [T.Unit]
  -> Map.Map String BuiltLemma   -- tstp_name → pre-built lemma (with lifted sub-lemmas)
  -> Map.Map String String       -- TSTP name to display name
  -> Maybe [Axiom]               -- canonical emitted axiom list, or Nothing to derive it from this tree
  -> IO StructuredProof
runAlgorithm debug info allUnits candLemmaMap nameOverride mFixedAxioms = do
  -- one re-proof attempt per tree position, so repeated failures are free
  reproveCache <- newIORef (Map.empty :: Map.Map String (Maybe BuiltLemma))
  let unitMap    = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      thetaCtx   = ThetaCtx (piDeclAt info)
                     simplAll (\nm -> findEqByName nm (namedUnits ++ listedAxiomUnits ++ bgNamedUnits)
                                     <|> Map.lookup nm eqByTstpName)
                     (sharedNodeTheta (piDeclAt info) (piNuclei info ++ piElectrons info))
                     (explainStatus (piDeclAt info) (piNuclei info ++ piElectrons info))
      nameToPos  = Map.fromList [ (leName e, lePos e) | e <- piElectrons info ]
      eqByTstpName = Map.fromList
        [ (unitNameStr n, (l, r))
        | T.Unit n decl _ <- allUnits
        , isPositiveUnitFormula decl
        , Just tl <- [headLitOf decl]
        , not (isReservedTLit tl)
        , Eq l r <- [convertLit tl] ]
      -- Goal j is G_jθ, the conjecture's goal literals instantiated as far as the
      -- proof determines, read off the negated conjecture nucleus closest to the
      -- root
      goalLits'  = instantiateGoals (map convertLit (piGoalLits info))
      instantiateGoals gs
        | all (null . litFree) gs = gs
        | otherwise = case solve [] openGoals of
            (σ : _) -> map (applySubst σ) gs
            []      -> map inst gs
        where
          goalNuclei = sortBy (comparing (\e -> (length (lePos e), lePos e)))
                         [ e | e <- piNuclei info, leRole e == NegConjecture ]
          instBodies = [ applySubst (computeNucleusTheta thetaCtx e) l
                       | e <- goalNuclei
                       , Just (Clause bs _) <- [convertDeclToClause (leDecl e)]
                       , l <- bs ]
          -- The goal literals share their variables, so one substitution must satisfy
          -- them all.  Instantiating each alone can give a variable two values, as
          -- PUZ011-1 read borders(X0,X1) as borders(indian,india) while african(X1)
          -- forces somalia.  matchLitWith threads the bindings so a contradicting choice
          -- is rejected and the search backtracks.  Each body atom answers one
          -- goal atom, or two goals with one predicate would take the same fact.
          openGoals = [ g | g <- gs, not (null (litFree g)) ]
          solve σ gs' = solveWith σ instBodies gs'
          solveWith σ _ []             = [σ]
          solveWith σ bodies (g : rest) =
            concat [ solveWith σ' (before ++ after) rest
                   | (before, b : after) <- zip (inits bodies) (tails bodies)
                   , Just σ' <- [matchEither g b σ] ]
          -- an equation of the conjecture may be written the other way round
          -- in the negated clause
          matchEither g b σ = listToMaybe
            [ σ' | g0 <- [g, flipLit g], Just σ' <- [matchLitWith g0 b σ], applySubst σ' g0 == b ]
          -- No assignment satisfies every open goal, when some goal atoms are not body
          -- atoms of the nucleus, so instantiate each alone as before.
          inst g = case [ applySubst ρ g | b <- instBodies, Just ρ <- [matchEither g b []] ] of
                     (g' : _) -> g'
                     []       -> g

      (rawAxiomList0, posToName0, namedUnits0) =
        assignAxiomNames nameOverride negationConj goalLits' (piElectrons info) (piNuclei info) unitMap
      -- With a fixed outer axiom list, a leaf the override could not name
      -- (its source clausified to several clauses) got a fresh number above,
      -- which may collide with an outer number, as ALG018+1/E's
      -- sorti2(X) => sorti2(esk2_1(X)) became axiom 1 beside the outer
      -- axiom 1.  Such an axiom takes the outer name of the axiom with its
      -- statement, or else a number beyond the outer list.
      (rawAxiomList, posToName, namedUnits, extraFixed) = case mFixedAxioms of
        Nothing    -> (rawAxiomList0, posToName0, namedUnits0, [])
        Just fixed ->
          let fixedNames = map axiomDisplayName fixed
              assign _ [] = []
              assign used (a : as) =
                let nm = axiomDisplayName a
                in case find (sameAxiomStatement a) fixed of
                     Just f -> (nm, axiomDisplayName f) : assign used as
                     Nothing
                       | nm `elem` fixedNames || nm `elem` used ->
                           let new = head [ n | i <- [1 :: Int ..], let n = "axiom " ++ show i
                                              , n `notElem` fixedNames, n `notElem` used ]
                           in (nm, new) : assign (new : used) as
                       | otherwise -> (nm, nm) : assign (nm : used) as
              ren = Map.fromList (assign [] rawAxiomList0)
              rn n = Map.findWithDefault n n ren
              renamed = [ renameAxiom (rn (axiomDisplayName a)) a | a <- rawAxiomList0 ]
          in ( renamed
             , Map.map rn posToName0
             , [ u { ueName = fmap rn (ueName u) } | u <- namedUnits0 ]
             , [ a | a <- renamed, axiomDisplayName a `notElem` fixedNames ] )
      negationConj = case conjectureHypotheses allUnits of
        Just (_, cons) -> not (null cons)
        Nothing        -> False

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
        Just fixed -> fixed ++ extraFixed
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
        , Just (lit, blk, lifted, _) <- [Map.lookup (leName e) candLemmaMap]
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
      simplAll = Map.fromList
        [ (lePos e, [(resolveSimplName n, d) | (n, d) <- leSimpl e])
        | e <- piElectrons info ++ piNuclei info, not (null (leSimpl e)) ]

      -- demodulation chain at the negated conjecture position, a fallback for splitChain
      pG1Chain = case find (\e -> leRole e == NegConjecture) (piNuclei info) of
        Just e | not (null (leSimpl e)) ->
          Just [(resolveSimplName n, d) | (n, d) <- leSimpl e]
        _ -> Nothing

      derivedUnits =
        [ UnitEntry Nothing lit mProof (Just (lePos e))
        | e <- filter (\e -> leRole e == Derived) (piElectrons info)
        , let lit    = electronLit unitMap e
              mProof = fmap (\(_, b, _, _) -> b) (Map.lookup (leName e) candLemmaMap)
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
        -- only positive unit clauses, since headLitOf strips the body of nuclei like
        -- comp(X,Y) → meet(X,Y) = zero and would create unsound axioms
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
      -- Unit axioms of the canonical list that are not leaves of this tree, used
      -- only inside a prebuilt lemma's cut-off derivation.  They are displayed under
      -- their names, so they are electrons here like every other axiom.
      listedAxiomUnits =
        [ UnitEntry (Just nm) lit Nothing Nothing
        | AUnit nm lit <- axiomList
        , nm `notElem` mapMaybe ueName namedUnits ]

      -- The nuclei are the non-unit leaf clauses, as the paper's collect_leaves
      -- returns them.  Derived inner nodes are what the algorithm reconstructs.
      allNuclei   = sortBy (comparing lePos)
                      (filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNuclei info))

      nAll = length axiomList + length bgAxiomList
      -- only nuclei with a display name can be cited
      axNucleiList = [ (nm, cl) | e <- piNuclei info
                                 , leRole e == OrigAxiom
                                 , Just nm <- [Map.lookup (lePos e) posToName]
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
      -- Re-prove the derived unit at a tree position from its ancestry via the
      -- lemma builder.  mFixedAxioms is Nothing exactly for the lemma builder's own
      -- recursive translations, which only get the sub-DAG route.  Its ancestry
      -- shrinks per level, so re-proving terminates.
      reproveAt pos = do
        active <- rescueActive
        if not active
          then do
            dbg debug ("[reprove] pos=" ++ pos ++ " inactive (rescue off or budget spent)")
            return Nothing
          else do
            cached <- readIORef reproveCache
            case Map.lookup pos cached of
              Just r  -> do
                dbg debug ("[reprove] pos=" ++ pos ++ " cached -> " ++ maybe "Nothing" (const "Just") r)
                return r
              Nothing -> do
                -- cap the attempt at the remaining rescue budget, and the prover children it
                -- spawned stop at their own caps
                dl  <- readIORef rescueDeadline
                now <- getMonotonicTime
                mr  <- timeout (max 0 (round ((dl - now) * 1e6))) (reproveAt' pos)
                let r = fromMaybe Nothing mr
                modifyIORef' reproveCache (Map.insert pos r)
                return r
      reproveAt' pos =
        case find (\e -> lePos e == pos) (piElectrons info ++ piNuclei info) of
          Just e | Just (T.Unit _ cdecl _) <- Map.lookup (leName e) unitMap -> do
            inProg <- readIORef reproveInProgress
            if Set.member (leName e) inProg
              then do
                dbg debug ("[reprove] pos=" ++ pos ++ " name=" ++ leName e ++ " skipped (in progress)")
                return Nothing
              else do
                modifyIORef' reproveInProgress (Set.insert (leName e))
                r <- (if isNothing mFixedAxioms
                        then buildCandidateLemmaSubDagOnly translateCatching unitMap nameOverride debug (leName e, cdecl)
                        else buildCandidateLemmaReprove translateCatching unitMap nameOverride debug (leName e, cdecl))
                       `finally` modifyIORef' reproveInProgress (Set.delete (leName e))
                dbg debug ("[reprove] pos=" ++ pos ++ " name=" ++ leName e ++ " -> " ++ maybe "Nothing" (const "Just") r)
                return r
          _ -> do
            dbg debug ("[reprove] pos=" ++ pos ++ " no entry/decl found")
            return Nothing

      initSt = AlgState
        { stDebug      = debug
        , stUnits      = namedUnits ++ listedAxiomUnits ++ derivedUnits ++ bgNamedUnits
        , stHornAxioms = hornAxiomEntries
        , stLemmas     = preLemmaEntries
        , stGoals      = []
        , stCounter    = nAll + 1
        , stAxNuclei   = axNucleiList
        , stReprove    = reproveAt
        , stNameToPos  = nameToPos
        , stEqByName   = eqByTstpName
        , stGoalTemplate = goalLits'
        , stNegationConj = negationConj
        , stClosing = Nothing
        , stCandLemmas = Map.fromList
            [ (dn, lifted ++ [(dn, lit, blk)])
            | (cname, (lit, blk, lifted, _)) <- Map.toList candLemmaMap
            , let dn = Map.findWithDefault ("lemma " ++ cname) cname nameOverride ]
        , stExtraAxioms = []
        , stBaseAxioms  = axiomList ++ bgAxiomList
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

  (outcome, finalSt) <- runStateT (runExceptT (action thetaCtx allNuclei posToName goalLits' simpl pG1Chain)) initSt
  either error return outcome
  -- A refutation that never resolves the negated conjecture (the axioms
  -- alone are contradictory) has no goal proof to show.
  when (null (stGoals finalSt)) $ error "no goal proof produced: the refutation does not use the conjecture"
  -- The emitted goals must be one consistent instance of the conjecture goals.
  -- A proof of some other true statement would pass Lean, so it is guarded here.
  -- Free variables of an emitted goal are universal, so the check unifies rather
  -- than matches, with goals renamed apart from each other and the conjecture.
  let emittedGoals = [ suffixVarsLit ("_g" ++ show i) g | (i, (g, _)) <- zip [1 :: Int ..] (stGoals finalSt) ]
      conjGoals    = map (suffixVarsLit "_c") goalLits'
      unifiesWith σ g = listToMaybe [ σ' | l <- conjGoals, Just σ' <- [unifyLits l g σ] ]
  -- Every conjunct of the conjecture has a goal proof, all under one
  -- substitution, so none is left unproved and none is proved at another
  -- instance.  The pairing is searched, since a conjunct may unify with
  -- several emitted goals and only one choice extends to the rest.
  let covers σ [] = Just σ
      covers σ (c : cs) = listToMaybe
        [ r | e <- emittedGoals, Just σ' <- [unifyLits c e σ], Just r <- [covers σ' cs] ]
  σJoint <- case covers [] conjGoals of
    Just σ  -> return σ
    Nothing -> error ("goal(s) could not be proved: "
                      ++ intercalate ", " [ ppLitI c | c <- goalLits'
                                          , isNothing (covers [] [suffixVarsLit "_c" c]) ]
                      ++ " (no emitted goal proves this conjunct)")
  when (isNothing (foldM unifiesWith σJoint emittedGoals)) $
    error ("emitted goals are not a consistent instance of the conjecture: "
           ++ intercalate ", " (map (ppLitI . fst) (stGoals finalSt)))
  -- the derivation of $false, appended after the coverage check, which the
  -- conjuncts' own goals pass
  let closing = [ (falsumLit, b) | negationConj, Just b <- [stClosing finalSt] ]
  return (StructuredProof (axiomList ++ bgAxiomList ++ stExtraAxioms finalSt)
                          (stLemmas finalSt) (stGoals finalSt ++ closing) emptyInput)
  where
    action thetaCtx' allNuclei posToName goalLits simpl pG1Chain = do
      -- the nucleus loop of Algorithm 1
      processNuclei debug thetaCtx' allNuclei posToName goalLits simpl
      unproven <- openGoalsOf goalLits
      unless (null unproven) $ do
        -- The goal literals share their existential variables, so the instance one
        -- goal is proved at instantiates the rest, as Algorithm 1 emits every G_j
        -- under the same θ.
        let proveAll _ [] = return ()
            proveAll θ (g : rest) = do
              let g' = applySubst θ g
              r <- attempt (proveGoal simpl pG1Chain g')
              case r of
                Right () -> return ()
                Left msg -> liftIO $ dbg debug ("[goal] " ++ ppLitI g' ++ " — " ++ msg)
              emitted <- gets (map fst . stGoals)
              let θ' = fromMaybe θ $ listToMaybe
                         [ θ'' | e <- emitted, Just ρ <- [matchLit g' e], Just θ'' <- [extendSubst θ ρ] ]
              proveAll θ' rest
        proveAll [] unproven
      open3 <- openGoalsOf goalLits
      unless (null open3) $
        error ("goal(s) could not be proved: "
               ++ intercalate ", " (map ppLitI open3)
               ++ " (no step of the input proof establishes it under theta, and the rewrite search found no chain)")
      -- A negated conclusion is proved by deriving $false from its conjuncts,
      -- so the goal shown is that derivation, the conjuncts' proofs as premises
      -- and the closing clause as the rule.  SWW469_1 has two conjuncts,
      -- sK0 = sK1 and a proposition, and showed the first alone as the proof.
      negation <- gets stNegationConj
      gs0 <- gets stGoals
      let derivesFalse (HaveHence ls) = or [ True | Hence l _ <- ls, l == falsumLit ]
          derivesFalse _              = False
      -- a goal block that already derives $false, as the contradiction route
      -- builds, is that derivation and stays as it is
      when (negation && not (any (derivesFalse . snd) gs0)) $ case closerName goalLits posToName of
        Just ax -> do
          gs <- gets stGoals
          prems <- forM gs $ \(g, b) -> do
            nm <- ensureNamed g (return b)
            return (g, nm)
          let ls = [ (if i == (0 :: Int) then Have else And) g nm | (i, (g, nm)) <- zip [0 ..] prems ]
          modify $ \st -> st { stClosing = Just (HaveHence (ls ++ [Hence falsumLit (ByAxiom ax)])) }
        -- The closing clause may also rest on a hypothesis or a unit the
        -- proof named beside the conjuncts' goals, as PUZ129+2's
        -- grocer(Z) /\ property1(Z,healthy,pos) => $false does with the
        -- assumption grocer(s) and the derived property1(s,healthy,pos).
        -- Its body is established literal by literal under one substitution.
        Nothing -> do
          gs    <- gets stGoals
          units <- gets stUnits
          let named = [ (ueUnit u, Left nm) | u <- units, Just nm <- [ueName u] ]
                   ++ [ (g, Right b) | (g, b) <- gs ]
              establish sigma [] = [(sigma, [])]
              establish sigma (b : bs) =
                [ (sigma'', (applySubst sigma'' b, src) : rest)
                | (l, src) <- named
                , Just sigma' <- [matchLitWith b l sigma]
                , (sigma'', rest) <- establish sigma' bs ]
              closers =
                [ (nm, prems)
                | e <- piNuclei info
                , Just (Clause bs Nothing) <- [closerClause e]
                , not (null bs)
                , Just nm <- [Map.lookup (lePos e) posToName]
                , (_, prems) : _ <- [establish [] bs] ]
          case closers of
            [] -> return ()
            (ax, prems) : _ -> do
              named' <- forM prems $ \(g, src) -> case src of
                Left nm -> return (g, nm)
                Right b -> do
                  nm <- ensureNamed g (return b)
                  return (g, nm)
              let ls = [ (if i == (0 :: Int) then Have else And) g nm | (i, (g, nm)) <- zip [0 ..] named' ]
              modify $ \st -> st { stClosing = Just (HaveHence (ls ++ [Hence falsumLit (ByAxiom ax)])) }
    -- a hypothesis clausified from a FOF conjecture has that whole formula
    -- as its source, so the clause the leaf states is read then
    closerClause e = convertDeclToClause (leSrcDecl e) <|> convertDeclToClause (leDecl e)
    -- the clause that closes the refutation on the conjuncts, by its display name
    closerName goalLits posToName = listToMaybe
      [ nm | e <- piNuclei info
           , Just (Clause bs Nothing) <- [closerClause e]
           , length bs == length goalLits
           , all (\b -> any (\g -> isJust (matchLit b g) || isJust (matchLit g b)) goalLits) bs
           , Just nm <- [Map.lookup (lePos e) posToName] ]

