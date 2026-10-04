-- Twee as the rewrite fallback. A goal and the units relevant to it go to
-- Twee as a TPTP problem, and its proof comes back as a chain of rewrites by
-- those units. One time budget covers all Twee calls of a run.
module TweeInterface
  ( disableFallback
  , startFallbackBudget
  , fallbackBudgetSpent
  , callTwee
  , TweeBudget (..)
  ) where

import Control.Applicative ((<|>))
import Control.Exception (bracket)
import Control.Monad (when)
import Data.Bifunctor (first)
import Data.Char (isAsciiLower, isAsciiUpper, isDigit)
import Data.IORef (IORef, modifyIORef', newIORef, readIORef, writeIORef)
import Data.List (isInfixOf, isPrefixOf, nub, sortBy)
import Data.Maybe (fromMaybe, isNothing, listToMaybe)
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import GHC.Clock (getMonotonicTime)
import System.Directory (doesFileExist, findExecutable, getTemporaryDirectory, removeFile)
import System.Environment (lookupEnv)
import System.IO (hClose, hPutStr, hPutStrLn, openTempFile, stderr)
import System.IO.Unsafe (unsafePerformIO)
import System.Process (readProcessWithExitCode)
import System.Timeout (timeout)
import Text.Read (readMaybe)

import Types
import Helpers (atomTerm, foldLiteralTerms, isEqLit, isRelLit, litNames, mapLiteralTerms, litVars, notVar, rewriteTermAll, sanitizeId, trySync, unitEquation)
import TptpConvert (isLowerWord, tptpLiteral)

-- Twee's binary, cached after the first lookup.
{-# NOINLINE tweeBinary #-}
tweeBinary :: IORef (Maybe (Maybe FilePath))
tweeBinary = unsafePerformIO (newIORef Nothing)

-- Whether Twee may be called at all. --no-fallback turns it off, so the
-- translation uses only what the input proof states.
{-# NOINLINE fallbackEnabled #-}
fallbackEnabled :: IORef Bool
fallbackEnabled = unsafePerformIO (newIORef True)

-- Turns Twee off for the run, as --no-fallback asks.
disableFallback :: IO ()
disableFallback = writeIORef fallbackEnabled False

-- Finds Twee, at TAELJA_TWEE if that names an existing file, else at bin/twee
-- in the current directory, else on the PATH. If none exists, a warning is
-- printed once and every Twee call answers nothing. With the fallback off
-- there is no Twee.
findTwee :: IO (Maybe FilePath)
findTwee = do
  enabled <- readIORef fallbackEnabled
  cached  <- readIORef tweeBinary
  case cached of
    _ | not enabled -> return Nothing
    Just found      -> return found
    Nothing         -> do
      env    <- lookupEnv "TAELJA_TWEE"
      envOk  <- maybe (return False) doesFileExist env
      local  <- doesFileExist "bin/twee"
      onPath <- findExecutable "twee"
      let found = (if envOk then env else Nothing)
                  <|> (if local then Just "bin/twee" else Nothing) <|> onPath
      when (isNothing found) $ hPutStrLn stderr $
        "taelja: no twee found, so rewrite fallbacks are off.  Set TAELJA_TWEE"
        ++ ", put it at bin/twee or on the PATH"
        ++ maybe "" (\p -> " (TAELJA_TWEE is " ++ p ++ ", which does not exist)") env
      writeIORef tweeBinary (Just found)
      return found

-- Run Twee for at most secs or what is left of the run's budget, whichever
-- is smaller. Twee's own --max-time can overrun by minutes, so on timeout
-- the process is killed and the answer is Nothing.
runCapped :: Int -> FilePath -> [String] -> IO (Maybe String)
runCapped secs bin args = do
  deadline <- readIORef fallbackDeadline
  now      <- getMonotonicTime
  let remaining = deadline - now
  if remaining <= 0
    then writeIORef fallbackExhausted True >> return Nothing
    else do
      let cap = min secs (ceiling remaining)
      r <- timeout (cap * 1000000) (trySync (readProcessWithExitCode bin args ""))
      now' <- getMonotonicTime
      when (now' >= deadline) $ writeIORef fallbackExhausted True
      return $ case r of
        Just (Right (_, out, _)) -> Just out
        _                        -> Nothing

-- One deadline for all Twee calls of a run, so a run takes at most Taelja's
-- own work plus this budget. The top-level translation starts it and
-- sub-runs share it.
{-# NOINLINE fallbackDeadline #-}
fallbackDeadline :: IORef Double
fallbackDeadline = unsafePerformIO (newIORef 0)

-- Whether a Twee call of this run has reached the deadline.
{-# NOINLINE fallbackExhausted #-}
fallbackExhausted :: IORef Bool
fallbackExhausted = unsafePerformIO (newIORef False)

-- Starts the run's Twee budget from TAELJA_FALLBACK_TIMEOUT, 30 seconds by
-- default, and clears the answer cache. Returns the budget in seconds.
startFallbackBudget :: IO Int
startFallbackBudget = do
  writeIORef tweeCache Map.empty
  secs <- timeoutSecsFromEnv "TAELJA_FALLBACK_TIMEOUT" 30
  now  <- getMonotonicTime
  writeIORef fallbackDeadline (now + fromIntegral secs)
  writeIORef fallbackExhausted False
  return secs

-- Whether the run's Twee budget ran out.
fallbackBudgetSpent :: IO Bool
fallbackBudgetSpent = readIORef fallbackExhausted

-- Seconds from an environment variable, or the default when it is unset or
-- unreadable. At least 1, since zero would fail at once and a negative
-- value would disable the wall-clock kill.
timeoutSecsFromEnv :: String -> Int -> IO Int
timeoutSecsFromEnv var def = max 1 . fromMaybe def . (>>= readMaybe) <$> lookupEnv var

-- The time limit of one Twee call. A goal's chain gets TAELJA_TWEE_TIMEOUT,
-- and a speculative internal call the smaller TAELJA_TWEE_INTERNAL_TIMEOUT,
-- so failed guesses cannot eat the whole run.
data TweeBudget = GoalBudget | InternalBudget deriving (Eq, Show)

-- Twee's output for a problem, empty when there is none. The translation
-- asks the same questions many times, so answers are cached per problem and
-- time limit until a new budget starts. A call cut short is cached as no
-- answer, or it would be retried until the budget is gone.
runTwee :: TweeBudget -> String -> String -> IO String
runTwee budget tag input = do
  goalSecs <- timeoutSecsFromEnv "TAELJA_TWEE_TIMEOUT" 15
  secs <- case budget of
    GoalBudget     -> return goalSecs
    InternalBudget -> min goalSecs <$> timeoutSecsFromEnv "TAELJA_TWEE_INTERNAL_TIMEOUT" 5
  cached <- Map.lookup (input, secs) <$> readIORef tweeCache
  out <- fromMaybe "" <$> case cached of
    Just out -> return out
    Nothing  -> do
      mBin <- findTwee
      out <- case mBin of
        Nothing  -> return Nothing
        Just bin -> withTempInput tag input $ \path -> runCapped (secs + 5) bin
                      ["--no-colour", "--formal-proof", "--no-lemmas", "--multi", "--max-time", show secs, path]
      modifyIORef' tweeCache (Map.insert (input, secs) out)
      return out
  -- TAELJA_TWEE_DEBUG=1 prints every call's input and output
  dumpEnv <- lookupEnv "TAELJA_TWEE_DEBUG"
  when (dumpEnv == Just "1") $
    hPutStrLn stderr ("[twee " ++ tag ++ "] input:\n" ++ input ++ "[twee " ++ tag ++ "] output:\n" ++ out)
  return out

-- Twee's answers by problem and time limit, cleared when a budget starts.
{-# NOINLINE tweeCache #-}
tweeCache :: IORef (Map.Map (String, Int) (Maybe String))
tweeCache = unsafePerformIO (newIORef Map.empty)

-- Run an action on the problem written to a fresh temp file, so concurrent
-- runs never collide. The file is removed even when the action throws.
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

-- Keep the units whose symbols are reachable from the goal's through other
-- units, since unrelated equations only widen Twee's search. An equation
-- with a bare variable side rewrites any term, so it is always kept and its
-- symbols count as reachable.
relevantUnits :: Literal -> [UnitEntry] -> [UnitEntry]
relevantUnits goal units = filter keep units
  where
    keep u = universal (ueUnit u) || any (`elem` finalSyms) (litSyms (ueUnit u))
    universal (Eq (Var _) _) = True
    universal (Eq _ (Var _)) = True
    universal _              = False
    -- only positive units go to Twee, so only their symbols count
    litSyms l | isEqLit l || isRelLit l = litNames l
              | otherwise               = []
    allUnitSyms = map (litSyms . ueUnit) units
    expand syms =
      let newSyms = nub (syms ++ concat (filter (any (`elem` syms)) allUnitSyms))
      in if newSyms == syms then syms else expand newSyms
    finalSyms = expand (litSyms goal ++ concat [ litSyms (ueUnit u) | u <- units, universal (ueUnit u) ])

-- Parse a term of Twee's proof output. Variables start uppercase, and other
-- symbols lowercase or with an underscore.
parseTweeTerm :: String -> Maybe (Term, String)
parseTweeTerm s = case dropWhile (== ' ') s of
  s'@(c : _)
    | isAsciiUpper c -> Just (Var nm, rest)
    | isAsciiLower c || c == '_' -> case rest of
        '(' : more -> first (App nm) <$> parseTweeArgList more
        _          -> Just (Const nm, rest)
    where (nm, rest) = span (\x -> isAsciiLower x || isAsciiUpper x || isDigit x || x == '_') s'
  _ -> Nothing

-- The arguments of a Twee term up to its closing parenthesis, and the rest.
parseTweeArgList :: String -> Maybe ([Term], String)
parseTweeArgList = go []
  where
    go acc str = do
      (t, rest) <- parseTweeTerm str
      case dropWhile (== ' ') rest of
        ',' : more -> go (acc ++ [t]) more
        ')' : more -> Just (acc ++ [t], more)
        _          -> Nothing

-- Read Twee's --formal-proof output as a rewrite chain between l and r.
-- directChain takes Twee's terms verbatim, which works for ground proofs.
-- guidedChain replays only the cited units and directions and recomputes
-- each term, which copes with variables Twee renamed.
parseTweeChain
  :: Map.Map String UnitEntry
  -> String        -- Twee's stdout
  -> Term -> Term  -- expected start and end of chain
  -> Maybe (Term, [(UnitEntry, Dir, Term)])
parseTweeChain idToUe output l r = case dropWhile (not . isTermLine) afterProof of
    startLine : rest -> let steps = collectSteps rest
                        in directChain (skipSpaces startLine) steps <|> guidedChain steps
    []               -> Nothing
  where
    skipSpaces = dropWhile (== ' ')
    afterProof = drop 1 (dropWhile (not . isPrefixOf "Proof:" . skipSpaces) (lines output))
    isTermLine ln = case skipSpaces ln of
      c : _ -> isAsciiLower c || isAsciiUpper c || c == '_'
      []    -> False

    -- each line citing a unit, with its direction and the term line after it
    collectSteps [] = []
    collectSteps (ln : lns) = case citation ln of
      Just (nm, dir) -> case dropWhile (not . isTermLine) lns of
        tl : rest -> (nm, dir, skipSpaces tl) : collectSteps rest
        []        -> []
      Nothing -> collectSteps lns
    citation ln
      | "by axiom" `isInfixOf` s, not (null nm) = Just (nm, if "R->L" `isInfixOf` s then RL else LR)
      | otherwise                               = Nothing
      where s  = dropWhile (/= '{') ln
            nm = takeWhile (/= ')') (drop 1 (dropWhile (/= '(') s))

    directChain startStr steps = case (fst <$> parseTweeTerm startStr, mapM readStep steps) of
      (Just start, Just chain)
        | start == l && endsAt r chain -> Just (l, chain)
        | start == r && endsAt l chain -> Just (r, chain)
      _ -> Nothing
    readStep (nm, dir, termStr) = do
      ue <- Map.lookup nm idToUe
      (t, _) <- parseTweeTerm termStr
      Just (ue, dir, t)
    endsAt end chain = null chain || let (_, _, t) = last chain in t == end

    guidedChain steps = replay l r <|> replay r l
      where
        replay start end = (start,) <$> go start steps
          where
            go cur [] = if cur == end then Just [] else Nothing
            go cur ((nm, dir, _) : rest) = case Map.lookup nm idToUe of
              -- A rewrite from a bare variable, as by X = Y, would match
              -- every term and invent a step the proof never made, so
              -- such a step is skipped.
              Just ue | Eq a b <- ueUnit ue, notVar (if dir == LR then a else b) ->
                listToMaybe [ (ue, dir, t) : chain | t <- rewriteTermAll cur (a, b) dir, Just chain <- [go t rest] ]
              _ -> go cur rest

-- Asks Twee for a rewrite chain that proves the goal from the units. The
-- answer gives the side the chain starts from and its steps. Twee prints
-- symbols that are not plain names, such as '==>', infix, and parseTweeTerm
-- cannot read them back. They get plain aliases for the call, as do
-- Theorem 1's fresh constants, and the answer is renamed back.
callTwee :: TweeBudget -> [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTwee budget units goal
  | null unplain && null freshNames = callTweeUnaliased budget units goal
  | otherwise = fmap renameBack <$>
      callTweeUnaliased budget (map (onUnit (ren fwd) toCall) units) (onLit (ren fwd) toCall goal)
  where
    renameBack (t, ch) = (fromCall t, [ (onUnit (ren back) fromCall u, d, fromCall x) | (u, d, x) <- ch ])
    allLits    = map ueUnit units ++ [goal]
    syms       = nub (concatMap litNames allLits)
    unplain    = [ f | f <- syms, not (isLowerWord f) ]
    freshNames = nub (concatMap (foldLiteralTerms freshIn) allLits)
    freshIn (Fresh x)  = [x]
    freshIn (App _ ts) = concatMap freshIn ts
    freshIn _          = []
    names      = [ a | i <- [1 :: Int ..], let a = "taelja_sym" ++ show i, a `notElem` syms ]
    aliases    = zip unplain names
    freshAlias = Map.fromList (zip freshNames (drop (length unplain) names))
    fwd        = Map.fromList aliases
    back       = Map.fromList [ (a, f) | (f, a) <- aliases ]
    freshBack  = Map.fromList [ (a, x) | (x, a) <- Map.toList freshAlias ]
    ren m f = Map.findWithDefault f f m
    toCall (Fresh x)  = Const (freshAlias Map.! x)
    toCall (Const c)  = Const (ren fwd c)
    toCall (App f ts) = App (ren fwd f) (map toCall ts)
    toCall t          = t
    fromCall (Const c) = maybe (Const (ren back c)) Fresh (Map.lookup c freshBack)
    fromCall (App f ts) = App (ren back f) (map fromCall ts)
    fromCall t          = t
    onLit sym term (Rel n ts)  = Rel (sym n) (map term ts)
    onLit sym term (NRel n ts) = NRel (sym n) (map term ts)
    onLit _ term l             = mapLiteralTerms term l
    onUnit sym term u = u { ueUnit = onLit sym term (ueUnit u) }

-- Ask Twee for the goal from the relevant units. An equation goes as it is,
-- and an atom P(t) as P(t) = true.
callTweeUnaliased :: TweeBudget -> [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)]))
callTweeUnaliased budget units goal = case goal of
    -- Equations with variables go before ground ones, which makes Twee's
    -- search less sensitive to the order of the input proof.
    Eq l r  -> ask "eq" l r (sortBy (comparing (null . litVars . ueUnit . snd))
                                    [ iu | iu@(_, u) <- indexed, isEqLit (ueUnit u) ])
    Rel _ _ -> ask "horn" (atomTerm goal) (Const "true")
                   [ iu | iu@(_, u) <- indexed, isEqLit (ueUnit u) || isRelLit (ueUnit u) ]
    _       -> return Nothing
  where
    indexed = zip [0 :: Int ..] (relevantUnits goal units)
    -- The index keeps ids distinct, since sanitizing alone maps "axiom 3"
    -- and "axiom_3" to the same id.
    mkId i ue = maybe "anon" sanitizeId (ueName ue) ++ "_" ++ show i
    ask tag l r us = do
      let axioms = [ "cnf(" ++ mkId i ue ++ ", axiom, " ++ tptpLiteral (uncurry Eq (unitEquation (ueUnit ue))) ++ ")."
                   | (i, ue) <- us ]
          idToUe = Map.fromList [ (mkId i ue, ue) | (i, ue) <- us ]
      out <- runTwee budget tag (unlines (axioms ++ ["cnf(goal, negated_conjecture, " ++ tptpLiteral (NEq l r) ++ ")."]))
      return (parseTweeChain idToUe out l r)

