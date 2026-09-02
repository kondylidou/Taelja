module LemmaBuilder
  ( flattenParents
  , ancestorNamesOf
  , findLemmaCandidates
  , buildCandidateLemma
  , BuiltLemma
  , makeFileSourced
  ) where

import Control.Monad (when)
import Control.Applicative ((<|>))
import Data.List (intercalate, nub)
import Data.Maybe (fromJust, fromMaybe, isJust, isNothing, listToMaybe, mapMaybe, maybeToList)
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import Data.TPTP.Pretty (Pretty (..))
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import qualified Data.Text as Text
import System.Directory (doesFileExist, findExecutable)
import System.Environment (lookupEnv)
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
  ( applySubst, applyConstSubstBlock, applyConstSubstLit, blockRefNames
  , extractSzsBlock, isEmptyBlock, litVars, renameRefsBlock
  )
import ProofTree (headLitOf, isPositiveUnitFormula, resolveSourceName, unitNameStr)
import TptpConvert
import TweeInterface (TweeBudget (..), callTwee, isDerivedUnit, isEqLit, isOrigAxiomDecl, runProverCapped, sanitizeId, timeoutSecsFromEnv, toTptpTerm, withTempInput)

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
      _ -> Set.empty

    startFrontier = parentsOf rootName

    go frontier seen = case Set.minView frontier of
      Nothing -> seen
      Just (nm, rest)
        | Set.member nm seen -> go rest seen
        | otherwise          ->
            go (Set.union rest (parentsOf nm)) (Set.insert nm seen)

-- Lemma candidates: derived positive-unit clauses (equational or relational)
-- cited at least twice as parents in the DAG, in original order.
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
        -- Only unit clauses: the output format states a lemma as a single
        -- literal, so a Horn candidate (with body atoms) has no representable
        -- statement; such clauses are inlined at every use instead.
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

-- A built lemma: its statement, its proof, and the sub-lemmas the recursive
-- translation introduced (already renamed apart and de-Skolemized), which the
-- caller must add to the outer proof before the lemma itself.
type BuiltLemma = (Literal, ProofBlock, [(String, Literal, ProofBlock)])

-- Lemma introduction (paper, Section 4): Skolemize the candidate's negation,
-- obtain a refutation of {A_1..A_n, not B} from the axioms, translate it
-- recursively, and de-Skolemize.  The translateFn parameter is
-- Translate.translateWith (passed to avoid a circular import).
buildCandidateLemma
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Maybe StructuredProof))
  -> Bool                   -- strict mode: translate the candidate's own sub-DAG first
  -> Map.Map String T.Unit
  -> Map.Map String String  -- tstp2name: TSTP name -> display name in outer proof
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

-- The synthetic unit names of a sub-problem must not collide with the names
-- of the units that appear in it (the candidate's ancestry): a collision
-- would let lemmaNameOverrides rename a real axiom to "assumption".
syntheticCollision :: Map.Map String T.Unit -> String -> [Literal] -> Bool
syntheticCollision unitMap cname bodyLits_sk =
  let inProblem = Set.insert cname (ancestorNamesOf unitMap cname)
      ids = Set.union inProblem (Set.map sanitizeId inProblem)
  in any (`Set.member` ids) (syntheticNames bodyLits_sk)

-- Strict mode (paper, Section 4): the translation is applied recursively to a
-- refutation of {A_1..A_n, not B} from the axioms.  The candidate's own
-- ancestry in the input proof already is such a refutation once the
-- Skolemized negation is resolved against it, so no prover is needed: all
-- ancestor units (verbatim), the candidate, the Skolemized body atoms as
-- hypotheses, the Skolemized negated head, and synthetic resolution steps
-- deriving bottom are translated as one proof.
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
          nameOvr   = lemmaNameOverrides bodyLits_sk tstp2name
      when debug $ hPutStrLn stderr ("buildCandidateLemma: sub-DAG for " ++ cname)
      case eitherResult (feed (parseTSTP (Text.pack content)) mempty) of
        Left err -> do
          when debug $ hPutStrLn stderr ("buildCandidateLemma: sub-DAG parse error: " ++ err)
          return Nothing
        Right tstp -> do
          msp <- translateFn nameOvr debug tstp
          return (msp >>= liftSubProof cname lit undoMap)

-- Turn the recursive translation of a candidate into an outer-proof lemma:
-- the goal block becomes the lemma's proof; the sub-lemmas are renamed apart
-- (the outer emitter renumbers all lemmas at the end) and de-Skolemized
-- together with the block.  Generalizing a sub-lemma over the Skolem
-- constants is sound only if it was proved from the axioms alone, so a
-- candidate whose sub-lemmas cite an assumption (a Skolemized body premise)
-- is rejected.
liftSubProof :: String -> Literal -> [(String, Term)] -> StructuredProof -> Maybe BuiltLemma
liftSubProof cname lit undoMap sp = do
  (_, goalBlk) <- listToMaybe (goals sp)
  let subLemmas = lemmas sp
      newName n = "lemma " ++ cname ++ "/" ++ n
      renaming  = Map.fromList [ (n, newName n) | (n, _, _) <- subLemmas ]
      ren nm    = Map.findWithDefault nm nm renaming
      lift blk  = applyConstSubstBlock undoMap (renameRefsBlock ren blk)
      lifted    = [ (newName n, applyConstSubstLit undoMap l, lift b) | (n, l, b) <- subLemmas ]
      blk'      = lift goalBlk
  if isEmptyBlock blk' || any (\(_, _, b) -> "assumption" `elem` blockRefNames b) lifted
    then Nothing
    else Just (lit, blk', lifted)

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
      let ancNames = ancestorNamesOf unitMap cname
          ancLines = [ line
                     | aname <- Set.toList ancNames
                     , Just u@(T.Unit _ adecl _) <- [Map.lookup aname unitMap]
                     , not (isDerivedUnit u)
                     , isOrigAxiomDecl adecl
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
            , not (isDerivedUnit u)
            , isOrigAxiomDecl adecl
            ]
      mTweeBlk <-
        if null bodyLits_sk && isEqLit lit_sk && ancestryAllUnitEqs
          then do
            let ancUes = mapMaybe mkAncUe (Set.toList ancNames)
                mkAncUe aname = do
                  u@(T.Unit _ adecl _) <- Map.lookup aname unitMap
                  if isDerivedUnit u || not (isOrigAxiomDecl adecl) || not (null (bodyLitsOf adecl))
                    then Nothing
                    else do
                      headTlit <- headLitOf adecl
                      let clit = convertLit headTlit
                      if not (isEqLit clit) then Nothing
                      else Just (UnitEntry (Map.lookup aname tstp2name) clit Nothing Nothing)
            case lit_sk of
              Eq l r -> do
                mChain <- callTwee InternalBudget ancUes (Eq l r)
                case mChain of
                  Just (start, chain)
                    | not (null chain)
                    , all (isJust . ueName . (\(ue,_,_) -> ue)) chain ->
                        let steps = [ (RwStep (fromJust (ueName ue)) (a, b) dir, cur)
                                    | (ue, dir, cur) <- chain
                                    , Eq a b <- [ueUnit ue] ]
                            blk   = EqChain start steps
                        in return (Just (lit, applyConstSubstBlock undoMap blk, []))
                  _ -> return Nothing
              _ -> return Nothing
          else return Nothing
      case mTweeBlk of
        Just r  -> return (Just r)
        Nothing -> do
          when debug $ hPutStrLn stderr
            ("buildCandidateLemma: E subproblem for " ++ cname ++ ":\n" ++ content)
          eBin  <- fromMaybe "eprover" <$> lookupEnv "TAELJA_EPROVER"
          -- Per-candidate E budget (TAELJA_E_TIMEOUT, default 5 s soft CPU,
          -- +5 s wall-clock kill): a lemma is only worth introducing if its
          -- subproof is easy; an unprovable candidate would otherwise burn
          -- the whole limit (e.g. 30 s of ResourceOut on HEN006-4/Twee).
          -- --proof-object: the same proof format as the test baselines; the
          -- full saturation trace of --output-level=2 is not parseable here
          eSecs <- timeoutSecsFromEnv "TAELJA_E_TIMEOUT" 5
          eResult <- withTempInput ("lemma_" ++ sanitizeId cname) content $ \tmpFile ->
            runProverCapped (eSecs + 5) eBin
              ["--auto", "--proof-object", "--tptp3-format",
               "--soft-cpu-limit=" ++ show eSecs, tmpFile]
          case eResult of
            Nothing -> do
              -- distinguish a missing binary (silently drops every candidate)
              -- from an ordinary timeout; findExecutable only searches PATH,
              -- so also accept a path-qualified binary that exists
              mExe   <- findExecutable eBin
              exists <- doesFileExist eBin
              if isNothing mExe && not exists
                then hPutStrLn stderr
                  ("[warn] buildCandidateLemma: E prover not found (" ++ eBin
                   ++ "); lemma candidate inlined")
                else when debug $ hPutStrLn stderr "buildCandidateLemma: E failed or timed out"
              return Nothing
            Just eOut -> do
              when debug $ hPutStrLn stderr
                ("buildCandidateLemma: E output length=" ++ show (length eOut))
              case eitherResult (feed (parseTSTP (Text.pack (extractSzsBlock eOut))) mempty) of
                Left err -> do
                  when debug $ hPutStrLn stderr
                    ("buildCandidateLemma: parse error: " ++ err)
                  return Nothing
                Right tstp -> do
                  -- The sub-proof cites its inputs through E's file sources,
                  -- i.e. under the anc_ names given above; those resolve to
                  -- the outer display names here.  The outer map itself must
                  -- not be consulted: E numbers the sub-run's own clauses
                  -- c_0_N as well, and a raw outer key c_0_N would rename an
                  -- unrelated sub-run clause (COL006-2/E cited the k axiom
                  -- for the s step and vice versa).
                  let ancOvr = Map.fromList
                        [ (ancInputName aname, dn)
                        | aname <- Set.toList ancNames
                        -- tstp2name may be keyed by the leaf name itself or by
                        -- its resolved source (E copies axioms through bare
                        -- unit references), so both are consulted
                        , Just dn <- [ Map.lookup (resolveSourceName unitMap aname) tstp2name
                                       <|> Map.lookup aname tstp2name ] ]
                      nameOvr = Map.union ancOvr (syntheticOverrides bodyLits_sk)
                  msp <- translateFn nameOvr debug tstp
                  return (msp >>= liftSubProof cname lit undoMap)
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

-- Display-name overrides for a recursive lemma translation: body premises are
-- cited as "assumption", the negated conjecture is suppressed, axioms keep
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
