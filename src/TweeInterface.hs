module TweeInterface
  ( tweeBin
  , tweemaxtime
  , toTptpTerm
  , toCnfAxiom
  , toCnfNegGoal
  , toFOFHornAxiom
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
  ) where

import Control.Applicative ((<|>))
import Data.Char (isAsciiLower, isAsciiUpper, isDigit, toUpper)
import Data.List (intercalate, isInfixOf, isPrefixOf, nub, sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Map.Strict as Map
import qualified Data.TPTP as T
import System.Environment (lookupEnv)
import System.Process (readProcessWithExitCode)

import Types
import Helpers (appendLine, litVars, rewriteTermAll)
import TptpConvert

tweeBin :: FilePath
tweeBin = "bin/twee"

-- Read the per-call Twee time limit from the environment.
-- Defaults to 15s; set TAELJA_TWEE_TIMEOUT=60 (or any integer) to override.
tweemaxtime :: IO String
tweemaxtime = fromMaybe "15" <$> lookupEnv "TAELJA_TWEE_TIMEOUT"

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

-- Call twee to decide whether a Skolemized relational goal follows from
-- the given unit ancestors plus Horn-clause ancestors (pre-formatted as FOF).
-- Returns True iff twee finds "Unsatisfiable".
callTweeRelLemma :: [UnitEntry] -> [String] -> Literal -> IO Bool
callTweeRelLemma units hornFOFs goalLit = do
  let goalTerm   = litToRelTerm goalLit
      indexed    = zip [(0::Int)..] units
      mkId i ue  = maybe ("anon_" ++ show i) sanitizeId (ueName ue)
      toAxiom (i, ue) = case ueUnit ue of
        Eq a b   -> Just (toCnfAxiom (mkId i ue) a b)
        Rel n as -> Just (toCnfAxiom (mkId i ue) (relTerm n as) (Const "true"))
        _        -> Nothing
      unitAxioms = mapMaybe toAxiom indexed
      negGoal    = toCnfNegGoal "goal" goalTerm (Const "true")
      input      = unlines (unitAxioms ++ hornFOFs ++ [negGoal])
      tmpFile    = "/tmp/taelja_twee_rel_lemma.p"
  writeFile tmpFile input
  maxTime <- tweemaxtime
  (_, out, _) <- readProcessWithExitCode tweeBin
                   ["--no-colour", "--no-lemmas", "--multi", "--max-time", maxTime, tmpFile] ""
  return ("Unsatisfiable" `isInfixOf` out)
  where
    litToRelTerm (Rel n as) = relTerm n as
    litToRelTerm _          = Const "?"
    relTerm n []            = Const n
    relTerm n as            = App n as

sanitizeId :: String -> String
sanitizeId = map (\c -> if c == ' ' then '_' else c)

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
callTwee units (Eq l r) = do
  let rawEqUnits = [(i, ue) | (i, ue) <- zip [(0::Int)..] units, isEqLit (ueUnit ue)]
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
      tmpFile = "/tmp/taelja_twee_input.p"
  writeFile tmpFile input
  maxTime <- tweemaxtime
  (_, out, _) <- readProcessWithExitCode tweeBin
                   ["--no-colour", "--formal-proof", "--no-lemmas", "--multi", "--max-time", maxTime, tmpFile] ""
  return (parseTweeChain idToUe out l r)
callTwee units (Rel name args) = do
  let goalTerm  = if null args then Const name else App name args
      indexed   = zip [(0::Int)..] units
      mkId i ue = maybe ("anon_" ++ show i) sanitizeId (ueName ue)
      toAxiom (i, ue) = case ueUnit ue of
        Eq a b   -> Just (toCnfAxiom (mkId i ue) a b)
        Rel n as -> Just (toCnfAxiom (mkId i ue) (if null as then Const n else App n as) (Const "true"))
        _        -> Nothing
      axioms  = mapMaybe toAxiom indexed
      negGoal = toCnfNegGoal "goal" goalTerm (Const "true")
      input   = unlines (axioms ++ [negGoal])
      idToUe  = Map.fromList [(mkId i ue, ue) | (i, ue) <- indexed, isEqLit (ueUnit ue) || isRelLit (ueUnit ue)]
      tmpFile = "/tmp/taelja_twee_horn_input.p"
  writeFile tmpFile input
  maxTime <- tweemaxtime
  (_, out, _) <- readProcessWithExitCode tweeBin
                   ["--no-colour", "--formal-proof", "--no-lemmas", "--multi", "--max-time", maxTime, tmpFile] ""
  return (parseTweeChain idToUe out goalTerm (Const "true"))
  where
    isRelLit (Rel _ _) = True
    isRelLit _         = False
callTwee _ _ = return Nothing
