-- Lemma introduction. A derived Horn clause with a head that the proof cites
-- at least twice is proved once, from its own derivation or, for a unit
-- equation, by a Twee chain, and cited at its uses.
module LemmaBuilder
  ( findLemmaCandidates
  , BuiltLemma
  , makeFileSourced
  , lemmaInput
  , buildAllCandidates
  , orderPrebuiltLemmas
  ) where

import Control.Monad (guard, when)
import Control.Applicative ((<|>))
import Data.List (intercalate, nub, stripPrefix, zip4)
import Data.Maybe (isJust, listToMaybe, maybeToList)
import Data.Traversable (mapAccumM)
import Data.TPTP.Pretty (Pretty (..))
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import qualified Data.Text as Text
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
  ( applyConstSubstBlock, applyConstSubstLit, assumptionName, axiomName, blockRefNames
  , blockVars, blockConcludes, clauseHead, clauseLits, freezeClauseVars, isEmptyBlock, litVars
  , mapClauseLits, renameBlock, renameLit, renameRefsBlock, sanitizeId, underscoreApart
  , unitEquation
  )
import Debug (dbgScoped)
import Conjecture (conjectureHypotheses)
import ProofTree (classifyRole, resolveCopySource)
import TptpConvert
import TweeInterface (TweeBudget (..), callTwee)
import StepReader (isAtomEquation, reverseChain)

-- The names of every ancestor of rootName, itself excluded.
ancestorNamesOf :: Map.Map String T.Unit -> String -> Set.Set String
ancestorNamesOf unitMap rootName = go (parentsOf rootName) Set.empty
  where
    -- a bare reference, as E copies a unit, counts as a parent too
    parentsOf nm = maybe Set.empty (Set.fromList . unitParents) (Map.lookup nm unitMap)
    go frontier seen = case Set.minView frontier of
      Nothing -> seen
      Just (nm, rest)
        | Set.member nm seen -> go rest seen
        | otherwise          -> go (Set.union rest (parentsOf nm)) (Set.insert nm seen)

-- The lemma candidates in proof order, derived Horn clauses with a head cited
-- as a parent at least twice. An equation with an atom as a side is not
-- first-order and is left out.
findLemmaCandidates :: [T.Unit] -> [(String, T.Declaration)]
findLemmaCandidates units =
  [ (unitNameStr n, decl) | T.Unit n decl _ <- units, Set.member (unitNameStr n) candidates ]
  where
    uses = premiseUses units
    preds = predicateSymbols units
    candidates = Set.fromList
      [ unitNameStr n
      | T.Unit n decl (Just (T.Inference {}, _)) <- units
      -- one positive literal, and no disequation, which no lemma states
      , maybe False (not . isTDisequality) (headLitOf decl)
      , Map.findWithDefault 0 (unitNameStr n) uses >= 2
      , not (maybe False (isAtomEquation preds . convertLit) (headLitOf decl)) ]

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

-- A built lemma as an input unit. It takes the role lemma, so a clause the
-- prover derived from the negated conjecture is not read as part of the goal
-- once it is proved.
lemmaInput :: T.Unit -> T.Unit
lemmaInput u = case makeFileSourced u of
  T.Unit n (T.Formula _ f) src -> T.Unit n (T.Formula (T.Standard T.Lemma) f) src
  u'                           -> u'

-- A lemma's statement, its proof, its sub-lemmas (renamed apart and
-- de-Skolemized, to go before it) and the axioms its sub-run numbered itself.
-- Those are file axioms the outer proof never used, so the caller must give
-- them outer names, or the lifted block would cite the wrong axiom.
type BuiltLemma = (Clause, ProofBlock, [(String, Clause, ProofBlock)], [Axiom])

-- Builds the lemma for a candidate B1 /\ ... /\ Bn => H. Its variables become
-- Skolem constants, its derivation is translated recursively as a refutation
-- that assumes the Bi and ~H, and the result is de-Skolemized. When that
-- fails, a unit equation may still get a Twee chain. translateFn comes in as
-- an argument because Translate imports this module.
buildCandidateLemma
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Either String StructuredProof))
  -> [String]               -- the proof's symbols, which the Skolem constants avoid
  -> Map.Map String T.Unit
  -> Map.Map String String  -- TSTP name to display name in the outer proof
  -> Bool                   -- debug
  -> (String, T.Declaration)
  -> IO (Maybe BuiltLemma)
buildCandidateLemma translateFn taken unitMap tstp2name debug (cname, cdecl) =
  case headLitOf cdecl of
    Nothing   -> return Nothing
    Just tlit -> do
      let c = Clause (map convertLit (bodyLitsOf cdecl)) (Just (convertLit tlit))
          (cSkolem, undoMap) = freezeClauseVars "skc_" taken c
      fromSubDag <- buildFromSubDag translateFn unitMap tstp2name debug cname c cSkolem undoMap
      maybe (buildWithTwee unitMap tstp2name cname c cSkolem undoMap) (return . Just) fromSubDag

-- The candidate's own derivation as a refutation, so no prover is needed.
-- The sub-problem is its ancestors, the candidate, the Skolemized body atoms
-- as assumptions and the Skolemized negated head. The candidate resolves with
-- each assumption in turn and then with the negated head to $false.
buildFromSubDag
  :: (Map.Map String String -> Bool -> T.TSTP -> IO (Either String StructuredProof))
  -> Map.Map String T.Unit
  -> Map.Map String String
  -> Bool
  -> String -> Clause -> Clause -> [(String, Term)]
  -> IO (Maybe BuiltLemma)
buildFromSubDag translateFn unitMap tstp2name debug cname c cSkolem@(Clause bodySk _) undoMap = do
  let ancNames  = ancestorNamesOf unitMap cname
      -- the units the sub-problem adds get names apart from its own, also
      -- once sanitized
      own       = Set.insert cname ancNames
      ids       = Set.union own (Set.map sanitizeId own)
      newName   = underscoreApart (`Set.member` ids)
      negName   = newName "negconj"
      botName   = newName "lemma_bot"
      hypNames  = [ newName ("assumption_" ++ show i) | i <- [1 .. length bodySk] ]
      stepNames = [ newName ("lemma_step_" ++ show i) | i <- [1 .. length bodySk] ]
      headSk    = clauseHead cSkolem
      -- The outer conjecture is left out, or the sub-run would take the
      -- outer goal for its own. Negated conjecture clauses stay, since
      -- they carry the hypotheses the conjecture grants, and as they cite
      -- the conjecture they are inputs of the sub-problem.
      kept      = [ u | aname <- Set.toList ancNames, Just u@(T.Unit _ d _) <- [Map.lookup aname unitMap]
                      , not (isConjectureDecl d) ]
      keptNames = Set.fromList [ unitNameStr n | T.Unit n _ _ <- kept ]
      ancUnits  = [ if all (`Set.member` keptNames) (unitParents u) then u else makeFileSourced u | u <- kept ]
      unitLines = map (show . pretty) (ancUnits ++ maybeToList (Map.lookup cname unitMap))
      hypLines  = [ "cnf(" ++ h ++ ", axiom, " ++ tptpLiteral b ++ ")." | (h, b) <- zip hypNames bodySk ]
      -- the candidate with its first i body atoms resolved away
      stepLines = [ "cnf(" ++ s ++ ", plain, " ++ tptpClause (Clause (drop i bodySk) (Just headSk))
                    ++ ", inference(resolution,[status(thm)],[" ++ prev ++ ", " ++ h ++ "]))."
                  | (i, s, prev, h) <- zip4 [1 ..] stepNames (cname : stepNames) hypNames ]
      negLine   = "cnf(" ++ negName ++ ", negated_conjecture, " ++ tptpLiteral (negLit headSk) ++ ")."
      botLine   = "cnf(" ++ botName ++ ", plain, $false, inference(resolution,[status(thm)],["
                  ++ last (cname : stepNames) ++ ", " ++ negName ++ "]))."
      content   = unlines (unitLines ++ hypLines ++ stepLines ++ [negLine, botLine])
      -- E keeps several clausified copies of an axiom, and an ancestor
      -- may be one the outer proof did not name. It takes the outer name
      -- of its source, or the sub-run would number it afresh.
      bySource  = Map.fromList [ (resolveCopySource unitMap k, dn) | (k, dn) <- Map.toList tstp2name ]
      copyOverride = Map.fromList
        [ (aname, dn)
        | aname <- Set.toList ancNames
        , not (Map.member aname tstp2name)
        , Just dn <- [Map.lookup (resolveCopySource unitMap aname) bySource] ]
      -- the negation is the sub-run's goal, not an axiom, so it gets no
      -- name, and the body atoms are cited as assumptions
      nameOverride = Map.unions [ Map.singleton negName "", Map.fromList [ (h, assumptionName) | h <- hypNames ]
                                , tstp2name, copyOverride ]
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
        Right sp -> return (liftSubProof nameOverride cname c undoMap sp)

-- Turns the recursive translation of a candidate into an outer lemma. The goal
-- block becomes its proof, and the sub-lemmas are renamed apart and
-- de-Skolemized with it. The proof must end on the candidate's head. A
-- sub-lemma must not assume the candidate's body atoms, since the format has
-- no lemma local to another's proof, and stated alone it would drop them.
liftSubProof :: Map.Map String String -> String -> Clause -> [(String, Term)]
             -> StructuredProof -> Maybe BuiltLemma
liftSubProof nameOverride cname c undoMap sp = do
  (_, goalBlk) <- listToMaybe (goals sp)
  lit <- hd c
  let subLemmas = lemmas sp
      newName n = "lemma " ++ cname ++ "/" ++ n
      renaming  = Map.fromList [ (n, newName n) | (n, _, _) <- subLemmas ]
      lift blk  = deSkolemizeBlock undoMap (renameRefsBlock (\nm -> Map.findWithDefault nm nm renaming) blk)
      deSkolemize l = mapClauseLits (applyConstSubstLit undoMap . renameLit (apartFrom undoMap (concatMap litVars (clauseLits l)))) l
      lifted    = [ (newName n, deSkolemize l, lift b) | (n, l, b) <- subLemmas ]
      blk'      = lift goalBlk
      -- Axiom names taken from the outer proof. The sub-run numbered the
      -- others itself.
      outerNames = Set.fromList (filter (not . null) (Map.elems nameOverride))
      ownAxioms = [ a | a <- axioms sp, axiomName a `Set.notMember` outerNames ]
  guard (not (isEmptyBlock blk') && blockConcludes lit blk')
  guard (assumptionName `notElem` concat [ blockRefNames b | (_, _, b) <- subLemmas ])
  return (c, blk', lifted, ownAxioms)

-- The fallback for an equation whose ancestor axioms are all unit equations.
-- Twee is asked for a chain from them.
buildWithTwee
  :: Map.Map String T.Unit
  -> Map.Map String String
  -> String -> Clause -> Clause -> [(String, Term)]
  -> IO (Maybe BuiltLemma)
buildWithTwee unitMap tstp2name cname c cSkolem undoMap = case cSkolem of
  Clause [] (Just (Eq l r)) | Just units <- mapM unitEquationOf origAncestors -> do
    mChain <- callTwee InternalBudget units (Eq l r)
    return $ case mChain of
      Just (start, chain)
        | not (null chain), all (\(ue, _, _) -> isJust (ueName ue)) chain ->
            -- a chain from r to l is reversed, so the lemma states the
            -- candidate as the proof cites it
            let chain' = if start == l then chain else reverseChain start chain
                steps = [ (RwStep nm (unitEquation (ueUnit ue)) dir, cur)
                        | (ue, dir, cur) <- chain', Just nm <- [ueName ue] ]
            in Just (c, deSkolemizeBlock undoMap (EqChain l steps), [], [])
      _ -> Nothing
  _ -> return Nothing
  where
    granted = maybe [] (uncurry (++)) (conjectureHypotheses (Map.elems unitMap))
    dispNameOf aname = Map.lookup (resolveCopySource unitMap aname) tstp2name <|> Map.lookup aname tstp2name
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
        || (not (isDerivedUnit u) && classifyRole granted unitMap aname adecl == OrigAxiom && named)
        || (isFileUnit unitMap copySrc && maybe False hasAxiomRole (lookupDecl unitMap copySrc) && named)
      where
        named = isJust (dispNameOf aname)
        copySrc = resolveCopySource unitMap aname
    unitEquationOf (aname, adecl)
      | isPositiveUnitFormula adecl
      , Just eq@(Eq _ _) <- convertLit <$> headLitOf adecl
      = Just (UnitEntry (dispNameOf aname) eq Nothing Nothing)
      | otherwise = Nothing

-- A clause as a TPTP disjunction, its body atoms negated.
tptpClause :: Clause -> String
tptpClause (Clause bs mh) =
  "(" ++ intercalate " | " (map (tptpLiteral . negLit) bs ++ maybe [] (pure . tptpLiteral) mh) ++ ")"

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
  snd <$> mapAccumM buildOne [] cands
  where
    -- the proof's symbols, gathered once, as huge terms make this slow
    taken = Set.toList (Set.fromList (concat [ fs ++ ps | T.Unit _ d _ <- Map.elems unitMap, let (fs, ps) = declSymbols d ]))
    buildOne done c = do
      let unitMapC = foldr (Map.adjust lemmaInput) unitMap done
          namesC   = foldr (\c' -> Map.insert c' ("lemma " ++ c')) tstp2name done
      v <- buildCandidateLemma translateFn taken unitMapC namesC debug c
      return (if isJust v then done ++ [fst c] else done, v)

-- The pre-built lemmas in the order the proof tree reaches them, given as
-- (TSTP name, display name). Each follows the lemmas it cites, which the tree
-- may not reach itself, and its own sub-lemmas.
orderPrebuiltLemmas :: Map.Map String BuiltLemma -> [(String, String)] -> [(String, Clause, ProofBlock)]
orderPrebuiltLemmas built reached = snd (foldl emit (Set.empty, []) reached)
  where
    emit (seen, acc) (c, nm)
      | Set.member c seen = (seen, acc)
      | Just (stmt, blk, lifted, _) <- Map.lookup c built =
          let cited = [ c' | ref <- concatMap blockRefNames (blk : [ b | (_, _, b) <- lifted ])
                           , Just c' <- [stripPrefix "lemma " ref]
                           , c' /= c, Map.member c' built ]
              (seen', acc') = foldl emit (Set.insert c seen, acc) [ (c', "lemma " ++ c') | c' <- cited ]
          in (seen', acc' ++ lifted ++ [(nm, stmt, blk)])
      | otherwise = (seen, acc)
