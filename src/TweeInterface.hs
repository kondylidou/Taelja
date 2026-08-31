module TweeInterface
  ( tweeBin
  , toTptpTerm
  , toCnfAxiom
  , toCnfNegGoal
  , toFOFHornAxiom
  , HornAxiomEntry (..)
  , toIfeqCnfHorn
  , ifeqSelectorAxiom
  , sanitizeId
  , isEqLit
  , isDerivedUnit
  , isOrigAxiomDecl
  , dirFlag
  , findEqByName
  , applyRwLine
  , parseTweeTerm
  , parseTweeArgList
  , parseTweeChain
  , callTweeRelLemma
  , callTwee
  , relevantUnits
  , runProverCapped
  , withTempInput
  , timeoutSecsFromEnv
  ) where

import Control.Applicative ((<|>))
import Data.Char (isAsciiLower, isAsciiUpper, isDigit, toUpper)
import Data.List (intercalate, isInfixOf, isPrefixOf, nub, sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Map.Strict as Map
import qualified Data.TPTP as T
import Control.Exception (SomeException, bracket, try)
import Data.IORef (IORef, newIORef, readIORef, modifyIORef')
import System.IO.Unsafe (unsafePerformIO)
import System.Directory (getTemporaryDirectory, removeFile)
import System.Environment (lookupEnv)
import System.Exit (ExitCode)
import System.IO (hClose, hPutStr, openTempFile)
import System.Process (readProcessWithExitCode)
import System.Timeout (timeout)
import Text.Read (readMaybe)

import Types
import Helpers (appendLine, litVars, rewriteTermAll)
import TptpConvert

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
-- wall-clock margin.  The input goes to a fresh temporary file so that
-- concurrent Taelja processes (e.g. a test suite running in parallel) never
-- overwrite each other's problems.
runTwee :: String -> String -> IO String
runTwee tag input = do
  secs <- timeoutSecsFromEnv "TAELJA_TWEE_TIMEOUT" 15
  cache <- readIORef tweeCache
  case Map.lookup (input, secs) cache of
    Just out -> return out
    Nothing  -> do
      out <- withTempInput tag input $ \tmpFile -> do
        let maxTime = show secs
        fromMaybe "" <$> runProverCapped (secs + 5) tweeBin
          ["--no-colour", "--formal-proof", "--no-lemmas", "--multi", "--max-time", maxTime, tmpFile]
      modifyIORef' tweeCache (Map.insert (input, secs) out)
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

-- Serialise a Horn clause (or unit clause) ancestor as a TPTP FOF axiom.
-- All literals are encoded in the "rel(args) = true" style for consistency
-- with the relational goal encoding used by callTweeRelLemma.
toFOFHornAxiom :: String -> T.Declaration -> String
toFOFHornAxiom name decl = case headAndBodyLits decl of
  Nothing           -> ""
  Just (heads, bodies) ->
    let allVs   = nub (concatMap litVars heads ++ concatMap litVars bodies)
        qStr    = if null allVs then ""
                  else "! [" ++ intercalate "," allVs ++ "] : "
        toLitStr l = case l of
          Eq a b   -> toTptpTerm a ++ " = " ++ toTptpTerm b
          Rel n [] -> n ++ " = true"
          Rel n as -> n ++ "(" ++ intercalate "," (map toTptpTerm as) ++ ") = true"
          _        -> "true = true"
        bodyStr = intercalate " & " (map toLitStr bodies)
        headStr = intercalate " & " (map toLitStr heads)
        fofBody = if null bodies then headStr
                  else "(" ++ bodyStr ++ " => " ++ headStr ++ ")"
    in "fof(" ++ sanitizeId name ++ ", axiom, " ++ qStr ++ fofBody ++ ")."
  where
    headAndBodyLits (T.Formula _ (T.CNF (T.Clause lits))) =
      let ls = toList lits
      in Just ( [convertLit l | (T.Positive, l) <- ls]
               , [convertLit l | (T.Negative, l) <- ls] )
    headAndBodyLits (T.Formula _ (T.FOF f)) =
      let heads  = map convertLit (headLitsOfFOF f)
          bodies = map convertLit (bodyLitsOfFOF f)
      in if null heads then Nothing else Just (heads, bodies)
    headAndBodyLits _ = Nothing

-- The ifeq selector axiom: ifeq(X,X,Y,Z) = Y.
ifeqSelectorAxiom :: String
ifeqSelectorAxiom = "cnf(ifeq_axiom, axiom, ifeq(X,X,Y,Z) = Y)."

-- Convert a relational literal to a term (for ifeq/pair encoding).
litRelTerm :: Literal -> Term
litRelTerm (Rel n []) = Const n
litRelTerm (Rel n as) = App n as
litRelTerm _          = Const "true"

-- Right-nested pair encoding of a non-empty list of terms.
nestRightPair :: [Term] -> Term
nestRightPair []     = Const "true"
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
callTweeRelLemma :: [UnitEntry] -> [HornAxiomEntry] -> Literal
                 -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTweeRelLemma units hornAxioms goalLit = do
  let goalTerm  = litRelTerm goalLit
      relUnits  = relevantUnits goalLit units
      indexed   = zip [(0::Int)..] relUnits
      mkId i ue = maybe ("anon_" ++ show i) sanitizeId (ueName ue)
      toAxiom (i, ue) = case ueUnit ue of
        Eq a b   -> Just (toCnfAxiom (mkId i ue) a b)
        Rel n as -> Just (toCnfAxiom (mkId i ue) (relTerm n as) (Const "true"))
        _        -> Nothing
      unitAxioms = mapMaybe toAxiom indexed
      needIfeq   = any (not . null . haBodies) hornAxioms
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
  out <- runTwee "rel_lemma" input
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
    filter (any (`elem` finalSyms) . litSyms . ueUnit) units
  where
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

isEqLit :: Literal -> Bool
isEqLit (Eq _ _) = True
isEqLit _        = False

isDerivedUnit :: T.Unit -> Bool
isDerivedUnit (T.Unit _ _ (Just (T.Inference {}, _))) = True
isDerivedUnit _                                           = False

-- True only for TPTP roles that indicate an original problem axiom.
isOrigAxiomDecl :: T.Declaration -> Bool
isOrigAxiomDecl (T.Formula (T.Standard T.Axiom)      _) = True
isOrigAxiomDecl (T.Formula (T.Standard T.Hypothesis) _) = True
isOrigAxiomDecl _                                        = False

dirFlag :: Dir -> Maybe Dir
dirFlag LR = Nothing
dirFlag RL = Just RL

findEqByName :: String -> [UnitEntry] -> Maybe (Term, Term)
findEqByName nm units = listToMaybe
  [ (l, r) | ue <- units, ueName ue == Just nm, Eq l r <- [ueUnit ue] ]

applyRwLine :: ProofBlock -> (RwStep, Literal) -> ProofBlock
applyRwLine b (rw, c) = appendLine b (Hence c (ByRw (rwName rw) (dirFlag (rwDir rw))))

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

-- Parse Twee's --formal-proof output and build the rewrite chain.
--
-- Two strategies, tried in order:
--  1. Direct: parse intermediate terms from Twee's output and use them verbatim.
--     Works for ground proofs where Twee's output terms match exactly.
--  2. Guided replay: use the axiom IDs and directions from the proof but
--     re-derive intermediate terms via rewriteTermAll on the stored equations.
--     Needed when Twee renames variables (e.g. X0 → X in non-ground proofs).
--     Only tries the one direction Twee specified, avoiding direction backtracking
--     while remaining robust to position ambiguity in short chains.
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
                  Eq a b ->
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

callTwee :: [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTwee units goal@(Eq l r) = do
  let relUnits   = relevantUnits goal units
      rawEqUnits = [(i, ue) | (i, ue) <- zip [(0::Int)..] relUnits, isEqLit (ueUnit ue)]
      -- Put general (variable-containing) equations before ground ones so Twee's
      -- proof strategy is consistent regardless of the prover's axiom ordering.
      eqUnits = sortBy (\(_, u1) (_, u2) ->
                  compare (null (litVars (ueUnit u1))) (null (litVars (ueUnit u2))))
                rawEqUnits
      mkId i ue = maybe ("anon_" ++ show i) sanitizeId (ueName ue)
      idToUe  = Map.fromList [(mkId i ue, ue) | (i, ue) <- eqUnits]
      axioms  = [ toCnfAxiom (mkId i ue) a b
                | (i, ue) <- eqUnits, Eq a b <- [ueUnit ue] ]
      negGoal = toCnfNegGoal "goal" l r
      input   = unlines (axioms ++ [negGoal])
  out <- runTwee "eq" input
  return (parseTweeChain idToUe out l r)
callTwee units goal@(Rel name args) = do
  let goalTerm  = if null args then Const name else App name args
      indexed   = zip [(0::Int)..] (relevantUnits goal units)
      mkId i ue = maybe ("anon_" ++ show i) sanitizeId (ueName ue)
      toAxiom (i, ue) = case ueUnit ue of
        Eq a b   -> Just (toCnfAxiom (mkId i ue) a b)
        Rel n as -> Just (toCnfAxiom (mkId i ue) (if null as then Const n else App n as) (Const "true"))
        _        -> Nothing
      axioms  = mapMaybe toAxiom indexed
      negGoal = toCnfNegGoal "goal" goalTerm (Const "true")
      input   = unlines (axioms ++ [negGoal])
      idToUe  = Map.fromList [(mkId i ue, ue) | (i, ue) <- indexed, isEqLit (ueUnit ue) || isRelLit (ueUnit ue)]
  out <- runTwee "horn" input
  return (parseTweeChain idToUe out goalTerm (Const "true"))
  where
    isRelLit (Rel _ _) = True
    isRelLit _         = False
callTwee _ _ = return Nothing
