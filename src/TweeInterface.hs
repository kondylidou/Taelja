module TweeInterface
  ( tweeBin
  , toTptpTerm
  , toCnfAxiom
  , toCnfNegGoal
  , HornAxiomEntry (..)
  , toIfeqCnfHorn
  , ifeqSelectorAxiom
  , sanitizeId
  , parseTweeTerm
  , parseTweeArgList
  , parseTweeChain
  , callTweeRelLemma
  , callTwee
  , TweeBudget (..)
  , relevantUnits
  , runProverCapped
  , withTempInput
  , timeoutSecsFromEnv
  ) where

import Control.Applicative ((<|>))
import Data.Char (isAsciiLower, isAsciiUpper, isDigit, toUpper)
import Data.List (intercalate, isInfixOf, isPrefixOf, nub, sortBy)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Map.Strict as Map
import Control.Exception (SomeException, bracket, try)
import Data.IORef (IORef, newIORef, readIORef, modifyIORef')
import Control.Monad (when)
import System.IO.Unsafe (unsafePerformIO)
import System.Directory (getTemporaryDirectory, removeFile)
import System.Environment (lookupEnv)
import System.Exit (ExitCode)
import System.IO (hClose, hPutStr, hPutStrLn, openTempFile, stderr)
import System.Process (readProcessWithExitCode)
import System.Timeout (timeout)
import Text.Read (readMaybe)

import Types
import Helpers (isEqLit, litVars, rewriteTermAll)

tweeBin :: FilePath
tweeBin = "bin/twee"

-- Run a prover with a hard wall-clock cap.  Twee's --max-time and E's
-- --soft-cpu-limit are not reliable stopping points (Twee has been observed
-- running for many minutes past --max-time), so the child is terminated on
-- timeout (readProcessWithExitCode's cleanup) and Nothing is returned.
runProverCapped :: Int -> FilePath -> [String] -> IO (Maybe String)
runProverCapped secs bin args = do
  r <- timeout (secs * 1000000)
         (try (readProcessWithExitCode bin args "")
            :: IO (Either SomeException (ExitCode, String, String)))
  return $ case r of
    Just (Right (_, out, _)) -> Just out
    _                        -> Nothing

-- Seconds from an environment variable, with a default for unset/unparseable.
-- Clamped to at least 1: zero or negative values would make System.Timeout
-- fail immediately or, worse, disable the wall-clock kill entirely.
timeoutSecsFromEnv :: String -> Int -> IO Int
timeoutSecsFromEnv var def = max 1 . fromMaybe def . (>>= readMaybe) <$> lookupEnv var

-- Twee call on a problem text, with the configured --max-time plus a
-- wall-clock margin. The input goes to a fresh temp file so concurrent
-- Taelja processes (e.g. a parallel test run) never overwrite each other's
-- problems. Goal-level calls (the chain for a goal) get the full budget;
-- speculative internal calls (electron recovery, unnamed units, lemma
-- candidates) get a small one, capped at the goal budget, so a failing call
-- can't eat the whole translation's time.
data TweeBudget = GoalBudget | InternalBudget deriving (Eq, Show)

runTwee :: TweeBudget -> String -> String -> IO String
runTwee budget tag input = do
  goalSecs <- timeoutSecsFromEnv "TAELJA_TWEE_TIMEOUT" 15
  secs <- case budget of
    GoalBudget     -> return goalSecs
    InternalBudget -> min goalSecs <$> timeoutSecsFromEnv "TAELJA_TWEE_INTERNAL_TIMEOUT" 5
  cache <- readIORef tweeCache
  case Map.lookup (input, secs) cache of
    Just out -> return out
    Nothing  -> do
      out <- withTempInput tag input $ \tmpFile -> do
        let maxTime = show secs
        fromMaybe "" <$> runProverCapped (secs + 5) tweeBin
          ["--no-colour", "--formal-proof", "--no-lemmas", "--multi", "--max-time", maxTime, tmpFile]
      modifyIORef' tweeCache (Map.insert (input, secs) out)
      -- TAELJA_TWEE_DEBUG=1 dumps every distinct call (input and output)
      dumpEnv <- lookupEnv "TAELJA_TWEE_DEBUG"
      when (dumpEnv == Just "1") $
        hPutStrLn stderr ("[twee " ++ tag ++ "] input:\n" ++ input ++ "[twee " ++ tag ++ "] output:\n" ++ out)
      return out

-- Process-wide result cache.  The translation retries the same sub-problems
-- many times (a large proof can produce thousands of calls with only ~10%
-- distinct inputs), and Twee is deterministic on a given input and time
-- budget, so repeat calls are served from memory.
{-# NOINLINE tweeCache #-}
tweeCache :: IORef (Map.Map (String, Int) String)
tweeCache = unsafePerformIO (newIORef Map.empty)

-- Write a prover input to a fresh temp file, run the action, remove the file
-- (also when the action throws, e.g. the wall-clock timeout).
withTempInput :: String -> String -> (FilePath -> IO a) -> IO a
withTempInput tag input act = do
  tmpDir <- getTemporaryDirectory
  bracket
    (do (path, h) <- openTempFile tmpDir ("taelja_" ++ tag ++ ".p")
        hPutStr h input
        hClose h
        return path)
    removeFile
    act

-- A symbol the prover would read back as something other than what we wrote.
-- An unquoted name starting uppercase comes back as a VARIABLE, and a
-- negative integer does not parse at all, so a call containing one would
-- either fail obscurely or return a wrong chain.  Such calls are refused.
tptpSafeName :: String -> Bool
tptpSafeName []         = False
tptpSafeName nm@(c : cs)
  -- an integer literal is a term in its own right and needs no quoting
  | all isDigit nm                        = True
  | c == '-', not (null cs), all isDigit cs = True
  -- anything else must be an unquoted atom: lowercase initial, so the prover
  -- does not read it back as a variable, and no character that would end the
  -- token and make the generated file unparseable
  | otherwise = isAsciiLower c
                && all (\ch -> isAsciiLower ch || isAsciiUpper ch || isDigit ch || ch == '_') cs

tptpSafeTerm :: Term -> Bool
tptpSafeTerm (Var _)    = True
tptpSafeTerm (Const f)  = tptpSafeName f
tptpSafeTerm (App f ts) = tptpSafeName f && all tptpSafeTerm ts

tptpSafeLit :: Literal -> Bool
tptpSafeLit (Eq a b)    = tptpSafeTerm a && tptpSafeTerm b
tptpSafeLit (NEq a b)   = tptpSafeTerm a && tptpSafeTerm b
tptpSafeLit (Rel n as)  = tptpSafeName n && all tptpSafeTerm as
tptpSafeLit (NRel n as) = tptpSafeName n && all tptpSafeTerm as

notVarTerm :: Term -> Bool
notVarTerm (Var _) = False
notVarTerm _       = True

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

-- The ifeq selector axiom: ifeq(X,X,Y,Z) = Y.
ifeqSelectorAxiom :: String
ifeqSelectorAxiom = "cnf(ifeq_axiom, axiom, ifeq(X,X,Y,Z) = Y)."

-- A relational literal as a term (for the ifeq/pair encoding); the Horn
-- axioms passed here are filtered to relational ones by the caller.
litRelTerm :: Literal -> Term
litRelTerm (Rel n []) = Const n
litRelTerm (Rel n as) = App n as
litRelTerm l          = error ("litRelTerm: not a relational atom: " ++ show l)

-- Right-nested pair encoding of a non-empty list of terms.
nestRightPair :: [Term] -> Term
nestRightPair []     = error "nestRightPair: empty list"
nestRightPair [t]    = t
nestRightPair (t:ts) = App "pair" [t, nestRightPair ts]

-- Encode a Horn clause with relational head as a CNF ifeq+pair axiom string.
-- Unit clause (no body): cnf(name, axiom, head = true).
-- Horn clause (n bodies): cnf(name, axiom, ifeq(pair(b1,..,bn), pair(true,..,true), head, true) = true).
toIfeqCnfHorn :: String -> Literal -> [Literal] -> String
toIfeqCnfHorn name headLit [] =
  "cnf(" ++ sanitizeId name ++ ", axiom, " ++ toTptpTerm (litRelTerm headLit) ++ " = true)."
toIfeqCnfHorn name headLit bodies =
  let bodyTs  = map litRelTerm bodies
      bodyEnc = nestRightPair bodyTs
      trueEnc = nestRightPair (replicate (length bodies) (Const "true"))
      headT   = litRelTerm headLit
      ifeqT   = App "ifeq" [bodyEnc, trueEnc, headT, Const "true"]
  in "cnf(" ++ sanitizeId name ++ ", axiom, " ++ toTptpTerm ifeqT ++ " = true)."

-- Call Twee to prove a Skolemized relational goal from unit ancestors plus
-- Horn axioms (given as HornAxiomEntry descriptors, encoded as ifeq+pair CNF).
-- Returns the rewrite chain from goalTerm to "true", or Nothing if unprovable.
callTweeRelLemma :: TweeBudget -> [UnitEntry] -> [HornAxiomEntry] -> Literal
                 -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTweeRelLemma budget units hornAxioms goalLit
  | not (tptpSafeLit goalLit) = return Nothing
  | otherwise = do
  let goalTerm  = litRelTerm goalLit
      relUnits  = relevantUnits goalLit (filter (tptpSafeLit . ueUnit) units)
      indexed   = zip [(0::Int)..] relUnits
      -- The index keeps ids apart: sanitizing alone maps "axiom 3" and
      -- "axiom_3" to one id, and the later unit would silently win the
      -- lookup, so a replayed step would cite the wrong axiom.
      mkId i ue = maybe "anon" sanitizeId (ueName ue) ++ "_" ++ show i
      toAxiom (i, ue) = case ueUnit ue of
        Eq a b   -> Just (toCnfAxiom (mkId i ue) a b)
        Rel n as -> Just (toCnfAxiom (mkId i ue) (relTerm n as) (Const "true"))
        _        -> Nothing
      unitAxioms = mapMaybe toAxiom indexed
      needIfeq   = not (all (null . haBodies) hornAxioms)
      ifeqAxioms = [ifeqSelectorAxiom | needIfeq]
      hornCnfs   = [ toIfeqCnfHorn (haCnfId ha) (haHead ha) (haBodies ha)
                   | ha <- hornAxioms ]
      negGoal    = toCnfNegGoal "goal" goalTerm (Const "true")
      unitIdToUe = Map.fromList [(mkId i ue, ue) | (i, ue) <- indexed]
      hornIdToUe = Map.fromList
        [ (sanitizeId (haCnfId ha), UnitEntry (haDispName ha) (haHead ha) Nothing Nothing)
        | ha <- hornAxioms ]
      -- Sentinel for ifeq_axiom so parseTweeChain's directChain doesn't abort
      -- when it encounters this step.  Filtered out downstream via isPrem check.
      ifeqSentinelUe = UnitEntry (Just "ifeq_axiom") (Eq (Var "X") (Var "Y")) Nothing Nothing
      idToUe     = Map.unions [unitIdToUe, hornIdToUe, Map.singleton "ifeq_axiom" ifeqSentinelUe]
      input      = unlines (unitAxioms ++ ifeqAxioms ++ hornCnfs ++ [negGoal])
  out <- runTwee budget "rel_lemma" input
  return (parseTweeChain idToUe out goalTerm (Const "true"))
  where
    relTerm n [] = Const n
    relTerm n as = App n as

-- An unquoted TPTP atom: lowercase-letter head, then [a-zA-Z0-9_].  Anything
-- else (spaces, ':', '-', quotes, ...) would make the generated prover input
-- file unparseable, silently failing every call that includes the unit.
sanitizeId :: String -> String
sanitizeId nm =
  let body = map (\c -> if isAsciiLower c || isAsciiUpper c || isDigit c || c == '_' then c else '_') nm
  in case body of
       (c : _) | isAsciiLower c -> body
       _                        -> 'x' : body

-- Transitive symbol-relevance filter: keep only units whose symbols are
-- reachable from the goal's symbols via the axiom set.  Prevents passing
-- unrelated equations to Twee, which inflates its critical-pair search.
relevantUnits :: Literal -> [UnitEntry] -> [UnitEntry]
relevantUnits goal units =
    filter keep units
  where
    -- An equation with a bare variable on one side rewrites every term, so it
    -- bears on any goal even when it shares no symbol with one.  Judging it by
    -- shared symbols alone drops it: SWV818-1 proves v_s = v_t from X = v_ta,
    -- whose only symbol is v_ta.
    keep u = universal (ueUnit u)
             || any (`elem` finalSyms) (litSyms (ueUnit u))
    universal (Eq (Var _) _) = True
    universal (Eq _ (Var _)) = True
    universal _              = False
    litSyms (Eq l r)    = nub (termSyms l ++ termSyms r)
    litSyms (Rel n as)  = n : concatMap termSyms as
    litSyms _           = []
    termSyms (Const c)  = [c]
    termSyms (Var _)    = []
    termSyms (App f ts) = f : concatMap termSyms ts
    allUnitSyms = map (litSyms . ueUnit) units
    expand syms =
      let newSyms = nub (syms ++ concat (filter (any (`elem` syms)) allUnitSyms))
      in if newSyms == syms then syms else expand newSyms
    finalSyms = expand (litSyms goal)

-- Parse a TPTP-style term from a string (Twee human-readable proof format).
-- Variables start uppercase; constants/functions start lowercase or '_'.
parseTweeTerm :: String -> Maybe (Term, String)
parseTweeTerm [] = Nothing
parseTweeTerm s  =
  let s' = dropWhile (== ' ') s
  in case s' of
       [] -> Nothing
       (c:_)
         | isAsciiUpper c ->
             let (nm, rest) = span isTweeIdChar s'
             in if null nm then Nothing else Just (Var nm, rest)
         | isAsciiLower c || c == '_' ->
             let (nm, rest) = span isTweeIdChar s'
             in case rest of
                  '(':more ->
                    case parseTweeArgList more of
                      Just (args, rest') -> Just (App nm args, rest')
                      Nothing            -> Nothing
                  _ -> Just (Const nm, rest)
         | otherwise -> Nothing
  where
    isTweeIdChar x = isAsciiLower x || isAsciiUpper x || isDigit x || x == '_'

parseTweeArgList :: String -> Maybe ([Term], String)
parseTweeArgList s = go [] (dropWhile (== ' ') s)
  where
    go acc str = case parseTweeTerm str of
      Nothing -> Nothing
      Just (t, rest) ->
        case dropWhile (== ' ') rest of
          ',':more -> go (acc ++ [t]) (dropWhile (== ' ') more)
          ')':more -> Just (acc ++ [t], more)
          _        -> Nothing

-- Parse Twee's --formal-proof output and build the rewrite chain. Two
-- strategies, tried in order:
--  1. Direct: use Twee's own intermediate terms verbatim. Works when Twee's
--     output terms match exactly (ground proofs).
--  2. Guided replay: keep Twee's axiom IDs and directions but re-derive each
--     intermediate term via rewriteTermAll on the stored equations. Needed
--     when Twee renames variables (e.g. X0 -> X in non-ground proofs); only
--     tries the direction Twee specified, so it stays robust to position
--     ambiguity in short chains without backtracking over direction too.
parseTweeChain
  :: Map.Map String UnitEntry
  -> String        -- Twee's stdout
  -> Term -> Term  -- expected start and end of chain
  -> Maybe (Term, [(UnitEntry, Dir, Term)])
parseTweeChain idToUe output l r =
  case extractProof of
    Nothing -> Nothing
    Just (startStr, rawSteps) ->
      directChain startStr rawSteps <|> guidedChain rawSteps
  where
    -- Strategy 1: parse intermediate terms verbatim from Twee's output.
    directChain startStr rawSteps =
      let mStart = fst <$> parseTweeTerm startStr
          mChain = sequence
            [ case (Map.lookup nm idToUe, fst <$> parseTweeTerm termStr) of
                (Just ue, Just t) -> Just (ue, dir, t)
                _                 -> Nothing
            | (nm, dir, termStr) <- rawSteps ]
      in case (mStart, mChain) of
           (Just start, Just chain)
             | start == l && (null chain || lastTerm chain == r) -> Just (l, chain)
             | start == r && (null chain || lastTerm chain == l) -> Just (r, chain)
           _ -> Nothing

    -- Strategy 2: guided replay using stored equations (handles variable renaming).
    guidedChain rawSteps =
      let steps = [(nm, dir) | (nm, dir, _) <- rawSteps]
      in replayGuided steps l r <|> replayGuided steps r l
      where
        replayGuided steps start end = (start,) <$> go start steps
          where
            go cur [] = if cur == end then Just [] else Nothing
            go cur ((tid, dir):rest) =
              case Map.lookup tid idToUe of
                Nothing -> go cur rest
                Just ue -> case ueUnit ue of
                  -- The side used as the left-hand side must not be a bare
                  -- variable.  The ifeq selector sentinel is X = Y, which
                  -- would match every term and rewrite it to an unbound
                  -- variable, inventing a step the proof never made.
                  Eq a b | notVarTerm (if dir == LR then a else b) ->
                    listToMaybe
                      [ (ue, dir, t) : chain
                      | t <- rewriteTermAll cur (a, b) dir
                      , Just chain <- [go t rest] ]
                  _ -> go cur rest

    lastTerm xs = let (_, _, t) = last xs in t

    isTermLine l' =
      let s = dropWhile (== ' ') l'
      in not (null s) && (head s `elem` (['a'..'z'] ++ ['A'..'Z'] ++ "_"))

    extractStep l' = case dropWhile (/= '{') l' of
      s | "by axiom" `isInfixOf` s ->
            let nm  = case dropWhile (/= '(') s of
                        []      -> ""
                        (_:r') -> takeWhile (/= ')') r'
                dir = if "R->L" `isInfixOf` s then RL else LR
            in if null nm then Nothing else Just (nm, dir)
        | otherwise -> Nothing

    collectSteps [] = []
    collectSteps (l':ls) = case extractStep l' of
      Just (nm, dir) ->
        case dropWhile (not . isTermLine) ls of
          []          -> []
          (tl:rest) -> (nm, dir, dropWhile (== ' ') tl) : collectSteps rest
      Nothing -> collectSteps ls

    extractProof =
      let ls         = lines output
          afterProof = drop 1 (dropWhile (not . isPrefixOf "Proof:" . dropWhile (== ' ')) ls)
      in case dropWhile (not . isTermLine) afterProof of
           [] -> Nothing
           (startLine:rest) ->
             Just (dropWhile (== ' ') startLine, collectSteps rest)

callTwee :: TweeBudget -> [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTwee budget units goal@(Eq l r)
  | not (tptpSafeLit goal) = return Nothing
  | otherwise = do
  let relUnits   = relevantUnits goal (filter (tptpSafeLit . ueUnit) units)
      rawEqUnits = [(i, ue) | (i, ue) <- zip [(0::Int)..] relUnits, isEqLit (ueUnit ue)]
      -- Put general (variable-containing) equations before ground ones so Twee's
      -- proof strategy is consistent regardless of the prover's axiom ordering.
      eqUnits = sortBy (\(_, u1) (_, u2) ->
                  compare (null (litVars (ueUnit u1))) (null (litVars (ueUnit u2))))
                rawEqUnits
      -- The index keeps ids apart: sanitizing alone maps "axiom 3" and
      -- "axiom_3" to one id, and the later unit would silently win the
      -- lookup, so a replayed step would cite the wrong axiom.
      mkId i ue = maybe "anon" sanitizeId (ueName ue) ++ "_" ++ show i
      idToUe  = Map.fromList [(mkId i ue, ue) | (i, ue) <- eqUnits]
      axioms  = [ toCnfAxiom (mkId i ue) a b
                | (i, ue) <- eqUnits, Eq a b <- [ueUnit ue] ]
      negGoal = toCnfNegGoal "goal" l r
      input   = unlines (axioms ++ [negGoal])
  out <- runTwee budget "eq" input
  return (parseTweeChain idToUe out l r)
callTwee budget units goal@(Rel name args)
  | not (tptpSafeLit goal) = return Nothing
  | otherwise = do
  let goalTerm  = if null args then Const name else App name args
      indexed   = zip [(0::Int)..] (relevantUnits goal (filter (tptpSafeLit . ueUnit) units))
      -- The index keeps ids apart: sanitizing alone maps "axiom 3" and
      -- "axiom_3" to one id, and the later unit would silently win the
      -- lookup, so a replayed step would cite the wrong axiom.
      mkId i ue = maybe "anon" sanitizeId (ueName ue) ++ "_" ++ show i
      toAxiom (i, ue) = case ueUnit ue of
        Eq a b   -> Just (toCnfAxiom (mkId i ue) a b)
        Rel n as -> Just (toCnfAxiom (mkId i ue) (if null as then Const n else App n as) (Const "true"))
        _        -> Nothing
      axioms  = mapMaybe toAxiom indexed
      negGoal = toCnfNegGoal "goal" goalTerm (Const "true")
      input   = unlines (axioms ++ [negGoal])
      idToUe  = Map.fromList [(mkId i ue, ue) | (i, ue) <- indexed, isEqLit (ueUnit ue) || isRelLit (ueUnit ue)]
  out <- runTwee budget "horn" input
  return (parseTweeChain idToUe out goalTerm (Const "true"))
  where
    isRelLit (Rel _ _) = True
    isRelLit _         = False
callTwee _ _ _ = return Nothing
