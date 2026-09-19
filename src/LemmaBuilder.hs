module LemmaBuilder
  ( flattenParents
  , ancestorNamesOf
  , findLemmaCandidates
  , buildCandidateLemma
  , buildCandidateLemmaSubDagOnly
  , buildCandidateLemmaReprove
  , clearLemmaCache
  , BuiltLemma
  , makeFileSourced
  ) where

import Control.Monad (when)
import Control.Applicative ((<|>))
import Data.IORef (IORef, modifyIORef', newIORef, readIORef, writeIORef)
import System.IO.Unsafe (unsafePerformIO)
import Data.List (intercalate, nub)
import Data.Maybe (isJust, listToMaybe, mapMaybe, maybeToList)
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import Data.TPTP.Pretty (Pretty (..))
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import qualified Data.Text as Text
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
  ( applySubst, applyConstSubstBlock, applyConstSubstLit, blockRefNames
  , extractSzsBlock, isEmptyBlock, isEqLit, litVars, renameRefsBlock
  , unitEquation
  )
import Debug (dbgScoped, subrunDepth)
import ProofTree (classifyRole, conjectureHypotheses, headLitOf, isDerivedUnit, isFileSrc, isOrigAxiomDecl, isPositiveUnitFormula, lookupDecl, resolveCopySource, resolveSourceName, unitNameStr)
import TptpConvert
import TweeInterface (TweeBudget (..), callTwee, findProver, runProverCapped, sanitizeId, timeoutSecsFromEnv, toTptpTerm, withTempInput)

-- Flatten a T.Parent into the TSTP unit names it references
flattenParents :: T.Parent -> [String]
flattenParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
flattenParents (T.Parent (T.Inference _ _ ps) _) = concatMap flattenParents ps
flattenParents _                                  = []

-- All TSTP names reachable as ancestors of rootName (rootName itself excluded)
ancestorNamesOf :: Map.Map String T.Unit -> String -> Set.Set String
ancestorNamesOf unitMap rootName = go startFrontier Set.empty
  where
    parentsOf nm = case Map.lookup nm unitMap of
      Just (T.Unit _ _ (Just (T.Inference _ _ ps, _))) ->
        Set.fromList (concatMap flattenParents ps)
      -- a bare reference (E copies a unit this way) is a parent too
      Just (T.Unit _ _ (Just (T.UnitSource p, _))) ->
        Set.singleton (unitNameStr p)
      _ -> Set.empty

    startFrontier = parentsOf rootName

    go frontier seen = case Set.minView frontier of
      Nothing -> seen
      Just (nm, rest)
        | Set.member nm seen -> go rest seen
        | otherwise          ->
            go (Set.union rest (parentsOf nm)) (Set.insert nm seen)

-- Lemma candidates are derived positive unit clauses cited at least twice as
-- parents in the DAG, in original order.
findLemmaCandidates :: [T.Unit] -> [(String, T.Declaration)]
findLemmaCandidates units =
  let parentCounts :: Map.Map String Int
      parentCounts = Map.fromListWith (+)
        [ (pname, 1)
        | T.Unit _ _ (Just (T.Inference _ _ parents, _)) <- units
        , pname <- concatMap flattenParents parents
        ]
      candidateSet = Set.fromList
        [ unitNameStr n
        | T.Unit n decl (Just (T.Inference {}, _)) <- units
        , isJust (headLitOf decl)  -- exactly one positive literal
        -- Only unit clauses.  A lemma is stated as a single literal, so a Horn
        -- candidate with body atoms is inlined at every use instead.
        , null (bodyLitsOf decl)
        , Map.findWithDefault 0 (unitNameStr n) parentCounts >= 2
        ]
  in [ (unitNameStr n, decl)
     | T.Unit n decl _ <- units
     , Set.member (unitNameStr n) candidateSet
     ]

-- Skolemize a head literal and its body literals together, replacing all
-- variables with fresh Skolem constants skc_0, skc_1, …
-- Returns the grounded head, grounded body, and an undo map for de-Skolemization.
skolemizeAll :: Literal -> [Literal] -> (Literal, [Literal], [(String, Term)])
skolemizeAll lit bodyLits =
  let allVs   = nub (concatMap litVars (lit : bodyLits))
      skMap   = zip allVs ["skc_" ++ show i | i <- [(0 :: Int) ..]]
      skSubst = [(v, Const sk) | (v, sk) <- skMap]
  in ( applySubst skSubst lit
     , map (applySubst skSubst) bodyLits
     , [(sk, Var v) | (v, sk) <- skMap] )

-- Replace a candidate unit's inference source with a synthetic file source so
-- that buildProofInfo treats it as an OrigAxiom leaf (halts expansion there).
makeFileSourced :: T.Unit -> T.Unit
makeFileSourced (T.Unit n decl _) =
  T.Unit n decl (Just (T.File (T.Atom (Text.pack "lemma")) Nothing, Nothing))
makeFileSourced u = u

-- A built lemma with its statement, its proof, the sub-lemmas the recursive
-- translation introduced, and the axioms that translation numbered itself.
-- The sub-lemmas are already renamed apart and de-Skolemized, and the caller
-- adds them before the lemma.  The axiom list is normally empty since a sub-run
-- cites outer axioms through its name override.  It is not when the sub-problem
-- needs a file axiom the outer proof never used, as LCL126-1/E does with q_3.
-- Those axioms go into the outer axiom list, or the lifted block would cite a
-- name that means a different axiom outside.
type BuiltLemma = (Literal, ProofBlock, [(String, Literal, ProofBlock)], [Axiom])

-- Lemma introduction as in Section 4 of the paper.  Skolemize the candidate's
-- negation, refute {A_1..A_n, not B} from the axioms, translate recursively,
-- and de-Skolemize.  translateFn is Translate.translateWith, passed in to avoid
-- a circular import.
buildCandidateLemma
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof))
  -> Bool                   -- strict mode translates the candidate's own sub-DAG first
  -> Map.Map String T.Unit
  -> Map.Map String String  -- TSTP name to display name in the outer proof
  -> Bool                   -- debug
  -> (String, T.Declaration)
  -> IO (Maybe BuiltLemma)
buildCandidateLemma translateFn strict unitMap tstp2name debug (cname, cdecl) =
  case headLitOf cdecl of
    Nothing   -> return Nothing
    Just tlit -> do
      let lit     = convertLit tlit
          bodyLits = map convertLit (bodyLitsOf cdecl)
          (lit_sk, bodyLits_sk, undoMap) = skolemizeAll lit bodyLits
      mSub <- if strict
                then buildFromSubDag translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap
                else return Nothing
      case mSub of
        Just r  -> return (Just r)
        Nothing -> buildWithProver translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap

-- Sub-DAG route only, with no prover fallback.  This is safe inside recursive
-- lemma sub-proofs because the candidate's ancestry shrinks at each level.  A
-- prover sub-proof introduces fresh units and has no such measure.
buildCandidateLemmaSubDagOnly
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String
  -> Bool
  -> (String, T.Declaration)
  -> IO (Maybe BuiltLemma)
buildCandidateLemmaSubDagOnly translateFn unitMap tstp2name debug (cname, cdecl) =
  case headLitOf cdecl of
    Nothing   -> return Nothing
    Just tlit -> do
      let lit      = convertLit tlit
          bodyLits = map convertLit (bodyLitsOf cdecl)
          (lit_sk, bodyLits_sk, undoMap) = skolemizeAll lit bodyLits
      buildFromSubDag translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap

-- Re-prove a derived unit mid-translation, first by its own sub-DAG and then
-- by the prover.
buildCandidateLemmaReprove
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String
  -> Bool
  -> (String, T.Declaration)
  -> IO (Maybe BuiltLemma)
buildCandidateLemmaReprove translateFn unitMap tstp2name debug (cname, cdecl) =
  case headLitOf cdecl of
    Nothing   -> return Nothing
    Just tlit -> do
      let lit      = convertLit tlit
          bodyLits = map convertLit (bodyLitsOf cdecl)
          (lit_sk, bodyLits_sk, undoMap) = skolemizeAll lit bodyLits
      mSub <- buildFromSubDag translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap
      case mSub of
        Just r  -> return (Just r)
        Nothing -> buildWithProver translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap

-- Synthetic unit names of a sub-problem must not collide with the candidate's
-- ancestry, or lemmaNameOverrides would rename a real axiom to "assumption".
syntheticCollision :: Map.Map String T.Unit -> String -> [Literal] -> Bool
syntheticCollision unitMap cname bodyLits_sk =
  let inProblem = Set.insert cname (ancestorNamesOf unitMap cname)
      ids = Set.union inProblem (Set.map sanitizeId inProblem)
  in any (`Set.member` ids) (syntheticNames bodyLits_sk)

-- Strict mode translates a refutation of {A_1..A_n, not B} from the axioms.
-- The candidate's ancestry is already one once its Skolemized negation is
-- resolved against it, so no prover is needed.  The proof is assembled from
-- the ancestor units, the candidate, the Skolemized body atoms as hypotheses,
-- the Skolemized negated head, and synthetic resolution steps to bottom.
buildFromSubDag
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String
  -> Bool
  -> String -> Literal -> Literal -> [Literal] -> [(String, Term)]
  -> IO (Maybe BuiltLemma)
buildFromSubDag translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap
  | syntheticCollision unitMap cname bodyLits_sk = do
      when debug $ hPutStrLn stderr
        ("buildCandidateLemma: sub-DAG skipped for " ++ cname ++ " (synthetic name collision)")
      return Nothing
  | otherwise = do
      let ancNames  = ancestorNamesOf unitMap cname
          ancUnits  = [ u | aname <- Set.toList ancNames, Just u <- [Map.lookup aname unitMap] ]
          candUnit  = maybeToList (Map.lookup cname unitMap)
          unitLines = map (show . pretty) (ancUnits ++ candUnit)
          premLines = premLinesFor bodyLits_sk
          negLine   = "cnf(negconj, negated_conjecture, " ++ cnfLitStr (negLit lit_sk) ++ ")."
          -- resolve the body atoms away one by one, then the head against negconj
          stepClause rest = intercalate " | " (cnfLitStr lit_sk : map (cnfLitStr . negLit) rest)
          stepLines =
            [ "cnf(" ++ lemmaStepName i ++ ", plain, " ++ stepClause (drop (i + 1) bodyLits_sk)
              ++ ", inference(resolution,[status(thm)],[" ++ prev ++ ", " ++ premName i ++ "]))."
            | i <- [0 .. length bodyLits_sk - 1]
            , let prev = if i == 0 then cname else lemmaStepName (i - 1) ]
          lastName  = if null bodyLits_sk then cname else lemmaStepName (length bodyLits_sk - 1)
          botLine   = "cnf(lemma_bot, plain, $false, inference(resolution,[status(thm)],["
                      ++ lastName ++ ", negconj]))."
          content   = unlines (unitLines ++ premLines ++ [negLine] ++ stepLines ++ [botLine])
          -- An ancestor may be a different clausified copy of an original
          -- axiom than the leaf the outer numbering named (E keeps several
          -- copies).  Without a display name the sub-run would number it
          -- freshly, and the lifted block would cite an outer axiom number
          -- that means a different axiom.  Copies of the same source get the
          -- outer display name.
          bySource  = Map.fromList
            [ (resolveCopySource unitMap k, dn) | (k, dn) <- Map.toList tstp2name ]
          resolvedOvr = Map.fromList
            [ (aname, dn)
            | aname <- Set.toList ancNames
            , not (Map.member aname tstp2name)
            , Just dn <- [Map.lookup (resolveCopySource unitMap aname) bySource]
            ]
          nameOvr   = Map.union (lemmaNameOverrides bodyLits_sk tstp2name) resolvedOvr
          key       = (content, Map.toList nameOvr)
      -- the same sub-DAG under the same names is asked for from every sub-run
      -- that needs the unit, and its translation is the same each time
      cache <- readIORef subDagCache
      case Map.lookup key cache of
        Just r -> do
          when debug $ hPutStrLn stderr ("buildCandidateLemma: sub-DAG for " ++ cname ++ " cached")
          return r
        Nothing -> do
          when debug $ hPutStrLn stderr ("buildCandidateLemma: sub-DAG for " ++ cname ++ ":\n" ++ content)
          r <- case eitherResult (feed (parseTSTP (Text.pack content)) mempty) of
            Left err -> do
              when debug $ hPutStrLn stderr ("buildCandidateLemma: sub-DAG parse error: " ++ err)
              return Nothing
            Right tstp -> do
              msp <- dbgScoped debug ("sub-DAG for " ++ cname) (translateFn nameOvr debug tstp)
              return (msp >>= liftSubProof nameOvr cname lit undoMap)
          modifyIORef' subDagCache (Map.insert key r)
          return r

-- Sub-DAG translations of one top-level run, keyed by the sub-problem text
-- and the outer names it uses.  Cleared when a top-level run starts, since
-- the stages translate differently.
{-# NOINLINE subDagCache #-}
subDagCache :: IORef (Map.Map (String, [(String, String)]) (Maybe BuiltLemma))
subDagCache = unsafePerformIO (newIORef Map.empty)

clearLemmaCache :: IO ()
clearLemmaCache = writeIORef subDagCache Map.empty

-- Turn the recursive translation of a candidate into an outer lemma.  The goal
-- block becomes the lemma's proof, and the sub-lemmas are renamed apart and
-- de-Skolemized with it.  Generalizing a sub-lemma over the Skolem constants
-- is sound only if the axioms alone prove it, so a candidate whose sub-lemmas
-- cite an assumption is rejected.
liftSubProof :: Map.Map String String -> String -> Literal -> [(String, Term)]
             -> StructuredProof -> Maybe BuiltLemma
liftSubProof nameOvr cname lit undoMap sp = do
  (_, goalBlk) <- listToMaybe (goals sp)
  let subLemmas = lemmas sp
      newName n = "lemma " ++ cname ++ "/" ++ n
      renaming  = Map.fromList [ (n, newName n) | (n, _, _) <- subLemmas ]
      ren nm    = Map.findWithDefault nm nm renaming
      lift blk  = applyConstSubstBlock undoMap (renameRefsBlock ren blk)
      lifted    = [ (newName n, applyConstSubstLit undoMap l, lift b) | (n, l, b) <- subLemmas ]
      blk'      = lift goalBlk
      -- Names the sub-run took from the outer proof.  Anything else in its
      -- axiom list it numbered itself, unknown to the outer proof.
      outerNames = Set.fromList (filter (not . null) (Map.elems nameOvr))
      axName a  = case a of { AUnit n _ -> n; ANucleus n _ -> n }
      ownAxioms = [ a | a <- axioms sp, axName a `Set.notMember` outerNames ]
  -- The sub-proof may cite the candidate's body atoms as assumptions.  The
  -- lifted lemma states the head alone, so a block resting on an assumption
  -- would claim the head outright.  The candidate's own block is checked too,
  -- since Translate.reproveAt' hands in any clause at a tree position,
  -- including a Horn nucleus with body atoms.
  if isEmptyBlock blk'
     || "assumption" `elem` blockRefNames blk'
     || any (\(_, _, b) -> "assumption" `elem` blockRefNames b) lifted
    then Nothing
    else Just (lit, blk', lifted, ownAxioms)

-- Re-prove the candidate with Twee (pure equations) or E, then translate the
-- prover's proof recursively (paper, Section 4).
buildWithProver
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String
  -> Bool
  -> String -> Literal -> Literal -> [Literal] -> [(String, Term)]
  -> IO (Maybe BuiltLemma)
buildWithProver translateFn unitMap tstp2name debug cname lit lit_sk bodyLits_sk undoMap
  | syntheticCollision unitMap cname bodyLits_sk = do
      when debug $ hPutStrLn stderr
        ("buildCandidateLemma: prover path skipped for " ++ cname ++ " (synthetic name collision)")
      return Nothing
  | otherwise = do
   depth <- subrunDepth
   -- a prover sub-proof introduces fresh units, so one inside a sub-run
   -- would nest without a termination measure, and only the outermost run
   -- asks the prover
   if depth > 0
    then do
      when debug $ hPutStrLn stderr
        ("buildCandidateLemma: prover path skipped for " ++ cname ++ " inside a sub-run")
      return Nothing
    else do
      let ancNames = ancestorNamesOf unitMap cname
          granted  = maybe [] (uncurry (++)) (conjectureHypotheses (Map.elems unitMap))
          dispNameOf aname =
            Map.lookup (resolveSourceName unitMap aname) tstp2name
              <|> Map.lookup aname tstp2name
          -- an ancestor counts as an original axiom either directly (an
          -- underived unit with an axiom or hypothesis role) or as a mere
          -- clausified copy of a file axiom (E marks those plain, e.g. a
          -- fof_simplification of a Horn axiom), provided its citation
          -- resolves to a display name
          -- A clause the conjecture grants, as LCL133-1's lemma_antecedent,
          -- is an axiom of the outer proof too, as the main run reads it
          effOrigAncestor aname u@(T.Unit _ adecl _) =
            (not (isDerivedUnit u) && isOrigAxiomDecl adecl)
              || (not (isDerivedUnit u) && classifyRole granted unitMap aname adecl == OrigAxiom
                  && isJust (dispNameOf aname))
              || (isFileSrc unitMap copySrc
                  && maybe False isOrigAxiomDecl (lookupDecl unitMap copySrc)
                  && isJust (dispNameOf aname))
            where copySrc = resolveCopySource unitMap aname
          effOrigAncestor _ _ = False
          ancLines = [ line
                     | aname <- Set.toList ancNames
                     , Just u@(T.Unit _ adecl _) <- [Map.lookup aname unitMap]
                     , effOrigAncestor aname u
                     , isJust (headLitOf adecl)
                     , Just line <- [toCNFAncAxiom (ancInputName aname) adecl]
                     ]
          premLines = premLinesFor bodyLits_sk
          negLine =
            "cnf(negconj, negated_conjecture, " ++ cnfLitStr (negLit lit_sk) ++ ")."
          content = unlines (ancLines ++ premLines ++ [negLine])

      -- For purely equational, no-body goals whose entire ancestry consists of
      -- unit equations, try Twee directly (that is all the information the
      -- Twee call passes on, so with a Horn ancestor the attempt would only
      -- burn the Twee time budget before falling through to E).
      let ancestryAllUnitEqs = and
            [ isPositiveUnitFormula adecl && maybe False (isEqLit . convertLit) (headLitOf adecl)
            | aname <- Set.toList ancNames
            , Just u@(T.Unit _ adecl _) <- [Map.lookup aname unitMap]
            , effOrigAncestor aname u
            ]
      mTweeBlk <-
        if null bodyLits_sk && isEqLit lit_sk && ancestryAllUnitEqs
          then do
            let ancUes = mapMaybe mkAncUe (Set.toList ancNames)
                mkAncUe aname = do
                  u@(T.Unit _ adecl _) <- Map.lookup aname unitMap
                  if not (effOrigAncestor aname u) || not (null (bodyLitsOf adecl))
                    then Nothing
                    else do
                      headTlit <- headLitOf adecl
                      let clit = convertLit headTlit
                      if not (isEqLit clit) then Nothing
                      else Just (UnitEntry (dispNameOf aname) clit Nothing Nothing)
            case lit_sk of
              Eq l r -> do
                mChain <- callTwee InternalBudget ancUes (Eq l r)
                case mChain of
                  Just (start, chain)
                    | not (null chain)
                    , all (isJust . ueName . (\(ue,_,_) -> ue)) chain ->
                        let steps = [ (RwStep nm (unitEquation (ueUnit ue)) dir, cur)
                                    | (ue, dir, cur) <- chain
                                    , Just nm <- [ueName ue] ]
                            blk   = EqChain start steps
                        in return (Just (lit, applyConstSubstBlock undoMap blk, [], []))
                  _ -> return Nothing
              _ -> return Nothing
          else return Nothing
      case mTweeBlk of
        Just r  -> return (Just r)
        Nothing -> do
          when debug $ hPutStrLn stderr
            ("buildCandidateLemma: E subproblem for " ++ cname ++ ":\n" ++ content)
          mEBin <- findProver "TAELJA_EPROVER" "eprover" "lemma re-proofs"
          -- Per-candidate E budget from TAELJA_E_TIMEOUT, 5 s soft CPU by
          -- default plus a 5 s wall-clock kill.  A lemma is only worth it if
          -- its subproof is easy, and an unprovable candidate would burn the
          -- whole limit, as HEN006-4/Twee did.  --proof-object gives the
          -- baseline format, since the --output-level=2 trace is not parseable
          eSecs <- timeoutSecsFromEnv "TAELJA_E_TIMEOUT" 5
          eResult <- case mEBin of
            Nothing   -> return Nothing
            Just eBin -> withTempInput ("lemma_" ++ sanitizeId cname) content $ \tmpFile ->
              runProverCapped (eSecs + 5) eBin
                ["--auto", "--proof-object", "--tptp3-format",
                 "--soft-cpu-limit=" ++ show eSecs, tmpFile]
          case eResult of
            Nothing -> do
              -- a missing binary was reported once by findProver
              when (debug && isJust mEBin) $ hPutStrLn stderr "buildCandidateLemma: E failed or timed out"
              return Nothing
            Just eOut -> do
              when debug $ hPutStrLn stderr
                ("buildCandidateLemma: E output length=" ++ show (length eOut)
                 ++ "\n" ++ eOut)
              case eitherResult (feed (parseTSTP (Text.pack (extractSzsBlock eOut))) mempty) of
                Left err -> do
                  when debug $ hPutStrLn stderr
                    ("buildCandidateLemma: parse error: " ++ err)
                  return Nothing
                Right tstp -> do
                  -- The sub-proof cites its inputs under the anc_ names given
                  -- above, which resolve to outer display names here.  The
                  -- outer map is not consulted since E also numbers the
                  -- sub-run's clauses c_0_N, and an outer key would rename an
                  -- unrelated clause, as happened on COL006-2/E.
                  let ancOvr = Map.fromList
                        [ (ancInputName aname, dn)
                        | aname <- Set.toList ancNames
                        -- tstp2name may be keyed by the leaf name itself or by
                        -- its resolved source (E copies axioms through bare
                        -- unit references), so both are consulted
                        , Just dn <- [ Map.lookup (resolveSourceName unitMap aname) tstp2name
                                       <|> Map.lookup aname tstp2name ] ]
                      nameOvr = Map.union ancOvr (syntheticOverrides bodyLits_sk)
                  msp <- dbgScoped debug ("E-reproved for " ++ cname) (translateFn nameOvr debug tstp)
                  return (msp >>= liftSubProof nameOvr cname lit undoMap)
  where
    toCNFAncAxiom :: String -> T.Declaration -> Maybe String
    toCNFAncAxiom name decl =
      let posLits = maybe [] (\tl -> [convertLit tl]) (headLitOf decl)
          negLits = map (negLit . convertLit) (bodyLitsOf decl)
          allLits = posLits ++ negLits
      in if null allLits then Nothing
         else Just ("cnf(" ++ name ++ ", axiom, "
                    ++ intercalate " | " (map cnfLitStr allLits) ++ ").")

cnfLitStr :: Literal -> String
cnfLitStr (Eq l r)    = toTptpTerm l ++ " = "  ++ toTptpTerm r
cnfLitStr (NEq l r)   = toTptpTerm l ++ " != " ++ toTptpTerm r
cnfLitStr (Rel n [])  = n
cnfLitStr (Rel n as)  = n ++ "(" ++ intercalate "," (map toTptpTerm as) ++ ")"
cnfLitStr (NRel n []) = "~" ++ n
cnfLitStr (NRel n as) = "~" ++ n ++ "(" ++ intercalate "," (map toTptpTerm as) ++ ")"

negLit :: Literal -> Literal
negLit (Rel n as)  = NRel n as
negLit (Eq l r)    = NEq l r
negLit (NRel n as) = Rel n as
negLit (NEq l r)   = Eq l r

-- Skolemized body atoms as TPTP hypothesis lines (prem_0, prem_1, ...).
premLinesFor :: [Literal] -> [String]
premLinesFor bodyLits_sk =
  [ "cnf(" ++ premName i ++ ", hypothesis, " ++ cnfLitStr bl ++ ")."
  | (i, bl) <- zip [(0::Int)..] bodyLits_sk ]

-- Display-name overrides for a recursive lemma translation.  Body premises are
-- cited as "assumption", the negated conjecture is suppressed, and axioms keep
-- their outer names.
lemmaNameOverrides :: [Literal] -> Map.Map String String -> Map.Map String String
lemmaNameOverrides bodyLits_sk tstp2name = Map.unions
  [ syntheticOverrides bodyLits_sk
  , tstp2name
    -- ancestor axioms reach the E subproblem under sanitized ids (quoted
    -- TPTP names lose their spaces), so the overrides answer to those too
  , Map.mapKeys sanitizeId tstp2name ]

-- Overrides for the synthetic units alone (premises cited as "assumption",
-- negated conjecture suppressed).
syntheticOverrides :: [Literal] -> Map.Map String String
syntheticOverrides bodyLits_sk = Map.union
  (Map.fromList [ (premName i, "assumption") | i <- [0 .. length bodyLits_sk - 1] ])
  (Map.singleton "negconj" "")

-- Name of an ancestor axiom inside the E sub-problem.  The prefix keeps it
-- apart from the c_0_N names E assigns to the sub-run's own clauses.
ancInputName :: String -> String
ancInputName aname = "anc_" ++ sanitizeId aname

-- Names of the synthetic units a sub-DAG translation adds.
syntheticNames :: [Literal] -> [String]
syntheticNames bodyLits_sk =
  "negconj" : "lemma_bot"
    : [ f i | i <- [0 .. length bodyLits_sk - 1], f <- [premName, lemmaStepName] ]

premName, lemmaStepName :: Int -> String
premName i      = "prem_" ++ show i
lemmaStepName i = "lemma_step_" ++ show i
