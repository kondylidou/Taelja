module LemmaBuilder
  ( flattenParents
  , ancestorNamesOf
  , findLemmaCandidates
  , buildCandidateLemma
  , makeFileSourced
  ) where

import Data.List (intercalate, nub)
import Data.Maybe (fromMaybe, isJust)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import qualified Data.Text as Text

import Types
import Helpers (applySubst, applyConstSubstLit, applyConstSubstTerm, applySubstTerm, litVars)
import ProofTree (headLitOf, unitNameStr, isPositiveUnitFormula)
import TptpConvert
import TweeInterface

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

-- A TPTP declaration is a pure positive-unit equation (no body, equality head)
-- Derived positive-unit clauses (equational, relational, or Horn) used ≥ 2 times
-- as parents in the DAG, returned in original topological order.
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
        , isJust (headLitOf decl)  -- exactly one positive literal (unit or Horn)
        , Map.findWithDefault 0 (unitNameStr n) parentCounts >= 2
        ]
  in [ (unitNameStr n, decl)
     | T.Unit n decl _ <- units
     , Set.member (unitNameStr n) candidateSet
     ]

-- Build a proof for candidate equation via direct Twee call.
-- tstp2name: TSTP unit name -> main-proof axiom name (from assignAxiomNames).
-- Returns (original-var-form lit, proof block with undo-Skolem) or Nothing.
buildCandidateLemma
  :: Map.Map String T.Unit
  -> Map.Map String String
  -> (String, T.Declaration)
  -> IO (Maybe (Literal, ProofBlock))
buildCandidateLemma unitMap tstp2name (cname, cdecl) =
  case headLitOf cdecl of
    Nothing -> return Nothing
    Just tlit ->
      let lit = convertLit tlit
      in case lit of
           Eq l r -> do
             let vs      = nub (litVars lit)
                 skMap   = zip vs ["skc_" ++ show i | i <- [(0 :: Int) ..]]
                 skSubst = [(v, Const sk) | (v, sk) <- skMap]
                 l_sk    = applySubstTerm skSubst l
                 r_sk    = applySubstTerm skSubst r

             let ancNames  = ancestorNamesOf unitMap cname
                 axEntries =
                   [ UnitEntry (Map.lookup aname tstp2name) aeq Nothing Nothing
                   | aname <- Set.toList ancNames
                   , Just u@(T.Unit _ adecl _) <- [Map.lookup aname unitMap]
                   , not (isDerivedUnit u)
                   , isOrigAxiomDecl adecl
                   , isPositiveUnitFormula adecl  -- exclude clauses with body literals
                   , Just headL <- [headLitOf adecl]
                   , let aeq = convertLit headL
                   , isEqLit aeq
                   ]

             mRes <- callTwee axEntries (Eq l_sk r_sk)
             case mRes of
               Nothing       -> return Nothing
               Just (_, [])  -> return Nothing
               Just (start, chain) -> do
                 let undoMap = [(sk, Var v) | (v, sk) <- skMap]
                     steps   = [ ( RwStep nm eq dir
                                 , applyConstSubstTerm undoMap cur )
                               | (ue, dir, cur) <- chain
                               , let nm = fromMaybe "?" (ueName ue)
                               , let eq = case ueUnit ue of
                                            Eq a b -> (a, b)
                                            _      -> (Const "?", Const "?")
                               ]
                     blk = EqChain (applyConstSubstTerm undoMap start) steps
                 -- Reject if any step references an ancestor not visible in the main proof
                 if any (\(RwStep nm _ _, _) -> nm == "?") steps
                   then return Nothing
                   else return (Just (lit, blk))

           Rel _ _ -> do
             let bodyTLits   = bodyLitsOf cdecl
                 bodyLits    = map convertLit bodyTLits
                 allVs       = nub (litVars lit ++ concatMap litVars bodyLits)
                 skMap       = zip allVs ["skc_" ++ show i | i <- [(0::Int)..]]
                 skSubst     = [(v, Const sk) | (v, sk) <- skMap]
                 lit_sk      = applySubst skSubst lit
                 bodyLits_sk = map (applySubst skSubst) bodyLits

             let ancNames = ancestorNamesOf unitMap cname
                 ancOrigUnits =
                   [ (sanitizeId aname, adecl)
                   | aname <- Set.toList ancNames
                   , Just u@(T.Unit _ adecl _) <- [Map.lookup aname unitMap]
                   , not (isDerivedUnit u)
                   , isOrigAxiomDecl adecl
                   , isJust (headLitOf adecl)
                   ]
                 -- Positive-unit ancestors (eq or rel) as UnitEntry background
                 unitAxEntries =
                   [ UnitEntry (Map.lookup aname tstp2name) aeq Nothing Nothing
                   | (aname, adecl) <- ancOrigUnits
                   , isPositiveUnitFormula adecl
                   , Just headL <- [headLitOf adecl]
                   , let aeq = convertLit headL
                   ]
                 -- Horn clause ancestors: only include those where every body variable
                 -- also appears in the head (safe ifeq encoding; multi-body ancestors
                 -- with extra body-only variables cause two to over-generalise).
                 hornFOFs =
                   [ toFOFHornAxiom (aname ++ "_anc") adecl
                   | (aname, adecl) <- ancOrigUnits
                   , not (isPositiveUnitFormula adecl)
                   , let hds  = map convertLit (bodyLitsOf adecl)
                         hds' = maybe [] (pure . convertLit) (headLitOf adecl)
                         hVs  = Set.fromList (concatMap litVars hds')
                         bVs  = Set.fromList (concatMap litVars hds)
                   , bVs `Set.isSubsetOf` hVs
                   ]
                 -- Skolemized body lits as ground premises in callTweeRelLemma
                 premEntries =
                   [ UnitEntry (Just ("prem_" ++ show i)) bl Nothing Nothing
                   | (i, bl) <- zip [(0::Int)..] bodyLits_sk
                   ]

             ok <- callTweeRelLemma (unitAxEntries ++ premEntries) hornFOFs lit_sk
             if not ok
               then return Nothing
               else do
                 let undoMap   = [(sk, Var v) | (v, sk) <- skMap]
                     headU     = applyConstSubstLit undoMap lit
                     bodyUs    = map (applyConstSubstLit undoMap) bodyLits
                     ancNms    = nub [nm | ue <- unitAxEntries, Just nm <- [ueName ue]]
                     justStr   = if null ancNms then "axioms" else intercalate ", " ancNms
                     haveLines = [Have bl "assumption" | bl <- bodyUs]
                     henceLine = Hence headU (ByAxiom justStr)
                     blk       = HaveHence (haveLines ++ [henceLine])
                 return (Just (lit, blk))

           _ -> return Nothing

-- Replace a candidate unit's inference source with a synthetic file source so
-- that buildProofInfo treats it as an OrigAxiom leaf (halts expansion there).
makeFileSourced :: T.Unit -> T.Unit
makeFileSourced (T.Unit n decl _) =
  T.Unit n decl (Just (T.File (T.Atom (Text.pack "lemma")) Nothing, Nothing))
makeFileSourced u = u
