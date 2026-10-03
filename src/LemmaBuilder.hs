-- Lemma introduction. A derived positive unit the proof cites at least twice
-- is proved once, from its own derivation or by a Twee chain, and cited at
-- its uses.
module LemmaBuilder
  ( findLemmaCandidates
  , BuiltLemma
  , makeFileSourced
  , buildAllCandidates
  , orderPrebuiltLemmas
  ) where

import Control.Monad (foldM, when)
import Control.Applicative ((<|>))
import Data.List (nub, stripPrefix)
import Data.Maybe (isJust, listToMaybe, maybeToList)
import Data.TPTP.Pretty (Pretty (..))
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import qualified Data.Text as Text
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
  ( applyConstSubstBlock, applyConstSubstLit, axiomName, blockRefNames, blockVars
  , blockConcludes, freezeLitVars, isEmptyBlock, litVars, renameBlock, renameLit
  , renameRefsBlock, sanitizeId, underscoreApart, unitEquation
  )
import Debug (dbgScoped)
import Conjecture (conjectureHypotheses)
import ProofTree (classifyRole, resolveCopySource)
import TptpConvert
import TweeInterface (TweeBudget (..), callTwee)
import StepReader (isAtomEquation, reverseChain)

-- The names of every ancestor of rootName, itself excluded.
ancestorNamesOf :: Map.Map String T.Unit -> String -> Set.Set String
ancestorNamesOf unitMap rootName = go startFrontier Set.empty
  where
    -- a bare reference, as E copies a unit, counts as a parent too
    parentsOf nm = maybe Set.empty (Set.fromList . unitParents) (Map.lookup nm unitMap)

    startFrontier = parentsOf rootName

    go frontier seen = case Set.minView frontier of
      Nothing -> seen
      Just (nm, rest)
        | Set.member nm seen -> go rest seen
        | otherwise          ->
            go (Set.union rest (parentsOf nm)) (Set.insert nm seen)

-- The lemma candidates in proof order, derived positive units cited as a
-- parent at least twice. An equation with an atom as a side is not
-- first-order and is left out.
findLemmaCandidates :: [T.Unit] -> [(String, T.Declaration)]
findLemmaCandidates units =
  let candidateSet = Set.fromList
        [ unitNameStr n
        | T.Unit n decl (Just (T.Inference {}, _)) <- units
        -- one positive literal, and no disequation, which no lemma states
        , maybe False (not . isTDisequality) (headLitOf decl)
        -- a lemma is a single literal, so a Horn clause is inlined instead
        , null (bodyLitsOf decl)
        , Map.findWithDefault 0 (unitNameStr n) (premiseUses units) >= 2
        , not (maybe False (isAtomEquation preds . convertLit) (headLitOf decl))
        ]
      preds = predicateSymbols units
  in [ (unitNameStr n, decl)
     | T.Unit n decl _ <- units
     , Set.member (unitNameStr n) candidateSet
     ]

-- Turns the Skolem constants back into the candidate's variables. A sub-proof
-- variable with the same name as one of them is renamed apart first.
deSkolemizeBlock :: [(String, Term)] -> ProofBlock -> ProofBlock
deSkolemizeBlock undoMap blk =
  applyConstSubstBlock undoMap (renameBlock (apartFrom undoMap (blockVars blk)) blk)

-- Renames each of vs that is also a candidate variable by adding _l.
apartFrom :: [(String, Term)] -> [String] -> [(String, String)]
apartFrom undoMap vs = [ (v, v ++ "_l") | v <- nub vs, v `elem` [ w | (_, Var w) <- undoMap ] ]

-- Replaces a unit's inference by a file source, so buildProofInfo reads it as
-- an input and stops there.
makeFileSourced :: T.Unit -> T.Unit
makeFileSourced (T.Unit n decl _) =
  T.Unit n decl (Just (T.File (T.Atom (Text.pack "lemma")) Nothing, Nothing))
makeFileSourced u = u

-- A lemma's statement, its proof, its sub-lemmas (renamed apart and
-- de-Skolemized, to go before it) and the axioms its sub-run numbered itself.
-- Those are file axioms the outer proof never used, so the caller must give
-- them outer names, or the lifted block would cite the wrong axiom.
type BuiltLemma = (Literal, ProofBlock, [(String, Literal, ProofBlock)], [Axiom])

-- Builds the lemma for a candidate unit B. B is Skolemized, its derivation is
-- translated recursively as a refutation of ~B, and the result de-Skolemized.
-- When that fails, an equation may still get a Twee chain. translateFn comes
-- in as an argument because Translate imports this module.
buildCandidateLemma
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Either String StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String  -- TSTP name to display name in the outer proof
  -> Bool                   -- debug
  -> (String, T.Declaration)
  -> IO (Maybe BuiltLemma)
buildCandidateLemma translateFn unitMap tstp2name debug (cname, cdecl) =
  case headLitOf cdecl of
    Nothing   -> return Nothing
    Just tlit -> do
      let lit             = convertLit tlit
          taken           = concat [ fs ++ ps | T.Unit _ d _ <- Map.elems unitMap, let (fs, ps) = declSymbols d ]
          (litSkolem, undoMap) = freezeLitVars "skc_" taken lit
      mFromSubDag <- buildFromSubDag translateFn unitMap tstp2name debug cname lit litSkolem undoMap
      case mFromSubDag of
        Just r  -> return (Just r)
        Nothing -> buildWithTwee unitMap tstp2name cname lit litSkolem undoMap

-- The candidate's own derivation as a refutation of ~B, so no prover is
-- needed. The sub-problem is its ancestors, the candidate, its Skolemized
-- negation and a resolution of the two to $false.
buildFromSubDag
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Either String StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String
  -> Bool
  -> String -> Literal -> Literal -> [(String, Term)]
  -> IO (Maybe BuiltLemma)
buildFromSubDag translateFn unitMap tstp2name debug cname lit litSkolem undoMap = do
  let ancNames  = ancestorNamesOf unitMap cname
      -- the two units the sub-problem adds get names apart from its own,
      -- also once sanitized
      ids       = Set.union (Set.insert cname ancNames) (Set.map sanitizeId (Set.insert cname ancNames))
      negName   = underscoreApart (`Set.member` ids) "negconj"
      botName   = underscoreApart (`Set.member` ids) "lemma_bot"
      -- The outer conjecture is left out, or the sub-run would take the
      -- outer goal for its own. Negated conjecture clauses stay, since
      -- they carry the hypotheses the conjecture grants, and as they cite
      -- the conjecture they are inputs of the sub-problem.
      kept      = [ u | aname <- Set.toList ancNames, Just u@(T.Unit _ d _) <- [Map.lookup aname unitMap]
                      , not (isConjectureDecl d) ]
      keptNames = Set.fromList [ unitNameStr n | T.Unit n _ _ <- kept ]
      ancUnits  = [ if all (`Set.member` keptNames) (unitParents u) then u else makeFileSourced u | u <- kept ]
      candUnit  = maybeToList (Map.lookup cname unitMap)
      unitLines = map (show . pretty) (ancUnits ++ candUnit)
      negLine   = "cnf(" ++ negName ++ ", negated_conjecture, " ++ tptpLiteral (negLit litSkolem) ++ ")."
      botLine   = "cnf(" ++ botName ++ ", plain, $false, inference(resolution,[status(thm)],["
                  ++ cname ++ ", " ++ negName ++ "]))."
      content   = unlines (unitLines ++ [negLine, botLine])
      -- E keeps several clausified copies of an axiom, and an ancestor
      -- may be one the outer proof did not name. It takes the outer name
      -- of its source, or the sub-run would number it afresh.
      bySource  = Map.fromList
        [ (resolveCopySource unitMap k, dn) | (k, dn) <- Map.toList tstp2name ]
      copyOverride = Map.fromList
        [ (aname, dn)
        | aname <- Set.toList ancNames
        , not (Map.member aname tstp2name)
        , Just dn <- [Map.lookup (resolveCopySource unitMap aname) bySource]
        ]
      -- the negation is the sub-run's goal, not an axiom, so it gets no name
      nameOverride   = Map.unions [Map.singleton negName "", tstp2name, copyOverride]
  when debug $ hPutStrLn stderr ("buildCandidateLemma: sub-DAG for " ++ cname ++ ":\n" ++ content)
  case parseTptp (Text.pack content) of
    -- the sub-problem is printed here, so a parse error is a bug and is
    -- reported
    Left err -> do
      hPutStrLn stderr ("[warn] lemma " ++ cname ++ ": its sub-problem does not parse, so it is not introduced: " ++ err)
      return Nothing
    Right tstp -> do
      sub <- dbgScoped debug ("sub-DAG for " ++ cname) (translateFn nameOverride debug tstp)
      case sub of
        Left reason -> do
          when debug $ hPutStrLn stderr ("buildCandidateLemma: no lemma for " ++ cname ++ ", " ++ reason)
          return Nothing
        Right sp -> return (liftSubProof nameOverride cname lit undoMap sp)

-- Turns the recursive translation of a candidate into an outer lemma. The goal
-- block becomes its proof, and the sub-lemmas are renamed apart and
-- de-Skolemized with it. The proof must end on the candidate.
liftSubProof :: Map.Map String String -> String -> Literal -> [(String, Term)]
             -> StructuredProof -> Maybe BuiltLemma
liftSubProof nameOverride cname lit undoMap sp = do
  (_, goalBlk) <- listToMaybe (goals sp)
  let subLemmas = lemmas sp
      newName n = "lemma " ++ cname ++ "/" ++ n
      renaming  = Map.fromList [ (n, newName n) | (n, _, _) <- subLemmas ]
      lift blk  = deSkolemizeBlock undoMap (renameRefsBlock (\nm -> Map.findWithDefault nm nm renaming) blk)
      lifted    = [ (newName n, applyConstSubstLit undoMap (renameLit (apartFrom undoMap (litVars l)) l), lift b) | (n, l, b) <- subLemmas ]
      blk'      = lift goalBlk
      -- Axiom names taken from the outer proof. The sub-run numbered the
      -- others itself.
      outerNames = Set.fromList (filter (not . null) (Map.elems nameOverride))
      ownAxioms = [ a | a <- axioms sp, axiomName a `Set.notMember` outerNames ]
  if isEmptyBlock blk' || not (blockConcludes lit blk')
    then Nothing
    else Just (lit, blk', lifted, ownAxioms)

-- The fallback for an equation whose ancestor axioms are all unit equations.
-- Twee is asked for a chain from them.
buildWithTwee
  :: Map.Map String T.Unit
  -> Map.Map String String
  -> String -> Literal -> Literal -> [(String, Term)]
  -> IO (Maybe BuiltLemma)
buildWithTwee unitMap tstp2name cname lit litSkolem undoMap = case litSkolem of
  Eq l r | Just units <- mapM unitEquationOf origAncestors -> do
    mChain <- callTwee InternalBudget units (Eq l r)
    return $ case mChain of
      Just (start, chain)
        | not (null chain)
        , all (isJust . ueName . (\(ue, _, _) -> ue)) chain ->
            -- a chain from r to l is reversed, so the lemma states the
            -- candidate as the proof cites it
            let chain' | start == l = chain
                       | otherwise  = reverseChain start chain
                steps = [ (RwStep nm (unitEquation (ueUnit ue)) dir, cur)
                        | (ue, dir, cur) <- chain', Just nm <- [ueName ue] ]
            in Just (lit, deSkolemizeBlock undoMap (EqChain l steps), [], [])
      _ -> Nothing
  _ -> return Nothing
  where
    granted = maybe [] (uncurry (++)) (conjectureHypotheses (Map.elems unitMap))
    dispNameOf aname =
      Map.lookup (resolveCopySource unitMap aname) tstp2name
        <|> Map.lookup aname tstp2name
    -- An original axiom is an underived axiom or hypothesis, another
    -- underived clause that classifyRole reads as an axiom, such as one the
    -- conjecture grants, or a clausified copy of a file axiom, which E marks
    -- plain. The last two also need a display name.
    origAncestors =
      [ (aname, adecl)
      | aname <- Set.toList (ancestorNamesOf unitMap cname)
      , Just u@(T.Unit _ adecl _) <- [Map.lookup aname unitMap]
      , isOrigAncestor aname u adecl ]
    isOrigAncestor aname u adecl =
      (not (isDerivedUnit u) && hasAxiomRole adecl)
        || (not (isDerivedUnit u) && classifyRole granted unitMap aname adecl == OrigAxiom
            && isJust (dispNameOf aname))
        || (isFileUnit unitMap copySrc
            && maybe False hasAxiomRole (lookupDecl unitMap copySrc)
            && isJust (dispNameOf aname))
      where copySrc = resolveCopySource unitMap aname
    unitEquationOf (aname, adecl)
      | isPositiveUnitFormula adecl
      , Just eq@(Eq _ _) <- convertLit <$> headLitOf adecl
      = Just (UnitEntry (dispNameOf aname) eq Nothing Nothing)
      | otherwise = Nothing

-- The complement of a literal.
negLit :: Literal -> Literal
negLit (Rel n as)  = NRel n as
negLit (Eq l r)    = NEq l r
negLit (NRel n as) = Rel n as
negLit (NEq l r)   = Eq l r

-- Builds the candidates in order. Later ones see each earlier lemma as a file
-- axiom named "lemma c", so they cite it instead of proving it again.
buildAllCandidates
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Either String StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String  -- TSTP name to display name in the outer proof
  -> Bool                   -- debug
  -> [(String, T.Declaration)]
  -> IO [Maybe BuiltLemma]
buildAllCandidates translateFn unitMap tstp2name debug cands =
  reverse . snd <$> foldM buildOne ([], []) cands
  where
    buildOne (done, acc) c = do
      let unitMapC = foldr (Map.adjust makeFileSourced) unitMap done
          namesC   = foldr (\c' -> Map.insert c' ("lemma " ++ c')) tstp2name done
      v <- buildCandidateLemma translateFn unitMapC namesC debug c
      return (if isJust v then done ++ [fst c] else done, v : acc)

-- The pre-built lemmas in the order the proof tree reaches them, given as
-- (TSTP name, display name). Each follows the lemmas it cites, which the tree
-- may not reach itself, and its own sub-lemmas.
orderPrebuiltLemmas :: Map.Map String BuiltLemma -> [(String, String)] -> [(String, Literal, ProofBlock)]
orderPrebuiltLemmas built reached = snd (foldl emit (Set.empty, []) reached)
  where
    emit (seen, acc) (c, nm)
      | Set.member c seen = (seen, acc)
      | Just (lit, blk, lifted, _) <- Map.lookup c built =
          let cited = [ c' | ref <- concatMap blockRefNames (blk : [ b | (_, _, b) <- lifted ])
                           , Just c' <- [stripPrefix "lemma " ref]
                           , c' /= c, Map.member c' built ]
              (seen', acc') = foldl emit (Set.insert c seen, acc) [ (c', "lemma " ++ c') | c' <- cited ]
          in (seen', acc' ++ lifted ++ [(nm, lit, blk)])
      | otherwise = (seen, acc)
