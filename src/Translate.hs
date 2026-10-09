-- Algorithm 1 of the paper, which turns a refutation into a structured
-- direct proof. It builds the lemmas, names the axioms, translates the proof
-- tree nucleus by nucleus, proves the goals and runs the finishing passes
-- over the result.
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TupleSections #-}
module Translate (translate) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, forM, forM_, unless, void, when)
import Data.Bifunctor (bimap, first, second)
import Control.Exception (evaluate)
import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Control.Monad.State
import Data.Either (isRight)
import Data.List (find, inits, intercalate, mapAccumL, nub, partition, sortBy, isSuffixOf, tails)
import Data.Maybe (fromMaybe, isJust, isNothing, listToMaybe, mapMaybe)
import Data.Ord (Down(..), comparing)
import Data.Tuple (swap)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.TPTP as T
import Data.IORef (IORef, modifyIORef', newIORef, readIORef)
import System.CPUTime (getCPUTime)
import System.IO (hPutStrLn, stderr)

import Types
import Helpers
import PropRes (expandPropRes)
import Conjecture (concludesNegation, conjectureHypotheses, expandSimplifiedConjecture)
import ProofTree (buildProofInfo, equationSteps, findRoot, inlineAtomCongruences, reachedNames, resolveCopySource)
import TptpConvert
import TweeInterface
import StepReader
import LemmaBuilder
import Theta (ThetaCtx (..), thetaContext, computeNucleusTheta, resolutionCoherent, derivedHead, literalRewrites, headRewrites)
import Debug (dbg)

-- Entry point for the recursive translation of a lemma candidate. Names in
-- the override map are used as given, so the sub-proof cites the outer
-- proof's axioms.
translateWith :: Map.Map String String -> Bool -> T.TSTP -> IO (Either String StructuredProof)
translateWith nameOverride debug (T.TSTP _ units) = case buildProofInfo True units of
  Left reason    -> return (Left reason)
  Right origInfo -> translateTree debug origInfo units Map.empty nameOverride Nothing

-- Translates a refutation into a structured proof, or gives the reason it
-- cannot. A typed proof is translated without sorts and keeps its typed units
-- for the TPTP output.
translate :: Bool -> T.TSTP -> IO (Either String StructuredProof)
translate debug tstp@(T.TSTP _ units) =
  fmap withTypes <$> translateUntyped debug (eraseSorts tstp)
  where
    -- a typed proof keeps its units as read, so the TPTP output is typed too
    withTypes sp
      | null [ () | T.Unit _ (T.Typing _ _) _ <- units ] = sp
      | otherwise = sp { spInput = (spInput sp) { inTyped = units } }

-- Runs the translation under a fresh Twee budget. A failure says why, and
-- whether the budget ran out.
translateUntyped :: Bool -> T.TSTP -> IO (Either String StructuredProof)
translateUntyped debug tstp = do
  fallbackSecs <- startFallbackBudget
  tStage <- getCPUTime
  when debug $ hPutStrLn stderr ("[time] start cpu=" ++ show (tStage `div` 1000000000) ++ " ms")
  -- an exception means no proof, and its first line is the reason
  res <- trySync (translateWithLemmas debug tstp) >>= \case
    Right r -> return r
    Left e  -> do
      when debug $ hPutStrLn stderr ("translate: failed with: " ++ show e)
      return (Left (takeWhile (/= '\n') (show e)))
  -- a failure states its reason, so it is clear without --debug
  spent <- fallbackBudgetSpent
  let budget = if spent then "; the fallback budget of " ++ show fallbackSecs ++ " s for Twee calls is spent" else ""
  return (first (\reason -> "translation failed" ++ budget ++ "; " ++ reason) res)

-- The translation with lemmas. Every derived unit used at least twice, other
-- than an axiom or its copy, is translated on its own and becomes a leaf
-- named "lemma <tstp-name>". Then the main tree is translated and finished.
-- All share one axiom numbering, so an axiom used only in a lemma is listed.
-- The numbering needs each clause once, so the tree with every use of a
-- clause is built only after the lemmas cut it down.
translateWithLemmas :: Bool -> T.TSTP -> IO (Either String StructuredProof)
translateWithLemmas debug (T.TSTP _ units0) = do
  let units = expandPropRes (expandSimplifiedConjecture (inlineAtomCongruences (map dedupLiterals units0)))
  case buildProofInfo False units of
    Left reason -> return (Left reason)
    Right origInfo -> do
      let unitMap0 = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- units]
          origLeaves = piElectrons origInfo ++ piNuclei origInfo
          (origAxioms, origPosToName, _) =
            assignAxiomNames Map.empty negationConj (map convertLit (piGoalLits origInfo)) (piElectrons origInfo) (piNuclei origInfo) unitMap0
          negationConj = concludesNegation units
          -- A display name belongs to a clause, not to its source unit, so a
          -- unit that clausifies to several axioms gets one key per clause.
          -- The unit's own name is kept only when it has one display name, or
          -- a step could cite the wrong axiom (MGT001+1).
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
          -- Axioms and hypotheses, and the units that copy them, are stated,
          -- not proved, so they are no lemma candidates. As a lemma, a
          -- hypothesis would be proved by a step citing itself (LCL888+1/E).
          candidates = filter (\(cname, _) ->
                          resolveCopySource unitMap0 cname `Set.notMember` origAxiomNames
                          && cname `Set.notMember` origAxiomNames)
                        (findLemmaCandidates units)
      candResults <- buildAllCandidates translateWith unitMap0 origTstp2name debug candidates
      let builtCands =
            [ (cname, r) | ((cname, _), Just r) <- zip candidates candResults ]
          -- A sub-proof may cite file axioms the outer proof never used,
          -- numbered in its own run. They get outer numbers here, reusing
          -- the number of an axiom with the same statement, and the
          -- sub-proof's citations are renamed to match.
          origNames = Set.fromList (map axiomName origAxioms)
          mergeCand accA (cname, (l, blk, lifted, own)) =
            let (accA', ren) = foldl addOne (accA, Map.empty) own
                addOne (as, m) a =
                  case find (sameAxiomStatement a) (origAxioms ++ as) of
                    Just existing ->
                      (as, Map.insert (axiomName a) (axiomName existing) m)
                    Nothing ->
                      let nm = nextOuterName (origAxioms ++ as)
                      in (as ++ [renameAxiom nm a], Map.insert (axiomName a) nm m)
                rn n    = Map.findWithDefault n n ren
                lifted' = [ (n, ll, renameRefsBlock rn bb) | (n, ll, bb) <- lifted ]
            in (accA', (cname, (l, renameRefsBlock rn blk, lifted', [])))
          nextOuterName as =
            head (freeAxiomNames (\nm -> Set.member nm origNames || nm `elem` map axiomName as))
          (extraAxioms, mergedCands) = mapAccumL mergeCand [] builtCands
          validCands   = Map.fromList mergedCands
          allAxioms    = origAxioms ++ extraAxioms
          candOverride = Map.fromList [ (c, "lemma " ++ c) | c <- Map.keys validCands ]
          nameOverride = Map.union candOverride origTstp2name
          modUnits = map replace units
          replace u@(T.Unit n _ _) | Map.member (unitNameStr n) validCands = makeFileSourced u
          replace u = u
          -- the leaves of one kind that have a display name
          namedLeaves p = [ (nm, e) | e <- origLeaves, p e, Just nm <- [Map.lookup (lePos e) origPosToName] ]
          isAxiom e = leRole e == OrigAxiom
          -- the input problem behind the axioms, hypotheses and goals, which
          -- the finishing passes and the TPTP output read
          input = ProofInput
            { inAxiomUnits = Map.fromList
                [ (nm, u) | (nm, e) <- namedLeaves isAxiom, Just u <- [Map.lookup (leName e) unitMap0] ]
            , inAxiomLeaves = Map.fromList [ (nm, leUnit e) | (nm, e) <- namedLeaves isAxiom ]
            , inGeneralized = []
            , inHypotheses = Map.fromList [ (nm, leUnit e) | (nm, e) <- namedLeaves leHyp ]
            , inConjecture = listToMaybe
                [ u | u@(T.Unit _ (T.Formula (T.Standard T.Conjecture) _) _) <- units ]
            , inUnits = units
            , inTyped = []
            , inNegated = negatedHyps
            }
          -- the hypotheses that come from the negated conclusion
          negatedHyps = case conjectureHypotheses units of
            Just (_, cons) | not (null cons) ->
              [ nm | (nm, e) <- namedLeaves leHyp
                   , Just c <- [convertDeclToClause (leDecl e)]
                   , any (`clauseInstance` c) cons ]
            _ -> []
          -- the tree translated against the input problem and finished
          finish info us cands names axs =
            translateTree debug info us cands names (Just axs) >>= traverse (\sp -> evaluate (finalize (sp { spInput = input })))
          -- Every hypothesis the proof uses must be granted by the
          -- conjecture, or the proof would assume more than the conjecture
          -- gives. A positive clause from a negative position, as
          -- ? [Y] : ! [X] : (p(Y) => p(X)) yields, makes the refutation a
          -- case split, which no Horn proof shows.
          ungranted =
            [ if null (body c)
                then "its negation yields the positive clause " ++ leUnit e ++ " from a negative position, so its proof is a case split"
                else "its negation yields the clause " ++ leUnit e ++ ", which the conjecture does not grant"
            | Just (ante, cons) <- [conjectureHypotheses units]
            , e <- origLeaves, leHyp e
            , Just c <- [convertDeclToClause (leDecl e)]
            , not (any (`clauseInstance` c) (ante ++ cons)) ]
      case ungranted of
        why : _ -> return (Left ("unsupported conjecture, " ++ why))
        [] | Map.null validCands -> either (return . Left) (\info -> finish info units Map.empty origTstp2name origAxioms)
                                             (buildProofInfo True units)
           | otherwise -> case buildProofInfo True modUnits of
               Right mainInfo -> finish mainInfo modUnits validCands nameOverride allAxioms
               Left reason -> return (Left ("the proof with its lemmas as inputs is no refutation, " ++ reason))

-- The finishing passes over the translated proof, run right to left. Unused
-- lemmas are dropped early, so they are neither generalized nor checked.
finalize :: StructuredProof -> StructuredProof
finalize = checkBlockEnds . checkChains . cutChainLoops . generalizeGoals . cutDetours . skolemWitnesses
         . dropUnusedLemmas . falsumGoalForNegation

-- A conjecture concluding a negation is proved by deriving $false from the
-- negated formula, so that derivation is the only goal.
falsumGoalForNegation :: StructuredProof -> StructuredProof
falsumGoalForNegation sp
  | null (inNegated (spInput sp)) = sp
  | otherwise = case [ b | (l, b) <- goals sp, l == falsumLit ] of
      b : _ -> sp { goals = [(falsumLit, b)] }
      []    | null (goals sp) -> sp
            | otherwise       -> error "the derivation of $false from the negated conclusion is not shown"

-- Every lemma and goal block ends on its own statement, up to orientation, so
-- the outputs print each as proved. A chain for an atom ends in true.
checkBlockEnds :: StructuredProof -> StructuredProof
checkBlockEnds sp = case [ n | (n, l, b) <- blocks, not (endsOn l b) ] of
    []    -> sp
    n : _ -> error ("the proof of " ++ n ++ " does not end on its statement")
  where
    blocks = lemmas sp ++ [ (ppLiteral l, l, b) | (l, b) <- goals sp ]
    endsOn l (HaveHence ls@(_ : _)) = lineLit (last ls) `elem` [l, flipLit l]
    endsOn l (EqChain s steps)
      | isRelLit l, (_, Const "true") : _ <- reverse steps = s == atomTerm l
      | otherwise = Eq s (if null steps then s else snd (last steps)) `elem` [l, flipLit l]
    endsOn _ _ = False

-- Every printed rewrite, in a chain or a hence line, must follow from the
-- equation it cites in the direction it cites. A lemma can state a stored
-- instance while the step used the general clause (GRP658+1, f295). Only
-- unit equations are checked here, other citations are left to the checkers.
checkChains :: StructuredProof -> StructuredProof
checkChains sp = case [ (n, nm, shown) | (n, blk) <- blocks, (nm, shown) <- take 1 (unjustified blk) ] of
    []                 -> sp
    (n, nm, shown) : _ ->
      error ("the chain of " ++ n ++ " has a step by " ++ nm
             ++ " that the statement of " ++ nm ++ " does not make: "
             ++ shown ++ " by " ++ maybe "?" (ppLiteral . uncurry Eq) (Map.lookup nm stated))
  where
    blocks = [ (n, b) | (n, _, b) <- lemmas sp ]
          ++ [ ("goal " ++ show i, b) | (i, (_, b)) <- zip [1 :: Int ..] (goals sp) ]
    stated = Map.fromList $
      [ (n, (a, b)) | AUnit n (Eq a b) <- axioms sp ]
      ++ [ (n, (a, b)) | (n, Eq a b, _) <- lemmas sp ]
    unjustified (EqChain start steps) =
      [ (rwName rw, ppLiteral (Eq prev cur))
      | ((rw, cur), prev) <- zip steps (start : map snd steps)
      , Just eq <- [Map.lookup (rwName rw) stated]
      , not (chainStepJustified (rwDir rw) eq prev cur) ]
    -- a hence line rewrites the last have or hence line before it
    unjustified (HaveHence ls) =
      [ (nm, ppLiteral prev ++ " to " ++ ppLiteral cur)
      | (before, Hence cur (ByRw nm d)) <- zip (inits ls) ls
      , prev : _ <- [reverse [ l | ln <- before, Just l <- [stated' ln] ]]
      , Just eq <- [Map.lookup nm stated]
      , Just (x, y) <- [(,) <$> litAsTerm prev <*> litAsTerm cur]
      , not (chainStepJustified d eq x y) ]
    stated' (Have l _)  = Just l
    stated' (Hence l _) = Just l
    stated' (And _ _)   = Nothing

-- Cuts the loops of every equality chain. Once the blocks state variables in
-- place of Theorem 1's fresh constants, two terms of a chain may be equal, and
-- the steps between them derive nothing.
cutChainLoops :: StructuredProof -> StructuredProof
cutChainLoops sp = sp
  { lemmas = [ (n, l, cut b) | (n, l, b) <- lemmas sp ]
  , goals  = [ (l, cut b)    | (l, b)    <- goals sp ] }
  where
    cut (EqChain start steps) = EqChain start (cutLoops snd start steps)
    cut b                     = b

-- The input proof may rewrite a fact and later rewrite it back. Rewrite
-- lines that lead from a fact back to itself derive nothing and are dropped.
cutDetours :: StructuredProof -> StructuredProof
cutDetours sp = sp { lemmas = [ (n, l, cut b) | (n, l, b) <- lemmas sp ]
                   , goals  = [ (l, cut b) | (l, b) <- goals sp ] }
  where
    cut (HaveHence ls) = HaveHence (go ls)
    cut b              = b
    go [] = []
    go (l : rest) = case detour (lineLit l) rest of
      Just rest' -> go (l : rest')
      Nothing    -> l : go rest
    -- the lines after the last rewrite that restates the fact
    detour lit rest = listToMaybe
      [ drop n rest | (n, rw) <- reverse (zip [1 ..] (takeWhile isRw rest)), lineLit rw == lit ]
    isRw (Hence _ (ByRw _ _)) = True
    isRw _                    = False

-- The symbols the problem states, in its input units and its axioms.
problemSymbols :: StructuredProof -> Set.Set String
problemSymbols sp = Set.fromList $
  concatMap (concatMap litSymbols . axiomLits) (axioms sp)
  ++ concat [ fs ++ ps | u@(T.Unit _ d _) <- inUnits (spInput sp), isFileSourced u
                       , let (fs, ps) = declSymbols d ]

-- A Skolem term f(W) of the negated conjecture cannot become a variable when
-- the proof rewrites inside W (GRP658+1/Vampire). So every term headed by f
-- is read as one variable, and a W that mentions f is replaced by one free of
-- f that a lemma proves equal to W.
skolemWitnesses :: StructuredProof -> StructuredProof
skolemWitnesses sp0 = foldl liftSymbol sp0 skolemFunctions
  where
    -- the symbols the problem, the axioms and the lemmas state
    stated = Set.unions (problemSymbols sp0 : [ Set.fromList (litSymbols l ++ concatMap termSymbols (blockTerms b))
                                              | (_, l, b) <- lemmas sp0 ])
    skolemFunctions = nub
      [ f | (l, _) <- goals sp0, t <- foldLiteralTerms subterms l
          , App f (_ : _) <- [t], Set.notMember f stated ]

    liftSymbol sp f
      | all (`elem` goalTerms) proofTerms = sp      -- nothing is rewritten below f
      | [App _ ws] <- skolemTerms
      , Just found <- mapM witness (zip [0 ..] ws) =
          let needed  = [ (w, ("lemma " ++ f ++ " witness " ++ show i, u, path))
                        | (i, w, Just (u, path)) <- zip3 [(0 :: Int) ..] ws found ]
              chosen  = [ maybe w fst m | (w, m) <- zip ws found ]
              newLemmas = [ (n, Eq (erase w) u, EqChain (erase w) path) | (w, (n, u, path)) <- needed ]
          in sp { lemmas  = lemmas sp ++ newLemmas
                , goals   = [ restate needed l b | (l, b) <- goals sp ]
                , spInput = (spInput sp) { inGeneralized = inGeneralized (spInput sp) ++ [(yName, App f chosen)] } }
      | otherwise = sp
      where
        yName = "Sk_" ++ f
        y     = Var yName
        headed t = case t of { App g _ -> g == f; _ -> False }
        -- the outermost terms headed by f
        outer t | headed t          = [t]
                | App _ ts <- t     = concatMap outer ts
                | otherwise         = []
        -- every term headed by f read as the one variable
        erase t | headed t      = y
                | App g ts <- t = App g (map erase ts)
                | otherwise     = t
        mentions t = not (null (outer t))
        goalTerms  = nub (concat [ foldLiteralTerms outer l | (l, _) <- goals sp ])
        proofTerms = nub (concat [ concatMap outer (blockShownTerms b) | (_, b) <- goals sp ])
        -- the Skolem term whose generalization leaves the goals free of f
        skolemTerms =
          [ t | t@(App _ ws) <- goalTerms
              , all (\(l, _) -> not (any mentions (foldLiteralTerms (: []) (mapLiteralTerms (generalize t ws) l)))) (goals sp) ]
        generalize t ws u
          | u == t        = y
          | u `elem` ws   = Var "\0witness"
          | App g ts <- u = App g (map (generalize t ws) ts)
          | otherwise     = u
        -- the equations between f's arguments that goal chain steps inside f
        -- make, per argument place and in both directions
        edges = concat
          [ [ (i, erase a, erase b, rw'), (i, erase b, erase a, rw' { rwDir = flipDir (rwDir rw) }) ]
          | (_, EqChain s steps) <- goals sp
          , (prev, (rw, cur)) <- zip (s : map snd steps) steps
          , (i, a, b) <- inside prev cur
          , erase a /= erase b
          , let rw' = rw { rwEq = bimap erase erase (rwEq rw) } ]
        inside a b
          | a == b = []
          | App g as <- a, App h bs <- b, g == h, length as == length bs =
              if g == f then [ (i, x, x') | (i, (x, x')) <- zip [(0 :: Int) ..] (zip as bs), x /= x' ]
                        else concat (zipWith inside as bs)
          | otherwise = []
        -- a witness free of f stays, and any other is searched breadth first
        -- along those equations for one free of f
        witness (i, w)
          | not (mentions w) = Just Nothing
          | otherwise        = Just <$> search [(erase w, [])] [erase w]
          where
            search [] _ = Nothing
            search ((t, path) : queue) seen
              | yName `notElem` termVars t = Just (t, reverse path)
              | otherwise =
                  let next = [ (b, (rw, b) : path) | (j, a, b, rw) <- edges, j == i, a == t, b `notElem` seen ]
                  in search (queue ++ next) (seen ++ map fst next)
        -- The goal at the chosen witnesses. A chain rewrites each witness
        -- occurrence to the one the proof used, follows the proof, and
        -- rewrites back.
        restate needed lit blk = (mapLiteralTerms chosenTerm lit, case blk of
          EqChain s steps ->
            let core   = [ (rw { rwEq = bimap erase erase (rwEq rw) }, erase t)
                         | (prev, (rw, t)) <- zip (s : map snd steps) steps, erase prev /= erase t ]
                final  = if null steps then s else snd (last steps)
                into   = [ (RwStep n (erase w, u) RL, t) | (n, w, u, t) <- drop 1 (stages s) ]
                back   = [ (RwStep n (erase w, u) LR, t)
                         | ((_, _, _, t), (n, w, u, _)) <- reverse (zip (stages final) (drop 1 (stages final))) ]
            in EqChain (chosenTerm s) (into ++ core ++ back)
          HaveHence ls ->
            -- a rewrite inside f now repeats its line, which cutDetours drops
            let erased = map (mapLineLit (mapLiteralTerms erase)) ls
                lastLit = lineLit (last ls)
                back = [ Hence l (ByRw n LR)
                       | ((_, l), (n, _)) <- reverse (zip (litStages lastLit) (drop 1 (litStages lastLit))) ]
            in HaveHence (erased ++ (if null ls then [] else back)))
          where
            occurrence t = lookup t [ (w, (n, u)) | (w, (n, u, _)) <- needed ]
            -- the term with its first k witness occurrences as the proof used
            -- them and the rest as chosen
            render k = snd . go (0 :: Int)
              where
                go c u
                  | headed u = (c, y)
                  | Just (_, chosenU) <- occurrence u = (c + 1, if c < k then erase u else chosenU)
                  | App g ts <- u = second (App g) (mapAccumL go c ts)
                  | otherwise = (c, u)
            chosenTerm = render 0
            -- the witness occurrences, each with its lemma and both sides
            occurrences u
              | headed u = []
              | Just (n, chosenU) <- occurrence u = [(n, u, chosenU)]
              | App _ ts <- u = concatMap occurrences ts
              | otherwise = []
            -- stage k has the first k occurrences as the proof used them, and
            -- the lemma of occurrence k - 1 links it to stage k - 1
            stages t = [ (n, w, u, render k t) | (k, (n, w, u)) <- zip [0 ..] (("", t, t) : occurrences t) ]
            litStages l = case l of
              Eq a b   -> [ (n, case args t of { [s, u] -> Eq s u; _ -> Eq t t }) | (n, _, _, t) <- stages (App "\0eq" [a, b]) ]
              Rel p ts -> [ (n, Rel p (args t)) | (n, _, _, t) <- stages (App "\0rel" ts) ]
              _        -> [("", l)]
            args t = case t of { App _ ts -> ts; _ -> [] }

-- Skolem terms of the negated conjecture stand for universal variables, so
-- they become variables again in the goals and lemmas. One variable stands
-- for one term, so a symbol stays when a lemma applies it to other arguments
-- than the goals do. Symbols of hypotheses stay too.
generalizeGoals :: StructuredProof -> StructuredProof
generalizeGoals sp
  | null fresh = sp
  | otherwise  = sp { lemmas = [ (n, applyTermSubstLit sub l, applyTermSubstBlock sub b) | (n, l, b) <- lemmas sp ]
                    , goals  = [ (applyTermSubstLit sub l, applyTermSubstBlock sub b) | (l, b) <- goals sp ]
                    , spInput = (spInput sp) { inGeneralized = inGeneralized (spInput sp) ++ [ (v, t) | (t, Var v) <- sub ] } }
  where
    -- hypotheses are listed as axioms, so their symbols are among these
    stated = problemSymbols sp
    used   = Set.union stated (Set.fromList
               [ f | t <- skolemTerms stated lemmaTerms, t `notElem` goalSkolems, f <- take 1 (termSymbols t) ])
    goalSkolems = skolemTerms stated goalTerms
    goalTerms  = [ t | (l, _) <- goals sp, t <- foldLiteralTerms (: []) l ]
    lemmaTerms = concat [ foldLiteralTerms (: []) l ++ blockTerms b | (_, l, b) <- lemmas sp ]
    -- the maximal subterms headed by a symbol not among those given
    skolemTerms known = concatMap maximal
      where
        maximal t | skolemHeaded t = [t]
                  | App _ ts <- t  = concatMap maximal ts
                  | otherwise      = []
        skolemHeaded t = case t of
          Const c -> Set.notMember c known
          App f _ -> Set.notMember f known
          _       -> False
    fresh = nub (skolemTerms used goalTerms)
    sub   = [ (t, Var (name i t)) | (i, t) <- zip [1 :: Int ..] fresh ]
    name _ (Const c)  = "Sk_" ++ c
    name i (App f _)  = "Sk_" ++ f ++ "_" ++ show i
    name i _          = "Sk_" ++ show i

-- The translation monad. A step that cannot be justified fails with
-- throwError, and the caller tries another route. The state survives the
-- failure, so facts found so far stay. error aborts the translation run.
type AlgM a = ExceptT String (StateT AlgState IO) a

-- The unit table holds each fact once, since duplicates multiply the
-- branching of later searches. Theorem 1's fresh constants are rigid only
-- while their nucleus is justified, and the fact holds for every value of
-- them, so it is stored with variables again.
addUnit :: UnitEntry -> AlgM ()
addUnit ue0 = modify $ \s ->
  let ue = ue0 { ueUnit = unrigidLit (ueUnit ue0)
               , ueProof = fmap unrigidBlock (ueProof ue0) }
      same u = ueName u == ueName ue && isJust (ueProof u) == isJust (ueProof ue)
               && variantLit (ueUnit u) (ueUnit ue)
  in if any same (stUnits s) then s else s { stUnits = stUnits s ++ [ue] }

-- Runs a step and returns its failure instead of propagating it. State
-- changes made before the failure are kept.
attempt :: AlgM a -> AlgM (Either String a)
attempt = lift . runExceptT

-- get_proof, the prover find_elec and the goal proofs fall back on. It
-- returns a rewrite chain from the units. The first pass, which only reads
-- the input proof, uses noProver.
newtype Prover = Prover
  { chainBy :: TweeBudget -> [UnitEntry] -> Literal -> IO (Maybe (Term, [(UnitEntry, Dir, Term)])) }

-- The prover backed by Twee, and the one that never finds a chain.
tweeProver, noProver :: Prover
tweeProver = Prover callTwee
noProver   = Prover (\_ _ _ -> return Nothing)

-- A search step that restores the state when it finds nothing.
orRestore :: AlgM (Maybe a) -> AlgM (Maybe a)
orRestore act = do
  saved <- get
  r <- act
  when (isNothing r) (put saved)
  return r

-- Elecs of Algorithm 1 for the nucleus at pos. The unnamed units at a
-- position before pos, or at none, come first, then the named ones.
getElectrons :: String -> AlgM [UnitEntry]
getElectrons pos = gets $ \s ->
  let allUnits = stUnits s
      named    = filter (isJust . ueName) allUnits
      unnamed  = filter (\u -> isNothing (ueName u) && maybe True (< pos) (uePos u)) allUnits
  in unnamed ++ named

-- The emitted goals renamed apart from each other and from the conjecture.
renameGoalsApart :: [Literal] -> [Literal]
renameGoalsApart gs = [ suffixVarsLit ("_g" ++ show i) g | (i, g) <- zip [1 :: Int ..] gs ]

-- A substitution extending σ under which each literal of the first list
-- unifies with one of the second.
unifyEach :: Subst -> [Literal] -> [Literal] -> Maybe Subst
unifyEach σ ls targets = unifyEachWith σ [ (l, targets) | l <- ls ]

-- A substitution extending σ under which each literal unifies with one of its
-- targets, tried in order. It backtracks, since a literal may unify with
-- several and only one choice may extend to the rest.
unifyEachWith :: Subst -> [(Literal, [Literal])] -> Maybe Subst
unifyEachWith σ [] = Just σ
unifyEachWith σ ((l, targets) : ls) =
  listToMaybe [ r | t <- targets, Just σ' <- [unifyLits l t σ], Just r <- [unifyEachWith σ' ls] ]

-- Records a goal, proved for the given conjunct, with its proof block. A goal
-- already emitted up to renaming is skipped, and one inconsistent with the
-- goals before it fails the step.
emitGoalProof :: Literal -> Literal -> ProofBlock -> AlgM ()
emitGoalProof conj lit blk = do
  -- A goal may keep variables theta never bound, since clause copies are
  -- renamed apart. Goal variables are existential, so the goal is emitted at
  -- the instance the block concludes.
  let lit' | not (null (litOpen lit))
           , Just c <- blockConcl blk
           , Just ρ <- matchLit lit c
           , any (\(_, t) -> case t of { Var _ -> False; _ -> True }) ρ = applySubstLit ρ lit
           | otherwise = lit
  dbgFlag <- gets stDebug
  liftIO $ dbg dbgFlag $ "[goal-emit] " ++ ppLiteral lit'
  template <- gets stGoalTemplate
  existing <- gets (map fst . stGoals)
  -- Several routes emit goals, and only this check stops two of them from
  -- grounding a shared goal variable differently (SYN602-1). An inconsistent
  -- goal is refused, so the search tries another derivation.
  axNuclei <- gets stAxNuclei
  -- a goal proved at a fresh constant holds for every value of it
  let litG = unrigidLit lit'
      blk' = orientToGoal axNuclei litG (unrigidBlock blk)
  -- a goal already emitted up to renaming is not emitted again, as when two
  -- clause copies reach the same instance (CSR117+1/E)
  unless (any (\e -> isJust (matchLit e litG) && isJust (matchLit litG e)) existing) $
    -- the template's variables are existential, so the goals unify with it
    if isJust (unifyEach [] (renameGoalsApart (existing ++ [litG])) (map (suffixVarsLit "_c") template))
      then modify $ \s -> s { stGoals = stGoals s ++ [(litG, blk')], stGoalFor = stGoalFor s ++ [conj] }
      else throwError ("emitGoalProof: " ++ ppLiteral litG ++ " is inconsistent with an already-proven goal")

-- A block that concludes the goal equation the other way round, as E prints
-- b = a for a = b, is turned to end on the goal, provided the cited axiom
-- derives that orientation from the same premises.
orientToGoal :: [(String, Clause)] -> Literal -> ProofBlock -> ProofBlock
orientToGoal axs goal@(Eq l r) blk@(HaveHence ls)
  | (Hence (Eq l' r') (ByAxiom nm) : older) <- reverse ls
  , l' == r, r' == l
  , Just (Clause bodyAbs (Just headAbs)) <- lookup nm axs
  -- the step's premises are the previous conclusion, if any, and the lines
  -- after it, in block order
  , let (after, before) = break (\case Hence {} -> True; _ -> False) older
        prems = take 1 (map lineLit before) ++ reverse (map lineLit after)
  , resolutionCoherent bodyAbs headAbs prems goal
  = HaveHence (init ls ++ [Hence goal (ByAxiom nm)])
  | otherwise = blk
orientToGoal _ _ blk = blk

-- The conclusion a proof block ends on.
blockConcl :: ProofBlock -> Maybe Literal
blockConcl (HaveHence ls)        = listToMaybe (reverse (map lineLit ls))
blockConcl (EqChain start steps) = listToMaybe [ Eq start t | (_, t) <- reverse steps ]

-- Makes a block a lemma with a fresh name "lemma N" and gives that name to the
-- unnamed unit that states it. Returns the name.
promoteToLemma :: Literal -> ProofBlock -> AlgM String
promoteToLemma lit blk
  | isEmptyBlock blk = error ("promoteToLemma: no proof for " ++ ppLiteral lit)
  -- Free head variables are universal. Every premise is an instance under
  -- the same bindings, so the block proves the lemma for all values.
  | otherwise = do
      -- a lemma candidate is named "lemma <tstp-name>" and TSTP names may
      -- be numbers, so a taken counter value is skipped
      taken <- gets (\s -> Set.fromList (map (\(n, _, _) -> n) (stLemmas s))
                          `Set.union` Set.fromList (mapMaybe ueName (stUnits s)))
      let freshName = do
            k <- gets stCounter
            modify $ \s -> s { stCounter = k + 1 }
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

-- The name a fact is cited by. A named unit keeps its name, a one-line block
-- gives the name it cites, and any other proof becomes a lemma. buildBlk
-- runs only when the table holds no proof. Fresh constants become variables,
-- as in the unit table.
ensureNamed :: Literal -> AlgM ProofBlock -> AlgM String
ensureNamed lit0 buildBlk0 = do
  let lit = unrigidLit lit0
  known <- gets (find (\u -> ueUnit u == lit) . stUnits)
  case known >>= ueName of
    Just nm -> return nm
    Nothing -> do
      blk <- maybe (unrigidBlock <$> buildBlk0) return (known >>= ueProof)
      case blk of
        HaveHence [Have _ nm] -> return nm
        _ -> do
          nm <- promoteToLemma lit blk
          when (isNothing known) (addUnit (UnitEntry (Just nm) lit Nothing Nothing))
          return nm

-- Matches electron ki onto body atom li, in either orientation of an
-- equation, giving σi. Under θ the body atom is ground up to fresh
-- constants, so only the electron's variables are bound.
matchElectron :: Literal -> Literal -> Maybe Subst
matchElectron li ki = matchLitEither ki li []

-- The citation of a chain step, by a unit that states its equation or a more
-- general one. A derived unit is named here, so no step cites an internal
-- name.
citeChainStep :: (RwStep, a) -> AlgM (RwStep, a)
citeChainStep (rw, c) = do
  units <- gets stUnits
  let eqLit = uncurry Eq (rwEq rw)
      -- a named unit stating this equation, either way round
      isVariant u = variantLit (ueUnit u) eqLit || variantLit (ueUnit u) (flipLit eqLit)
      named = listToMaybe [ u | u <- units, isVariant u, isJust (ueName u) ]
      -- a derived unit with a proof, either way round
      proved = listToMaybe [ u | u <- units, isVariant u, isJust (ueProof u) ]
      -- a unit more general than the instance the step applies
      general = listToMaybe [ u | u <- units, isJust (matchLitEither (ueUnit u) eqLit []), isCitable u ]
      -- the step's direction is read against the cited statement, and an
      -- unnamed unit is named here
      cite u = do
        nm <- maybe (ensureNamed (ueUnit u) (makeBlock u [] [])) return (ueName u)
        return $ if isJust (matchLit (ueUnit u) eqLit)
          then (rw { rwName = nm }, c)
          else (rw { rwName = nm, rwEq = swap (rwEq rw), rwDir = flipDir (rwDir rw) }, c)
  case named <|> proved <|> general of
    Just u  -> cite u
    Nothing -> do
      nameToPos <- gets stNameToPos
      case Map.lookup (rwName rw) nameToPos >>= \p -> find ((== Just p) . uePos) units of
        Nothing -> throwError ("rewrite step cites an unknown unit: " ++ rwName rw)
        -- The unit is stored as the instance the proof derived, while the
        -- step applied the prover's clause. Unless both state one equation,
        -- the lemma would be cited for a step it does not make (GRP658+1,
        -- f295). A variant here has no name, or named would have found it.
        Just u
          | isVariant u -> cite u
          | otherwise ->
              throwError ("rewrite step by " ++ rwName rw ++ " is stated as "
                          ++ ppLiteral (ueUnit u) ++ ", not as the equation it applied")

-- One chain step with its unit named.
nameChainStep :: (UnitEntry, Dir, a) -> AlgM (RwStep, a)
nameChainStep (stepUe, dir, cur) = do
  nm <- ensureNamed (ueUnit stepUe) (makeBlock stepUe [] [])
  return (RwStep nm (unitEquation (ueUnit stepUe)) dir, cur)

-- The chain for a positive unit, read from the input-proof step that derived
-- it as rewrites by the step's two premises (StepReader.stepRewrites). An
-- atom P is read as P = true. A failed reading restores the state, except
-- for the memo of unreadable steps.
readDerivingStep :: Literal -> AlgM (Maybe (Term, [(UnitEntry, Dir, Term)]))
readDerivingStep goal = case positiveUnit goal of
  Just (gl, gr) -> do
    steps <- gets stEquationSteps
    lits  <- gets stUnitLitByName
    let concludes nm = maybe False (\l -> isJust (matchLitEither l goal [])) (Map.lookup nm lits)
        readFrom c = do
          saved <- get
          r <- readStepChain c gl gr
          when (isNothing r) $ modify (\s -> saved { stUnreadSteps = stUnreadSteps s })
          return r
    firstJustM [ readFrom c | (c, _, _) <- steps, concludes c ]
  Nothing -> return Nothing

-- A positive unit as an equation, an atom P as P = true.
positiveUnit :: Literal -> Maybe (Term, Term)
positiveUnit l@(Eq _ _)  = Just (unitEquation l)
positiveUnit l@(Rel _ _) = Just (unitEquation l)
positiveUnit _           = Nothing

-- A premise of an equation step. It is a unit the table holds, read at some
-- instance, a unit another step derived, or an equation t = t, which holds
-- by reflexivity and rewrites nothing.
data Premise = Given UnitEntry Literal | ByStep String Literal | Trivial Literal

-- A premise's equation, an atom P read as P = true.
premiseEq :: Premise -> Maybe (Term, Term)
premiseEq p = positiveUnit (case p of { Given _ l -> l; ByStep _ l -> l; Trivial l -> l })

-- The readings of premise nm of an equation step. An equation t = t is
-- trivial. Otherwise it is read as the unit that states it, or else as the
-- step that derives it, or else as a more general unit at the printed
-- instance, and only when none exists as any unit that is an instance of it.
premiseReadings :: String -> AlgM [Premise]
premiseReadings nm = do
  lits  <- gets stUnitLitByName
  units <- gets (filter isCitable . stUnits)
  steps <- gets stEquationSteps
  return $ case Map.lookup nm lits of
    Nothing -> []
    Just e@(Eq a b) | a == b -> [Trivial e]
    Just e  ->
      let states f u = f (ueUnit u) e || f (ueUnit u) (flipLit e)
          -- a unit more general than the premise, when the algorithm leaves
          -- a head-only variable free where the proof prints an instance
          generalizes a b = isJust (matchLit a b)
          -- an instance of the premise, when the algorithm proves only
          -- instances under a lemma's Skolem constants, and the step's
          -- rewrites pick the one it uses
          instantiates a b = isJust (matchLit b a)
          given u = Given u (ueUnit u)
          -- the general unit read at the printed instance, in the unit's
          -- orientation, so the step reads as the prover made it
          atPrinted u = head [ Given u (applySubstLit σ (ueUnit u))
                             | x <- [e, flipLit e], Just σ <- [matchLit (ueUnit u) x] ]
      in case listToMaybe [ u | u <- units, states variantLit u ] of
           Just u  -> [given u]
           Nothing
             | any (\(c, _, _) -> c == nm) steps -> [ByStep nm e]
             | Just u <- listToMaybe [ u | u <- units, states generalizes u ] -> [atPrinted u]
             | otherwise -> [ given u | u <- units, states instantiates u ]

-- The chain from l to r through the two premises of the equation step c.
readStepChain :: String -> Term -> Term -> AlgM (Maybe (Term, [(UnitEntry, Dir, Term)]))
readStepChain c l r = do
  steps <- gets stEquationSteps
  case [ (p1, p2) | (c', p1, p2) <- steps, c' == c ] of
    ((p1, p2) : _) -> do
      qs1 <- premiseReadings p1
      qs2 <- premiseReadings p2
      let fits = [ (q1, q2, rws) | q1 <- qs1, q2 <- qs2
                                 , Just e1 <- [premiseEq q1], Just e2 <- [premiseEq q2]
                                 , Just rws <- [stepRewrites l r e1 e2] ]
      case fits of
        ((q1, q2, rws) : _) -> do
          -- each rewrite in the order the chain runs, from l to r
          let q i = if i == (1 :: Int) then q1 else q2
              go _ acc [] = return (Just acc)
              go from acc ((i, d, atRoot, inst, to) : rest) = do
                m <- premiseRewriteSteps (q i, d, atRoot, inst) from to
                case m of
                  Nothing -> return Nothing
                  Just st -> go to (acc ++ st) rest
          -- rewrites joined at their instances may go out and back
          fmap (\steps' -> (l, cutLoops (\(_, _, t) -> t) l steps')) <$> go l [] rws
        [] -> do
          dbgFlag <- gets stDebug
          let shown p qs = p ++ " " ++ intercalate " or " [ ppLiteral (uncurry Eq e) | Just e <- map premiseEq qs ]
          liftIO $ dbg dbgFlag ("[read] " ++ c ++ ": " ++ ppLiteral (Eq l r)
                                ++ " is not read from its premises " ++ shown p1 qs1 ++ ", " ++ shown p2 qs2)
          return Nothing
    [] -> return Nothing

-- A premise's own derivation, read once per step and equation and memoized
-- whether or not a chain was found.
readPremiseStep :: String -> (Term, Term) -> AlgM (Maybe (Term, [(UnitEntry, Dir, Term)]))
readPremiseStep nm e@(pl, pr) = do
  failed <- gets (Set.member (nm, e) . stUnreadSteps)
  done   <- gets (Map.lookup (nm, e) . stReadSteps)
  case (failed, done) of
    (True, _)       -> return Nothing
    (_, Just chain) -> return (Just chain)
    _ -> do
      r <- readStepChain nm pl pr
      modify (\st -> case r of
        Just chain -> st { stReadSteps = Map.insert (nm, e) chain (stReadSteps st) }
        Nothing    -> st { stUnreadSteps = Set.insert (nm, e) (stUnreadSteps st) })
      return r

-- The rewrite steps one premise makes from one term to the next. A derived
-- equation used only here at the root has its derivation spliced in, and any
-- other becomes a lemma, so the output keeps the input proof's sharing. The
-- derivation is read as stated, or else at the applied instance.
premiseRewriteSteps :: (Premise, Dir, Bool, (Term, Term)) -> Term -> Term -> AlgM (Maybe [(UnitEntry, Dir, Term)])
premiseRewriteSteps (Given u _, d, _, _) _ to = return (Just [(u, d, to)])
premiseRewriteSteps (Trivial _, _, _, _) _ _ = return (Just [])
premiseRewriteSteps (ByStep nm lit, d, atRoot, inst) from to = do
  preds <- gets stPredicates
  let e = unitEquation lit
      -- an equation between atoms is never a lemma, so it is spliced at
      -- the root and fails inside a term
      atomEq = isAtomEquation preds lit
      instLit = maybe lit (`applySubstLit` lit) (matchLit (uncurry Eq e) (uncurry Eq inst))
  -- a clause inside a nested inference is the premise of the next step only
  uses <- gets (Map.findWithDefault 1 nm . stPremiseUses)
  general <- readPremiseStep nm e
  sub <- case general of
    Just chain -> return (Just (lit, e, chain))
    Nothing
      | not (variantLit (uncurry Eq inst) (uncurry Eq e)) ->
          fmap (instLit, inst,) <$> readPremiseStep nm inst
      | otherwise -> return Nothing
  case sub of
    Nothing -> return Nothing
    Just (stated, e', chain@(start, steps))
      | atRoot && (uses == 1 || atomEq) -> return (instantiateChain d from to e' chain)
      | atomEq -> return Nothing
      | otherwise -> do
          n <- ensureNamed stated (EqChain start <$> mapM nameChainStep steps)
          return (Just [(UnitEntry (Just n) (unrigidLit stated) Nothing Nothing, d, to)])

-- The chain for a positive unit read from the input-proof step that derived
-- it, with every step's unit named, for make_block to cite. An atom P is read
-- as P = true.
readChainBlock :: Literal -> AlgM (Maybe ProofBlock)
readChainBlock lit = readDerivingStep lit >>= \case
  Just (start, chain@(_ : _)) -> Just . EqChain start <$> mapM nameChainStep chain
  _                           -> return Nothing

-- An electron, the substitution σi that instantiates it, and the rewrites
-- that take it to the body atom.
type ElecMatch = (UnitEntry, Subst, [(RwStep, Literal)])

-- The premises find_elec matched for a nucleus.
type ElecMatches = [ElecMatch]

-- Whether a matched premise is a body atom t = t, which holds by reflexivity.
isReflexivityPremise :: ElecMatch -> Bool
isReflexivityPremise (u, _, _) = case (ueName u, ueProof u, ueUnit u) of
  (Nothing, Just (EqChain _ []), Eq a b) -> a == b
  _                                      -> False

-- The premise instances a match establishes.
matchedPremises :: ElecMatches -> [Literal]
matchedPremises matched = [ matchedPremise ki σi rwi | (ki, σi, rwi) <- matched ]

-- find_elec (Algorithm 2) for the body atoms of a nucleus. Step 1 matches an
-- electron, step 2 reads the input proof's rewriting, and step 3 asks the
-- prover, get_proof. A complete match must pass accept, usually the coherence
-- of the hyperresolution step, or the search backtracks to the next candidate.
findElecs
  :: Prover
  -> (Subst -> ElecMatches -> Bool)
  -> [Literal] -> Subst -> [UnitEntry] -> String
  -> AlgM (Maybe (Subst, ElecMatches))
findElecs prover accept lits theta elecs pos = do
  failedRef <- liftIO (newIORef Set.empty)
  known     <- gets (length . stUnits)
  findElecsMemo prover accept failedRef known lits theta elecs pos

-- findElecs with a memo of failed sub-searches, since a search with the
-- same remaining atoms, premises and units fails again. known is the number
-- of units when the search began.
findElecsMemo
  :: Prover
  -> (Subst -> ElecMatches -> Bool)
  -> IORef (Set.Set String)
  -> Int
  -> [Literal] -> Subst -> [UnitEntry] -> String
  -> AlgM (Maybe (Subst, ElecMatches))
findElecsMemo prover accept failedRef known lits theta elecs pos = goMemo lits theta [] [] []
  where
    -- acc holds the matched premises, latest first. A premise is emitted
    -- general, so a nucleus variable that theta' binds is renamed apart inside
    -- its σi. Otherwise the premise would read as the lemma's bound variable
    -- and the step would not check (SYN163-1/E).
    finish theta' acc =
      let matched = map freshenGrounded (reverse acc)
          nucleusVars = concatMap litVars lits
          usedVars = nucleusVars
                  ++ concat [ litVars (ueUnit ki) ++ map fst σi ++ concatMap (termVars . snd) σi
                            | (ki, σi, _) <- acc ]
                  ++ concatMap (termVars . snd) theta'
          suffix = head [ sfx | n <- [1 :: Int ..], let sfx = concat (replicate n "_e")
                              , not (any (sfx `isSuffixOf`) usedVars) ]
          grounded    = [ (w, w ++ suffix) | w <- nub nucleusVars, isJust (lookup w theta') ]
          freshenGrounded (ki, σi, rwi) =
            (ki, [ (x, renameTerm grounded t) | (x, t) <- σi ], rwi)
      in return (if accept theta' matched then Just (theta', matched) else Nothing)
    goMemo [] theta' _ _ acc = finish theta' acc
    goMemo ls theta' usedPos extra acc = do
      -- The units added since the search began are keyed by what they state,
      -- not by their number, since a failed step takes its units back and
      -- another may add as many different ones.
      added  <- gets (map ueUnit . drop known . stUnits)
      let key = show (map (applySubstLit theta') ls, map ueUnit extra, usedPos, matchedPremises (reverse acc), added)
      failed <- liftIO (readIORef failedRef)
      if Set.member key failed
        then return Nothing
        else do
          r <- go ls theta' usedPos extra acc
          when (isNothing r) $ liftIO (modifyIORef' failedRef (Set.insert key))
          return r

    -- The sibling electron first, then unnamed electrons, then named ones,
    -- each tier nearest position first.
    sortedElecs =
      let (sibling, rest) = case providerSibling pos of
            Nothing -> ([], elecs)
            Just sp -> partition (\e -> uePos e == Just sp) elecs
          (unnamed, named) = partition (isNothing . ueName) rest
          byProx = Down . length . takeWhile id . zipWith (==) pos . fromMaybe "" . uePos
      in sibling ++ sortBy (comparing byProx) unnamed ++ sortBy (comparing byProx) named

    go [] theta' _ _ acc = finish theta' acc
    go (li : restLits) theta' usedPos extraElecs acc = case applySubstLit theta' li of
      -- A body atom t = t needs no electron, only reflexivity. It keeps its
      -- place among the premises, so they stay paired with the body atoms.
      liInst@(Eq a b) | a == b ->
        go restLits theta' usedPos extraElecs ((UnitEntry Nothing liInst (Just (EqChain a [])) Nothing, [], []) : acc)
      liInst -> do
        let (unused, used') = partition (\e -> uePos e `notElem` usedPos) sortedElecs
            prioritized = unused ++ used'
            -- instances from earlier body atoms first, then the electrons,
            -- keeping those named or proved
            pureMatches = [ (ue, σi, [])
                          | ue <- filter isCitable (extraElecs ++ prioritized)
                          , Just σi <- [matchElectron liInst (ueUnit ue)] ]
            -- the electron at the instance the match used is a step 1
            -- candidate for the later body atoms
            continueWith m@(ki, σi, _) =
              goMemo restLits theta' (uePos ki : usedPos) (ki { ueUnit = applySubstLit σi (ueUnit ki) } : extraElecs) (m : acc)
        dbgFlag <- gets stDebug
        liftIO $ dbg dbgFlag $ "[match] " ++ ppLiteral liInst ++ " step1="
          ++ show [ fromMaybe (fromMaybe "" (uePos ue)) (ueName ue) ++ ":" ++ ppLiteral (ueUnit ue) | (ue, _, _) <- pureMatches ]
        -- step 1, then steps 2 and 3
        firstJustM (map continueWith pureMatches ++ [tryRwChain liInst continueWith prioritized])

    -- Steps 2 and 3 of find_elec. First the input-proof step that derives
    -- the atom, then the rewrites the proof makes to the atom, which take it
    -- to an electron or to t = t, and last the prover.
    tryRwChain liInst continueWith candidates = do
      units <- gets stUnits
      litRw <- gets (Map.findWithDefault [] pos . stLiteralRewrites)
      debugOn <- gets stDebug
      liftIO $ when debugOn $ sequence_
        [ dbg True ("[litchain] pos=" ++ pos ++ " " ++ ppLiteral liInst ++ " via " ++ ppLiteral b ++ ": "
                    ++ intercalate ", " [ nm ++ " " ++ show d ++ " " ++ ppLiteral l | (nm, d, _, l) <- steps ])
        | (b, steps@(_ : _)) <- litRw, b == liInst || flipLit b == liInst ]
      readable <- gets stReadableUnits
      let -- the step of the input proof that derives an atom
          readStep lit = readDerivingStep lit >>= maybe (return Nothing) (elecFromChain lit pos . snd)
          -- the body atom after each of the proof's rewrites, in the atom's
          -- orientation, with the rewrites
          chains =
            [ (liInst : map (\(_, _, _, l) -> orient l) steps, [ RwStep nm e d | (nm, d, e, _) <- steps ])
            | (b, steps@(_ : _)) <- litRw
            , orient <- take 1 [ o | o <- [id, flipLit], o b == liInst ] ]
          -- A chain cites only established units, one named or proved that
          -- states the applied instance, or one whose derivation can be read.
          -- An equation no unit states yet is read from the step deriving it,
          -- so there is a unit to cite.
          states a b = isJust (matchLit a b)
          ensureStep (RwStep nm (l, r) _)
            | any (\u -> isCitable u && (states (ueUnit u) (Eq l r) || states (ueUnit u) (Eq r l))) units
              || Set.member nm readable = return True
            | otherwise = isJust <$> readStep (Eq l r)
          -- whether makeBlock can cite every step, with the state restored
          citable ki σi steps = do
            saved <- get
            let inst = map (second (applySubstLit σi)) steps
            cited <- attempt (mapM (citeOrSpliceIn litSubtermCtxs) (zip (applySubstLit σi (ueUnit ki) : map snd inst) inst))
            put saved
            return (isRight cited)
          -- Electrons named or proved that state the atom, as in step 1. A
          -- named equation is turned round when needed, so its one-line
          -- citation fits the chain that continues it.
          stating end =
            [ (ue', σi, [])
            | ue <- candidates, isCitable ue
            , let ue' | isJust (ueName ue), isNothing (matchLit (ueUnit ue) end) = ue { ueUnit = flipLit (ueUnit ue) }
                      | otherwise = ue
            , Just σi <- [matchElectron end (ueUnit ue')] ]
          viaChain (atoms, rws) = orRestore $ do
            ready <- foldM (\ok rw -> if ok then ensureStep rw else return False) True rws
            case last atoms of
              _ | not ready -> return Nothing
              -- the rewrites took the equation to t = t, so they join its
              -- sides, and it becomes a unit proved by that chain
              Eq t t' | t == t' -> case splitChain atoms rws of
                Nothing -> return Nothing
                Just (start, chainSteps) -> do
                  cited <- attempt (concat <$> mapM (citeOrSpliceIn termCtxs) (zip (start : map snd chainSteps) chainSteps))
                  case cited of
                    Left _       -> return Nothing
                    Right steps' -> do
                      let ue = UnitEntry Nothing (unrigidLit liInst) (Just (unrigidBlock (EqChain start steps'))) (Just pos)
                      addUnit ue
                      maybe (return Nothing) (\σi -> continueWith (ue, σi, [])) (matchElectron liInst (ueUnit ue))
              -- The rewrites took the atom to one an electron states or a
              -- step derives. That electron's block continues with the
              -- rewrites undone, oriented like its last line.
              end -> do
                let undo = undoRewrites rws atoms
                    undone (ki, σi, rwi) = do
                      let lastLine = if null rwi then ueUnit ki else snd (last rwi)
                          asStated = if isJust (matchLit lastLine end) then id else flipLit
                          steps    = rwi ++ [ (rw, asStated l) | (rw, l) <- undo ]
                      ok <- citable ki σi steps
                      if ok then continueWith (ki, σi, steps) else return Nothing
                firstJustM (map undone (stating end) ++ [readStep end >>= maybe (return Nothing) undone])
      firstJustM $
        [ orRestore (readStep liInst >>= maybe (return Nothing) continueWith) ]
        ++ map viaChain chains
        ++ [ proveElec prover liInst pos units >>= maybe (return Nothing) continueWith ]

-- One step of a chain read off the proof's rewrites. A derived equation
-- used only here has its derivation spliced in at the rewritten subterm, and
-- any other is cited, a derived one as a lemma. The subterm contexts are a
-- parameter, so the chain may be of terms or of literals.
citeOrSpliceIn :: Eq a => (a -> [(Term, Term -> a)]) -> (a, (RwStep, a)) -> AlgM [(RwStep, a)]
citeOrSpliceIn ctxs (prev, (rw, cur)) = do
  steps <- gets stEquationSteps
  lits  <- gets stUnitLitByName
  uses  <- gets stPremiseUses
  let nm = rwName rw
      (from, to) = case rwDir rw of { LR -> rwEq rw; RL -> swap (rwEq rw) }
      once = any (\(c, _, _) -> c == nm) steps && Map.findWithDefault 0 nm uses == 1
      -- the term around the rewritten subterm
      around = listToMaybe [ rebuild | (sub, rebuild) <- ctxs prev, sub == from, rebuild to == cur ]
  spliced <- case (Map.lookup nm lits, around) of
    (Just lit, Just rebuild) | once -> do
      -- read as the general equation, or else at the instance the step
      -- applies, when the proof derived the equation's premises only there
      let readAt e = (>>= instantiateChain (rwDir rw) from to e) <$> readPremiseStep nm e
      chain <- readAt (unitEquation lit) >>= maybe (readAt (rwEq rw)) (return . Just)
      return (map (\(u, d, t) -> (u, d, rebuild t)) <$> chain)
    _ -> return Nothing
  case spliced of
    Just triples -> mapM nameChainStep triples
    Nothing      -> (: []) <$> citeChainStep (rw, cur)

-- Rewrites undone in reverse order, each leading back to the term before it.
undoRewrites :: [RwStep] -> [a] -> [(RwStep, a)]
undoRewrites rws prevs = reverse [ (rw { rwDir = flipDir (rwDir rw) }, p) | (rw, p) <- zip rws prevs ]

-- SplitChain of Denzinger and Schulz. Rewrites that take l = r to t = t are
-- split into those of the left side, in order, and those of the right side,
-- undone in reverse, giving the chain from l over t to r.
splitChain :: [Literal] -> [RwStep] -> Maybe (Term, [(RwStep, Term)])
splitChain lits@(Eq a0 _ : _) rws = do
  sides <- sequence [ case (l, l') of
                        (Eq a b, Eq a' b') -> Just (rw, (a, a'), (b, b'))
                        _                  -> Nothing
                    | (l, l', rw) <- zip3 lits (drop 1 lits) rws ]
  let lefts  = [ (rw, a') | (rw, (a, a'), _) <- sides, a /= a' ]
      rights = [ (rw { rwDir = flipDir (rwDir rw) }, b) | (rw, _, (b, b')) <- reverse sides, b /= b' ]
  if null lefts && null rights then Nothing else Just (a0, lefts ++ rights)
splitChain _ _ = Nothing

-- get_proof for a body atom, a chain the prover finds from the units. For
-- an atom with no equational unit, Twee could only find a match step 1
-- already tried, so it is not asked. Variables become fresh constants for
-- the call, since Twee reads goal variables existentially.
proveElec :: Prover -> Literal -> String -> [UnitEntry] -> AlgM (Maybe ElecMatch)
proveElec prover li pos units = do
  let (liSk, undoSk) = freezeLitVars "skv_" (concatMap (litSymbols . ueUnit) units) li
      citable        = filter isCitable units
  mRaw <- if isEqLit li || any (isEqLit . ueUnit) citable
            then liftIO (chainBy prover InternalBudget citable liSk)
            else return Nothing
  maybe (return Nothing) (elecFromChain li pos . map (\(u, d, t) -> (u, d, applyConstSubstTerm undoSk t)) . snd) mRaw

-- The electron a chain for body atom li gives. It is a unit the chain
-- applies, or the fact a P = true chain ends on, rewritten into li. Else it
-- is a general unit covering an equation, or a new unit proved by the chain.
elecFromChain :: Literal -> String -> [(UnitEntry, Dir, Term)] -> AlgM (Maybe ElecMatch)
elecFromChain _ _ [] = return Nothing
elecFromChain li pos chain = case li of
  Eq l _ -> firstJustM [equationFromChain (l, chain), generalUnit, asUnit l]
  _      -> firstJustM (factFromChain li (start, chain) : [ asUnit start | all validInter chain ])
  where
    -- A general unnamed unit covering the instance beats a new ground unit,
    -- so the lemma is g(X) = X and not g(a) = a. One without a proof is
    -- taken only when its deriving step can be read.
    generalUnit = do
      units <- gets stUnits
      let citable u σg = case (ueProof u, ueUnit u) of
            (Just _, _)           -> return (Just (u, σg, []))
            (Nothing, e@(Eq _ _)) -> fmap (const (u, σg, [])) <$> readChainBlock e
            _                     -> return Nothing
      firstJustM [ citable u σg
                 | u <- units
                 , isNothing (ueName u)
                 , not (null (litOpen (ueUnit u)))
                 , maybe True isEqChain (ueProof u)
                 , Just σg <- [matchLit (ueUnit u) li] ]
    start = atomTerm li
    goalFun = case li of { Rel n _ -> n; _ -> "" }
    validInter (_, _, t) = case t of
      Const n -> n == goalFun || n == "true"
      App n _ -> n == goalFun
      _       -> False
    asUnit from = do
      steps' <- mapM nameChainStep chain
      let ki = UnitEntry Nothing li (Just (EqChain from steps')) (Just pos)
      addUnit ki
      return (Just (ki, [], []))

-- A chain for l = r that applies a unit proved by have/hence to a whole side
-- gives that unit rewritten into the equation. make_block prints the unit,
-- then the steps before it undone on one side and the steps after it on the
-- other, each a hence line.
equationFromChain :: (Term, [(UnitEntry, Dir, Term)]) -> AlgM (Maybe ElecMatch)
equationFromChain (start, chain) =
  case [ (k, u, d, σ)
       | (k, (u, d, to)) <- zip [0 :: Int ..] chain, Just (HaveHence _) <- [ueProof u]
       , Eq a b <- [ueUnit u]
       , let (from, to') = if d == LR then (a, b) else (b, a)
       , Just σ0 <- [matchTermWith from (terms !! k) []]
       , Just σ  <- [matchTermWith to' to σ0] ] of
    [] -> return Nothing
    (k, u, d, σ) : _ -> do
      named <- mapM nameChainStep [ step | (j, step) <- zip [0 ..] chain, j /= k ]
      let (before, after) = splitAt k named
          -- the side the chain leaves is rewritten back to l, the other on
          -- to r
          mk lft rgt = if d == LR then Eq lft rgt else Eq rgt lft
          undo = undoRewrites (map fst before) [ mk t (terms !! (k + 1)) | t <- terms ]
          on   = [ (rw, mk start (terms !! j))
                 | (j, (rw, _)) <- zip [k + 2 ..] after ]
      return (Just (u, σ, undo ++ on))
  where
    terms = start : [ t | (_, _, t) <- chain ]

-- A chain from P(t) to true ends with the fact P(s) its last step cites. It
-- gives that fact rewritten into the atom, P(s) and then the chain's
-- rewrites undone, each a hence line.
factFromChain :: Literal -> (Term, [(UnitEntry, Dir, Term)]) -> AlgM (Maybe ElecMatch)
factFromChain li (start, chain) = case (li, reverse chain) of
  (Rel p _, (fact, _, Const "true") : revEqs)
    | Rel q _ <- ueUnit fact, p == q
    , all (\(u, _, _) -> isEqLit (ueUnit u)) revEqs
    , Just atoms <- mapM termAtom (start : [ t | (_, _, t) <- init chain ])
    , Just σ <- matchLit (ueUnit fact) (last atoms) -> do
        named <- mapM nameChainStep (init chain)
        return (Just (fact, σ, undoRewrites (map fst named) atoms))
  _ -> return Nothing

-- make_block (Algorithm 3), the block for electron ki at σi continued by
-- rwSteps. The rewrites are given on the uninstantiated electron, so σi is
-- applied to them, and the block reads "hence p(a)", not "hence p(X)".
makeBlock :: UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
makeBlock ki σi rwSteps = do
  units <- gets stUnits
  base  <- buildBase units
  let inst = map (second (applySubstLit σi)) rwSteps
  rwStepsInst <- concat <$> mapM (citeOrSpliceIn litSubtermCtxs) (zip (lit : map snd inst) inst)
  return (foldl (\b (rw, c) -> appendLine b (Hence c (ByRw (rwName rw) (rwDir rw)))) base rwStepsInst)
  where
    lit = applySubstLit σi (ueUnit ki)
    -- the one-line block citing a name
    have nm = HaveHence [Have lit nm]
    -- the one-line block citing a fact that blk proves, as a lemma
    haveLemma fact blk = have <$> ensureNamed fact (return blk)
    -- a stored chain is cited as a lemma, and any other proof instantiated
    reuse u σ stored
      | isEqChain stored = haveLemma (ueUnit u) stored
      | otherwise        = return (instantiateBlock (ueUnit u) σ stored)
    -- an unnamed equation read from the input-proof step that derives it
    readEq u orElse = readChainBlock (ueUnit u) >>= maybe orElse (haveLemma (ueUnit u))

    buildBase units = do
      let allUnnamed = filter (\u -> ueUnit u == ueUnit ki && isNothing (ueName u)) units
          hasHence (HaveHence ls) = any (\case Hence {} -> True; _ -> False) ls
          hasHence _              = False
          mBest = find (maybe False hasHence . ueProof) allUnnamed
              <|> find (isJust . ueProof) allUnnamed
              <|> listToMaybe allUnnamed
      case mBest of
        Just unnamed -> case ueProof unnamed of
          Just stored
            | not (hasHence stored) -> haveLemma (ueUnit ki) stored
            | otherwise             -> return (instantiateBlock (ueUnit unnamed) σi stored)
          -- an equation is read from the input-proof step that derives it,
          -- and an atom is taken from a more general unit with a proof
          Nothing
            | isEqLit (ueUnit unnamed) -> readEq unnamed (namedCase units)
            | otherwise -> case listToMaybe [ (u, σg, stored) | u <- units, isNothing (ueName u)
                                                              , Just stored <- [ueProof u]
                                                              , Just σg <- [matchLit (ueUnit u) lit] ] of
                Just (genU, σg, stored) -> reuse genU σg stored
                Nothing                 -> namedCase units
        Nothing -> namedCase units

    -- a named electron is cited by its name, and otherwise by a unit that
    -- states it or one it instantiates
    namedCase units
      | Just nm <- ueName ki = return (have nm)
      | otherwise = case find (\u -> ueUnit u == ueUnit ki) units of
          Just u -> case ueName u of
            Just nm -> return (have nm)
            -- an unnamed unit without a proof, read from the step that
            -- derives it
            Nothing
              | isEqLit (ueUnit u) ->
                  readEq u (throwError ("makeBlock: cannot prove unnamed eq unit: " ++ ppLiteral (ueUnit ki)))
              | otherwise -> case listToMaybe [ nm | nu <- units, Just nm <- [ueName nu], Just _ <- [matchLit (ueUnit nu) lit] ] of
                  Just nm -> return (have nm)
                  -- an atom no unit proves is a lemma, with the chain the
                  -- input proof gives for it
                  Nothing -> readChainBlock lit >>= maybe (throwError ("no proof found for the unit " ++ ppLiteral lit))
                                                          (fmap have . promoteToLemma lit)
          -- ki may be an electron instance that the table lacks, so an
          -- entry it instantiates is cited or its proof instantiated. Entries
          -- with a name or proof come first, or one without could shadow a
          -- derived unit that has a proof (RNG008-5).
          Nothing -> case listToMaybe (mbCands isCitable ++ mbCands (not . isCitable)) of
            Just (u, sg)
              | Just nm <- ueName u      -> return (have nm)
              | Just stored <- ueProof u -> reuse u sg stored
            _ -> throwError ("makeBlock: unit not in table: " ++ ppLiteral (ueUnit ki))
      where
        mbCands who = [ (u, sg) | u <- units, who u, Just sg <- [matchLit (ueUnit u) (ueUnit ki)] ]

-- The premise a matched electron establishes, the last line of its rewrites
-- or else the electron itself, under σi.
matchedPremise :: UnitEntry -> Subst -> [(RwStep, Literal)] -> Literal
matchedPremise ki σi rw = case rw of
  [] -> applySubstLit σi (ueUnit ki)
  -- rw is on the uninstantiated electron, so σi is applied here too, or a
  -- lemma would state q(g(X)) while its proof shows q(g(a))
  _  -> applySubstLit σi (snd (last rw))

-- The head a nucleus step concludes, as its cited premises derive it, so
-- applying the axiom reproduces it. That is the head under theta, oriented as
-- the premises derive it, or the derived head when the premises fix more of
-- it than theta does.
stepConclusion :: [Literal] -> Literal -> Subst -> [Literal] -> Literal
stepConclusion bodyAbs headLit theta targets = case derivedHead bodyAbs headLit targets of
  Just d -> fromMaybe d (find (isJust . matchLit d) [headInst, flipLit headInst])
  Nothing -> headInst
  where
    headInst = applySubstLit theta headLit

-- The block for one nucleus step. A premise t = t gets no line, the first
-- other premise opens the block and the rest follow as and lines, then a
-- named nucleus derives the head. Without premises the named axiom asserts
-- the head under theta (the raw head claims more), and unnamed it fails.
nucleusBlock
  :: [Literal]     -- the rule's body atoms, as the axiom states them
  -> ElecMatches
  -> Maybe String  -- axiom name for "hence L0 by name", if the nucleus has one
  -> Subst         -- the substitution the body atoms were matched under
  -> Literal       -- head literal L0
  -> AlgM ProofBlock
nucleusBlock bodyAbs matched mAxName theta headLit = case filter (not . isReflexivityPremise) matched of
  [] -> case mAxName of
    Just ax -> return (HaveHence [Have (applySubstLit theta headLit) ax])
    Nothing -> throwError ("nucleusBlock: unjustified unit " ++ ppLiteral (applySubstLit theta headLit))
  (k1, σ1, rw1) : rest -> do
    blk1 <- makeBlock k1 σ1 rw1
    blk  <- foldM addAnd blk1 rest
    return $ case mAxName of
      Just ax -> appendLine blk (Hence (stepConclusion bodyAbs headLit theta (matchedPremises matched)) (ByAxiom ax))
      Nothing -> blk
  where
    addAnd blk (ki, σi, rwi) = do
      let targ = matchedPremise ki σi rwi
      -- A non-ground, unrewritten premise from an electron with a proof cites
      -- the electron's own lemma, which stays general. Any other premise is
      -- named with its own block.
      nm <- if null rwi && isJust (ueProof ki) && not (null (litOpen targ))
              then ensureNamed (ueUnit ki) (makeBlock ki [] [])
              else makeBlock ki σi rwi >>= ensureNamed targ . return
      return (appendLine blk (And targ nm))

-- The block for a goal that electron ki proves. An unnamed electron proved
-- by an equality chain gives that chain. An equational goal otherwise gets a
-- one-step chain by the named electron or the chain read from the input
-- proof. Everything else goes through makeBlock.
goalBlock :: Literal -> UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
goalBlock _ ki σi []
  | isNothing (ueName ki), Just blk@(EqChain {}) <- ueProof ki = return (instantiateBlock (ueUnit ki) σi blk)
goalBlock gl@(Eq _ _) ki σi []
  | isNothing (ueName ki), Just (HaveHence {}) <- ueProof ki = makeBlock ki σi []
  | Just blk <- buildEqChainFromElectron gl ki σi = return blk
  | otherwise = readChainBlock gl >>= maybe (makeBlock ki σi []) return
goalBlock _ ki σi rwi = makeBlock ki σi rwi

-- A one-step chain for l = r by the named electron at σi, in either direction.
buildEqChainFromElectron :: Literal -> UnitEntry -> Subst -> Maybe ProofBlock
buildEqChainFromElectron (Eq l r) ki σi = do
  nm    <- ueName ki
  (a,b) <- case ueUnit ki of { Eq a b -> Just (a,b); _ -> Nothing }
  let a' = applySubstTerm σi a
      b' = applySubstTerm σi b
      tryDir d = case listToMaybe (rewriteTermAll l (a', b') d) of
                   Just cur | cur == r -> Just (EqChain l [(RwStep nm (a,b) d, r)])
                   _                   -> Nothing
  tryDir LR <|> tryDir RL
buildEqChainFromElectron _ _ _ = Nothing

-- A block proving a literal by a named axiom nucleus whose head matches it
-- and whose body the electrons close. A goal reached by a nucleus without a
-- display name is justified this way, since that nucleus cannot be cited.
justifyByAxiom
  :: Prover
  -> Literal                           -- the literal to justify
  -> String                            -- the position whose electrons may be used
  -> AlgM (Maybe ProofBlock)
justifyByAxiom prover goalLit pos = do
  axNuclei <- gets stAxNuclei
  elecs    <- getElectrons pos
  -- as in translateNucleus, the instantiated axiom must derive the goal
  firstJustM
    [ do let coherent theta' m = resolutionCoherent bodyPats hdPat (matchedPremises m) (applySubstLit theta' goalLit)
         mRes <- findElecs prover coherent (map (applySubstLit σh) bodyPats) [] elecs pos
         dbgFlag <- gets stDebug
         forM mRes $ \(theta', matched) -> do
           liftIO $ dbg dbgFlag $ "[axjust] " ++ axName ++ " for " ++ ppLiteral goalLit
             ++ " premises=" ++ show (map ppLiteral (matchedPremises matched))
           nucleusBlock bodyPats matched (Just axName) theta' goalLit
    | (axName, Clause bodyPats (Just hdPat)) <- axNuclei
    , Just σh <- [matchLit hdPat goalLit] ]

-- Whether a literal states one of the goals, one an instance of the other.
statesGoal :: [Literal] -> Literal -> Bool
statesGoal goalLits l = any (\g -> isJust (matchLit g l) || isJust (matchLit l g)) goalLits

-- One nucleus of Algorithm 1 translate_proof. find_elec matches its body
-- atoms under θ, and the step's block proves the head as a new unit or
-- proves goals. Returns whether a goal was emitted.
translateNucleus
  :: Prover
  -> Bool
  -> ThetaCtx                        -- θ over the tree, read per nucleus
  -> LeafEntry
  -> Map.Map String String          -- pos → axiom name
  -> [Literal]                       -- goal literals
  -> AlgM Bool
translateNucleus prover debug thetaCtx entry posToName goalLits = do
  let pos     = lePos entry
      mAxName = Map.lookup pos posToName
      -- A negated conjecture keeps the negated formula as its source, which
      -- is no clause when it negates a universal (KLE137+1/Twee). The leaf's
      -- own clause is then the nucleus, with body equations oriented as the
      -- goals state them, since the prover may have turned them round.
      leafCls = (\(Clause bs mh) -> Clause (map orientLit bs) mh) <$> convertDeclToClause (leDecl entry)
      orientLit l@(Eq a b)
        | statesGoal goalLits l        = l
        | statesGoal goalLits (Eq b a) = Eq b a
      orientLit l = l
  case convertDeclToClause (leSrcDecl entry) <|> leafCls of
    Nothing -> do
      liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ") — could not convert to clause"
      return False
    Just (Clause bodyLitsAbs mHead) -> do
      let θ_local  = computeNucleusTheta thetaCtx entry
          bodyLits = map (applySubstLit θ_local) bodyLitsAbs
          coherentStep theta' matched = case mHead of
            Just headLit -> resolutionCoherent bodyLitsAbs headLit (matchedPremises matched) (applySubstLit theta' headLit)
            Nothing      -> True
      -- A clause without a head ends the direct proof and no unit rests on
      -- it, so it may use every unit, also one the tree places after it, as
      -- when the prover reasons from the negated goal first (ROB014-2). The
      -- position z sorts after every other.
      elecs   <- getElectrons (maybe "z" (const pos) mHead)
      mResult <- findElecs prover coherentStep bodyLits θ_local elecs pos
      case mResult of
        Nothing -> do
          liftIO $ dbg debug $ "[skip] pos=" ++ pos ++ " (" ++ leName entry ++ ")"
              ++ "  body=[" ++ intercalate ", " (map ppLiteral bodyLits) ++ "] — no matching electron found"
          return False
        Just (theta, matched) -> do
          liftIO $ dbg debug $ "[matched] pos=" ++ pos ++ " premises="
            ++ show (map ppLiteral (matchedPremises matched)) ++ " head=" ++ maybe "-" (ppLiteral . applySubstLit theta) mHead
          case mHead of
            -- ⊥ from a clause other than the negated conjecture means the
            -- axioms are contradictory, and every goal follows from $false.
            -- The derivation of $false also closes a conjecture that
            -- concludes a negation.
            Nothing | leRole entry /= NegConjecture, Just _ <- mAxName -> do
              blk <- nucleusBlock bodyLitsAbs matched mAxName theta falsumLit
              modify (\st -> st { stClosing = stClosing st <|> Just blk })
              forM_ goalLits $ \gl ->
                emitGoalProof gl gl (appendLine blk (Hence gl ByContradiction))
              return True
            -- otherwise the goal clause closes, and each premise proves a goal
            Nothing -> case (goalLits, matched) of
              ([gl], [(ki, σi, [])])
                | isNothing (ueName ki), Just chain@(EqChain {}) <- ueProof ki ->
                    emitGoalProof gl (applySubstLit theta gl) (instantiateBlock (ueUnit ki) σi chain) >> return True
              _ -> do
                -- Each goal is proved by a premise of its own that it
                -- matches, either way round. theta binds the clause copy's
                -- variables, so the goal's existential variables are bound
                -- by that match. Without such premises for all goals, the
                -- goal phase proves them.
                let assign [] _ = [[]]
                    assign (gl : gls) ms =
                      [ (gl, applySubstLit ρ gl0, m) : rest
                      | let gl0 = applySubstLit theta gl
                      , (m@(ki, σi, rwi), ms') <- picks ms
                      , Just ρ <- [matchLitEither gl0 (matchedPremise ki σi rwi) []]
                      , rest <- assign gls ms' ]
                case assign goalLits matched of
                  pairs : _ | not (null pairs) -> do
                    forM_ pairs $ \(gl, gl', (ki, σi, rwi)) -> goalBlock gl' ki σi rwi >>= emitGoalProof gl gl'
                    return True
                  _ -> return False
            Just headLit -> do
              blk <- nucleusBlock bodyLitsAbs matched mAxName theta headLit
              -- the proof's later rewrites of the head come below, from
              -- stHeadRewrites
              let headInst = stepConclusion bodyLitsAbs headLit theta (matchedPremises matched)
                  -- a circular block cites the head itself as a premise, so
                  -- it is not stored
                  isCircular = headInst `elem` matchedPremises (filter (not . isReflexivityPremise) matched)
                  proofToStore = if isCircular then Nothing else Just blk
                  headUnit = UnitEntry Nothing (unrigidLit headInst) (fmap unrigidBlock proofToStore) (Just pos)
              -- a nucleus without a display name cannot justify its head, so
              -- the head is not stored
              when (isJust mAxName) $ do
                liftIO $ dbg debug $ "[store] pos=" ++ pos ++ " head=" ++ ppLiteral headInst
                  ++ (if isJust proofToStore then "" else " (no proof)")
                addUnit headUnit
                -- an equality chain cannot sit inside a have/hence block, so
                -- it becomes a lemma at once
                when (isJust proofToStore && isEqChain blk) $
                  void (ensureNamed (unrigidLit headInst) (return (unrigidBlock blk)))
                -- The proof may rewrite the head before the clause is a unit,
                -- so the rewritten head is stored too. The rewrites start from
                -- the head under θ, so the stored head, whose head-only
                -- variables θ′ leaves free, is matched onto it first. The
                -- stored equation may be the other way round from θ's, and the
                -- rewrites follow the stored one.
                hRw <- gets (Map.lookup pos . stHeadRewrites)
                case hRw of
                  Just (start, steps) | isJust proofToStore ->
                    case [ (asStored, ρ) | asStored <- [id, flipLit]
                                         , Just ρ <- [matchLit (ueUnit headUnit) (asStored (unrigidLit start))] ] of
                      (asStored, ρ) : _ -> do
                        let rwSteps = [ (RwStep nm (unitEquation (unrigidLit (uncurry Eq e))) d, asStored (unrigidLit l))
                                      | (nm, d, e, l) <- steps ]
                        blkR <- makeBlock headUnit ρ rwSteps
                        addUnit (UnitEntry Nothing (snd (last rwSteps)) (Just blkR) (Just pos))
                      [] -> liftIO $ dbg debug $ "[head-rw] pos=" ++ pos ++ " not applied: the stored head "
                              ++ ppLiteral (ueUnit headUnit) ++ " is no generalisation of " ++ ppLiteral start
                  _ -> return ()
              -- An unnamed nucleus whose head is a goal cannot be cited, so a
              -- named axiom justifies the goal, with headLit turned to match.
              let orientedPair gl
                    | headInst == gl                     = Just (gl, headLit)
                    | isEqLit gl, flipLit headInst == gl = Just (gl, flipLit headLit)
                    | otherwise                          = Nothing
              case (mAxName, listToMaybe (mapMaybe orientedPair goalLits)) of
                (Nothing, Just (gl, headLitOr)) | not (null matched) ->
                  justifyByAxiom prover (applySubstLit theta headLitOr) pos
                    >>= maybe (return False) (\blk' -> emitGoalProof gl gl blk' >> return True)
                _ -> return False

-- The goal literals no emitted goal proves. An emitted goal proves one it
-- unifies with, either way round, since its fresh constants are variables
-- again. Counting emitted goals would let a conjunct proved twice hide one
-- proved never.
openGoalsOf :: [Literal] -> AlgM [Literal]
openGoalsOf goalLits = do
  emitted <- gets (map fst . stGoals)
  let proves e0 g = let e = suffixVarsLit "_e" e0
                    in isJust (unifyLits g e []) || isJust (unifyLits (flipLit g) e [])
  return (nub [ g | g <- goalLits, not (any (`proves` g) emitted) ])

-- The nucleus loop of Algorithm 1 translate_proof, one pass in tree order,
-- where each provider comes before its consumer. Returns the nuclei that
-- fail.
translateNuclei
  :: Prover
  -> Bool  -- debug
  -> ThetaCtx     -- θ over the tree, read per nucleus
  -> [LeafEntry]
  -> Map.Map String String
  -> [Literal]
  -> AlgM [LeafEntry]
translateNuclei prover debug thetaCtx nuclei posToName goalLits = do
  when debug $ liftIO $ do
    -- the inferences the θ replay did not reconstruct exactly, where a
    -- failing nucleus usually sits
    let st = tcStatus thetaCtx
    dbg True $ "replay: " ++ show (length [ () | (_, k) <- st, k == "strict" ]) ++ " strict"
      ++ concat [ ", " ++ p ++ "=" ++ k | (p, k) <- st, k /= "strict" ]
    -- θ is one substitution over the tree, each binding tagged with the
    -- position of its variable
    dbg True $ "θ = {"
      ++ intercalate ", " [ v ++ "@" ++ lePos e ++ "→" ++ ppTerm t
                          | e <- nuclei, (v, t) <- computeNucleusTheta thetaCtx e ] ++ "}"
  processPass nuclei
  where
    processPass [] = return []
    processPass (entry : rest) = do
      open <- openGoalsOf goalLits
      if null open then return [] else do
        prevCount <- gets (length . stUnits)
        res       <- attempt (translateNucleus prover debug thetaCtx entry posToName goalLits)
        newCount  <- gets (length . stUnits)
        -- a nucleus failed when it threw, or neither proved a goal nor
        -- stored a unit
        failedHere <- case res of
          Right done -> return (not done && newCount == prevCount)
          Left msg   -> do
            liftIO $ dbg debug $ "[skip] pos=" ++ lePos entry ++ " — " ++ msg
            return True
        ([ entry | failedHere ] ++) <$> processPass rest

-- A unit stating a relational goal, matched onto the goal or the goal onto it.
findUnitForGoal :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst, Literal)
findUnitForGoal goal units = listToMaybe $
  [ (ue, ρ0, goal)
  | ue <- units, Just ρ0 <- [matchLit (ueUnit ue) goal] ]
  ++
  [ (ue, [], applySubstLit ρ0 goal)
  | ue <- units, Just ρ0 <- [matchLit goal (ueUnit ue)] ]

-- A substitution making l and r equal, by matching one side onto the other.
-- The goal's variables are existential, so this instance proves it.
reflexiveInstance :: Term -> Term -> Maybe Subst
reflexiveInstance l r = listToMaybe
  [ ρ | (p, t) <- [(l, r), (r, l)]
      , Just ρ <- [matchTermWith p t []]
      , applySubstTerm ρ l == applySubstTerm ρ r ]

-- Proves a goal the nuclei left open, an instance of the given conjunct. It
-- tries a unit that states it, then for an equation reflexivity or a chain
-- from the input proof or the prover, for an atom a fact the input proof
-- rewrites into it, and last a named axiom whose head is the goal.
proveGoal :: Prover -> Literal -> Literal -> AlgM ()
proveGoal prover conj goal = do
  units <- gets stUnits
  case goal of
    Eq l r -> case listToMaybe [ (u, σ) | u <- units
                                        , isNothing (ueName u)
                                        , Just σ <- [matchElectron goal (ueUnit u)]
                                        , Just (HaveHence {}) <- [ueProof u] ] of
      Just (u, σ) -> makeBlock u σ [] >>= emitGoalProof conj goal
      -- a goal whose sides match holds by reflexivity at that instance,
      -- where Twee prints reflexivity and Vampire equality_resolution
      Nothing | Just ρ <- reflexiveInstance l r -> do
        let l' = deepApplySubstTerm ρ l
        emitGoalProof conj (Eq l' l') (EqChain l' [])
      Nothing -> do
        -- a chain read from the input proof, or else found by the prover
        mChain <- readDerivingStep goal
                    >>= maybe (liftIO (chainBy prover GoalBudget (filter isCitable units) goal)) (return . Just)
        case mChain of
          Just (start, chain@(_ : _)) -> mapM nameChainStep chain >>= emitGoalProof conj goal . EqChain start
          _ -> do
            -- an equational goal can be the head of a Horn axiom such as
            -- antisymmetry (HEN010-3), in either orientation
            mAx <- firstJustM [ fmap (g,) <$> justifyByAxiom prover g "z" | g <- [goal, Eq r l] ]
            case mAx of
              Just (g, blk) -> emitGoalProof conj g blk
              Nothing       -> throwError ("no proof found for goal: " ++ ppLiteral goal)
    _ -> case findUnitForGoal goal units of
      Just (ue, ρ0, instGoal) -> makeBlock ue ρ0 [] >>= emitGoalProof conj instGoal
      Nothing -> do
        -- for a ground goal no unit states, find_elec's step 2, a fact
        -- rewritten into the goal by the input-proof step that derives it
        fromFact <- if null (litOpen goal)
                      then readDerivingStep goal >>= maybe (return Nothing) (factFromChain goal)
                      else return Nothing
        case fromFact of
          Just (ki, σi, rwi) -> makeBlock ki σi rwi >>= emitGoalProof conj goal
          Nothing -> justifyByAxiom prover goal "z"
                       >>= maybe (throwError ("no unit found for goal: " ++ ppLiteral goal)) (emitGoalProof conj goal)

-- The key of an axiom's display name, its source unit and its clause, so the
-- axioms of a unit that clausifies to several stay apart.
electronNameKey :: Map.Map String T.Unit -> LeafEntry -> String
electronNameKey unitMap e =
  leName e ++ "#" ++ clauseKey (Clause [] (Just (electronLit unitMap e)))

-- The same key for a nucleus, from its source clause.
nucleusNameKey :: LeafEntry -> String
nucleusNameKey e =
  leName e ++ "#" ++ maybe "" clauseKey (convertDeclToClause (leSrcDecl e))

-- The literal an electron leaf states. An axiom leaf states its source
-- formula when it is an instance of it, either way round, and otherwise its
-- own literal, as when the traced source is unrelated.
electronLit :: Map.Map String T.Unit -> LeafEntry -> Literal
electronLit unitMap e
  | leRole e == OrigAxiom
  , Just (T.Unit _ srcDecl _) <- Map.lookup (leName e) unitMap
  , Just srcLit <- headLitOf srcDecl
  , let converted = convertLit srcLit
  , isJust (matchLitEither converted derivedLit []) = converted
  | otherwise = derivedLit
  where
    derivedLit = case headLitOf (leDecl e) of
      Just lit -> convertLit lit
      Nothing  -> error ("electronLit: no head literal for " ++ leName e)

-- Whether two axioms state the same clause up to one renaming of its
-- variables. An axiom that several runs bring in then gets one outer number.
sameAxiomStatement :: Axiom -> Axiom -> Bool
sameAxiomStatement (AUnit _ a) (AUnit _ b) = variantLit a b
sameAxiomStatement (ANucleus _ c1) (ANucleus _ c2) = variantClause c1 c2
sameAxiomStatement _ _ = False

-- The axioms of a proof tree with their display names. An axiom nameOverride
-- names takes that name and stays off the list, which the outer proof holds,
-- and one it maps to "" is skipped, like the negated goal of a lemma's
-- sub-run.
assignAxiomNames
  :: Map.Map String String  -- TSTP name to display name, where "" skips the axiom
  -> Bool                   -- the conjecture concludes a negation
  -> [Literal]              -- goal literals
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
    -- an axiom is one clause of a source unit, so a FOF unit can give
    -- several
    step acc@(axAcc, posMap, seen) (pos, leaf) = case Map.lookup seenKey seen of
      -- an internal unit is recorded as "", and a later occurrence is
      -- skipped too, or a step would print a nameless "by"
      Just existingName | not (null existingName) -> (axAcc, Map.insert pos existingName posMap, seen)
      Just _ -> acc
      Nothing -> case Map.lookup seenKey nameOverride <|> Map.lookup (leName e) nameOverride of
        -- the outer proof's display name, which its axiom list holds
        Just nm | not (null nm) -> (axAcc, Map.insert pos nm posMap, Map.insert seenKey nm seen)
        -- "" marks a unit that is no axiom, as a lemma sub-run's negated goal
        Just _ -> (axAcc, posMap, Map.insert seenKey "" seen)
        Nothing | Just axiom <- newAxiom ->
          let nm = freshAxiomName axAcc
          in (axAcc ++ [axiom nm], Map.insert pos nm posMap, Map.insert seenKey nm seen)
        Nothing -> acc
      where
        (e, seenKey, newAxiom) = case leaf of
          Left el  -> (el, electronNameKey unitMap el, Just (`AUnit` electronLit unitMap el))
          -- leSrcDecl keeps the source's body order and equation directions.
          -- A headless clause stating the goals is the negated conjecture and
          -- gets no name, any other is a negative fact. A hypothesis is named
          -- even when it reads like the negated conjecture (SYN929+1).
          Right nu -> (nu, nucleusNameKey nu, case convertDeclToClause (leSrcDecl nu) of
            Just cls@(Clause bs mh)
              | isJust mh || not (all (statesGoal goalLits) bs) || leHyp nu -> Just (`ANucleus` cls)
            _ -> Nothing)
    -- A headless clause stating the goals is normally the negated
    -- conjecture. When the conjecture concludes a negation it is the axiom
    -- the proof closes with, listed like any other.
    goalLits | negationConj = []
             | otherwise    = goalLits0

    -- The next "axiom N" used neither here nor by the override, so a sub-run
    -- never reuses an outer name (LCL126-1/E).
    freshAxiomName axAcc =
      head (freeAxiomNames (\nm -> Set.member nm takenNames || nm `elem` map axiomName axAcc))
    takenNames = Set.fromList (filter (not . null) (Map.elems nameOverride))

-- Algorithm 1 translate_proof on one proof tree. The nuclei and goals run
-- first without a prover and then with Twee for what is open, and the goals
-- proved must be one instance of the conjecture. A failure gives its reason.
translateTree
  :: Bool
  -> ProofInfo
  -> [T.Unit]
  -> Map.Map String BuiltLemma   -- TSTP name to prebuilt lemma, with its lifted sub-lemmas
  -> Map.Map String String       -- TSTP name to display name
  -> Maybe [Axiom]               -- the fixed axiom list, or Nothing to build it from this tree
  -> IO (Either String StructuredProof)
translateTree debug info allUnits candLemmaMap nameOverride mFixedAxioms = do
  let unitMap    = Map.fromList [(unitNameStr n, u) | u@(T.Unit n _ _) <- allUnits]
      thetaCtx   = thetaContext info
      nameToPos  = Map.fromList [ (leName e, lePos e) | e <- piElectrons info ]
      -- the input proof's equation steps, so a unit one derived is read
      -- from it rather than proved again
      (steps0, stepUnits) = equationSteps allUnits
      -- The rewrites the proof makes to each nucleus's body atoms. A step's
      -- equation is named through its unit, since a unit used twice has an
      -- electron entry at its first position only.
      elecNameOf = Map.fromList [ (leUnit e, fromMaybe (leName e) (Map.lookup (leName e) nameToAxiom)) | e <- piElectrons info ]
      literalRw = Map.fromList
        [ (lePos e, [ (b, steps) | (b, raw) <- literalRewrites thetaCtx (lePos e)
                                 , Just steps <- [mapM named raw]
                                 , not (any atomStep steps) ])
        | e <- piNuclei info ]
      atomStep (_, _, (l, r), _) = isAtomEquation (predicateSymbols allUnits) (Eq l r)
      -- an electron goes by its display name, and a nucleus head by its unit
      -- name, which the citation resolves to the electron it derived
      named (p, d, e, l) = (\u -> (fromMaybe u (Map.lookup u elecNameOf), d, e, l)) <$> Map.lookup p (piUnitAt info)
      -- the rewrites of each nucleus's head before the clause is a unit
      headRw = Map.fromList
            [ (lePos e, (start, steps)) | e <- piNuclei info
                                        , (Just start, raw) <- [headRewrites thetaCtx (lePos e)]
                                        , Just steps@(_ : _) <- [mapM named raw]
                                        , not (any atomStep steps) ]
      -- every positive unit's literal by TSTP name, for reading steps
      unitLitByTstpName = Map.fromList $
        [ (nm, convertLit tl)
        | (nm, decl) <- [ (unitNameStr n, d) | T.Unit n d _ <- allUnits ] ++ stepUnits
        , isPositiveUnitFormula decl
        , Just tl <- [headLitOf decl]
        , not (isReservedTLit tl) ]
        -- a conditional equation, by its head, which only the units the
        -- proof derives state
        ++ [ (unitNameStr n, h) | T.Unit n d _ <- allUnits
                                , Just (Clause (_ : _) (Just h@(Eq _ _))) <- [convertDeclToClause d] ]
      -- Goal j is G_jθ, the goal literal instantiated as far as the proof
      -- fixes it, read off the negated conjecture nuclei nearest the root first.
      goalLits'  = instantiateGoals (map convertLit (piGoalLits info))
      instantiateGoals gs
        | all (null . litOpen) gs = gs
        | otherwise = case solveWith [] instBodies openGoals of
            (σ : _) -> map (applySubstLit σ) gs
            []      -> map inst gs
        where
          goalNuclei = sortBy (comparing (\e -> (length (lePos e), lePos e)))
                         [ e | e <- piNuclei info, leRole e == NegConjecture ]
          instBodies = [ applySubstLit (computeNucleusTheta thetaCtx e) l
                       | e <- goalNuclei
                       , Just (Clause bs _) <- [convertDeclToClause (leDecl e)]
                       , l <- bs ]
          -- The goal literals share variables, so one substitution must fit
          -- them all, or a variable could get two values (PUZ011-1). The
          -- search backtracks over which body atom answers which goal, and
          -- uses each body atom once.
          openGoals = [ g | g <- gs, not (null (litOpen g)) ]
          solveWith σ _ []             = [σ]
          solveWith σ bodies (g : rest) =
            concat [ solveWith σ' (before ++ after) rest
                   | (before, b : after) <- zip (inits bodies) (tails bodies)
                   , Just σ' <- [matchEither g b σ] ]
          -- the negated clause may state a goal equation the other way round
          matchEither g b σ = listToMaybe
            [ σ' | g0 <- [g, flipLit g], Just σ' <- [matchLitWith g0 b σ], applySubstLit σ' g0 == b ]
          -- when no joint assignment exists, as when some goal is no body
          -- atom, each goal is instantiated alone
          inst g = fromMaybe g (listToMaybe [ applySubstLit ρ g | b <- instBodies, Just ρ <- [matchEither g b []] ])

      (rawAxiomList0, posToName0, namedUnits0) =
        assignAxiomNames nameOverride negationConj goalLits' (piElectrons info) (piNuclei info) unitMap
      -- With a fixed outer list, an axiom the override cannot name takes the
      -- name of an outer axiom with its statement, or else a number the outer
      -- list does not use, since assignAxiomNames' own may clash (ALG018+1/E).
      (rawAxiomList, posToName, namedUnits, extraFixed) = case mFixedAxioms of
        Nothing    -> (rawAxiomList0, posToName0, namedUnits0, [])
        Just fixed ->
          let fixedNames = map axiomName fixed
              assign _ [] = []
              assign used (a : as) =
                let nm = axiomName a
                in case find (sameAxiomStatement a) fixed of
                     Just f -> (nm, axiomName f) : assign used as
                     Nothing
                       | nm `elem` fixedNames || nm `elem` used ->
                           let new = head (freeAxiomNames (\n -> n `elem` fixedNames || n `elem` used))
                           in (nm, new) : assign (new : used) as
                       | otherwise -> (nm, nm) : assign (nm : used) as
              ren = Map.fromList (assign [] rawAxiomList0)
              rn n = Map.findWithDefault n n ren
              renamed = [ renameAxiom (rn (axiomName a)) a | a <- rawAxiomList0 ]
          in ( renamed
             , Map.map rn posToName0
             , [ u { ueName = fmap rn (ueName u) } | u <- namedUnits0 ]
             , [ a | a <- renamed, axiomName a `notElem` fixedNames ] )
      negationConj = concludesNegation allUnits

      -- the axiom electrons by TSTP name, with their display names
      axiomElectrons =
        [ (leName e, nm) | e <- piElectrons info, leRole e == OrigAxiom, Just nm <- [Map.lookup (lePos e) posToName] ]
      nameToAxiom = Map.fromList axiomElectrons
      -- the axiom electrons that are prebuilt lemmas
      prebuilt = [ p | p@(n, _) <- axiomElectrons, Map.member n candLemmaMap ]
      candAxiomNames = Set.fromList (map snd prebuilt)
      -- the axioms proper, without those lemmas
      axiomList = case mFixedAxioms of
        Just fixed -> fixed ++ extraFixed
        Nothing    -> filter ((`Set.notMember` candAxiomNames) . axiomName) rawAxiomList
      -- the prebuilt lemmas in tree order, each after its sub-lemmas and the
      -- candidates it cites
      preLemmaEntries = orderPrebuiltLemmas candLemmaMap prebuilt

      derivedUnits =
        [ UnitEntry Nothing lit mProof (Just (lePos e))
        | e <- piElectrons info, leRole e == Derived
        , let lit    = electronLit unitMap e
              mProof = fmap (\(_, b, _, _) -> b) (Map.lookup (leName e) candLemmaMap)
        , lit `notElem` goalLits' ]

      -- Equational file axioms the refutation reaches that are no leaves of
      -- the tree, as when a proof uses an axiom only inside a rewriting
      -- chain. They are added as units, and the output keeps those it cites.
      proofTreeAxNames = Set.fromList
        [ leName e | e <- piElectrons info ++ piNuclei info
                   , leRole e == OrigAxiom ]
      reached = Set.fromList (maybe [] (reachedNames unitMap) (findRoot allUnits))
      bgEqLits = nub
        [ clit
        | u@(T.Unit n decl _) <- allUnits
        , hasAxiomRole decl
        , not (isDerivedUnit u)
        , unitNameStr n `Set.member` reached
        , unitNameStr n `Set.notMember` proofTreeAxNames
        -- not already named by the outer proof, as an axiom used in a lemma is
        , unitNameStr n `Map.notMember` nameOverride
        -- positive units only, since headLitOf would drop the body of a
        -- clause like comp(X,Y) => meet(X,Y) = zero
        , Just (Clause [] (Just _)) <- [convertDeclToClause decl]
        , Just lit <- [headLitOf decl]
        , let clit = convertLit lit
        , isEqLit clit
        ]
      -- the next axiom numbers neither this run nor the outer proof uses
      bgNames = freeAxiomNames (\nm -> nm `elem` map axiomName axiomList || nm `elem` Map.elems nameOverride)
      bgAxiomList  = zipWith AUnit bgNames bgEqLits
      bgNamedUnits = [ UnitEntry (Just nm) lit Nothing Nothing | (nm, lit) <- zip bgNames bgEqLits ]
      -- unit axioms of the list that are no leaves here, used only inside a
      -- prebuilt lemma, are electrons like every other axiom
      listedAxiomUnits =
        [ UnitEntry (Just nm) lit Nothing Nothing
        | AUnit nm lit <- axiomList
        , nm `notElem` mapMaybe ueName namedUnits ]

      -- the nuclei are the non-unit leaves, as collect_leaves returns them,
      -- and derived inner nodes are what the algorithm rebuilds
      allNuclei   = sortBy (comparing lePos)
                      (filter (\e -> leRole e `elem` [OrigAxiom, NegConjecture]) (piNuclei info))

      -- only nuclei with a display name can be cited
      axNucleiList = [ (nm, cl) | e <- piNuclei info
                                 , leRole e == OrigAxiom
                                 , Just nm <- [Map.lookup (lePos e) posToName]
                                 , Just cl <- [convertDeclToClause (leDecl e)] ]
      initSt = AlgState
        { stDebug      = debug
        , stUnits      = namedUnits ++ listedAxiomUnits ++ derivedUnits ++ bgNamedUnits
        , stLemmas     = preLemmaEntries
        , stGoals      = []
        , stGoalFor    = []
        , stCounter    = length axiomList + length bgAxiomList + 1
        , stAxNuclei   = axNucleiList
        , stNameToPos  = nameToPos
        , stEquationSteps  = steps0
        , stUnitLitByName = unitLitByTstpName
        , stPremiseUses = premiseUses allUnits
        , stLiteralRewrites = literalRw
        , stHeadRewrites = headRw
        , stReadableUnits = readableUnits allUnits
        , stPredicates = predicateSymbols allUnits
        , stUnreadSteps = Set.empty
        , stReadSteps = Map.empty
        , stGoalTemplate = goalLits'
        , stNegationConj = negationConj
        , stClosing = Nothing
        }

  when debug $ do
    dbg debug $ "goals: " ++ intercalate ", " (map ppLiteral goalLits')
    dbg debug ""
    let tagged = map (True,)  (piElectrons info)
              ++ map (False,) allNuclei
        sorted  = sortBy (comparing (lePos . snd)) tagged
        showPos p = if null p then "ε" else p
        posWidth = maximum $ map (length . showPos . lePos . snd) sorted
    forM_ sorted $ \(isElec, e) -> do
      let tag    = if isElec then "+" else "-"
          axNm   = fromMaybe (leName e) (Map.lookup (lePos e) posToName)
          label  = case leRole e of
                     OrigAxiom     -> axNm
                     NegConjecture -> "[goal]"
                     Derived       -> "[derived]"
          lit    = if isElec
                   then ppLiteral (electronLit unitMap e)
                   else maybe "?" ppClause (convertDeclToClause (leSrcDecl e))
      dbg debug $ "  @" ++ padRight posWidth (showPos (lePos e)) ++ " [" ++ tag ++ "] " ++ label ++ ": " ++ lit
    dbg debug ""

  (outcome, finalSt) <- runStateT (runExceptT (action thetaCtx allNuclei posToName goalLits')) initSt
  return $ do
    _ <- outcome
    -- a refutation that never uses the negated conjecture proves no goal
    when (null (stGoals finalSt)) $ Left "no goal proof produced: the refutation does not use the conjecture"
    -- The emitted goals must be one consistent instance of the conjecture,
    -- since Lean would also accept a proof of some other true statement.
    -- Goals are renamed apart and unified, as their free variables are
    -- universal.
    -- Each conjunct tries the goals proved for it first, and each goal its
    -- own conjunct, so the pairing the proof made is found without search.
    let emittedGoals = renameGoalsApart (map fst (stGoals finalSt))
        conjGoals    = map (suffixVarsLit "_c") goalLits'
        provedFor    = zip (stGoalFor finalSt) emittedGoals
        ownFirst k xs = [ x | (k', x) <- xs, k' == k ] ++ [ x | (k', x) <- xs, k' /= k ]
    -- every conjunct needs a goal proof, all under one substitution
    σJoint <- case unifyEachWith [] [ (c', ownFirst c provedFor) | (c, c') <- zip goalLits' conjGoals ] of
      Just σ  -> Right σ
      Nothing -> Left ("goal(s) could not be proved: "
                       ++ intercalate ", " [ ppLiteral c | c <- goalLits'
                                           , isNothing (unifyEach [] [suffixVarsLit "_c" c] emittedGoals) ]
                       ++ " (no emitted goal proves this conjunct)")
    when (isNothing (unifyEachWith σJoint [ (e, ownFirst c (zip goalLits' conjGoals)) | (c, e) <- provedFor ])) $
      Left ("emitted goals are not a consistent instance of the conjecture: "
            ++ intercalate ", " (map (ppLiteral . fst) (stGoals finalSt)))
    -- the derivation of $false comes after the check, which the conjuncts'
    -- own goals pass
    let closing = [ (falsumLit, b) | negationConj, Just b <- [stClosing finalSt] ]
    return (StructuredProof (axiomList ++ bgAxiomList)
                            (stLemmas finalSt) (stGoals finalSt ++ closing) emptyInput)
  where
    action thetaCtx' allNuclei posToName goalLits = do
      -- The goals share existential variables, so the instance one goal is
      -- proved at instantiates the rest, as Algorithm 1 emits every G_j under
      -- one θ.
      let proveOpenGoals prover = openGoalsOf goalLits >>= proveAll prover []
          proveAll _ _ [] = return ()
          proveAll prover θ (g : rest) = do
            let g' = applySubstLit θ g
            attempt (proveGoal prover g g')
              >>= either (\msg -> liftIO $ dbg debug ("[goal] " ++ ppLiteral g' ++ " — " ++ msg)) return
            emitted <- gets (renameGoalsApart . map fst . stGoals)
            let θ' = fromMaybe θ $ listToMaybe
                       [ θ'' | e <- emitted, Just ρ <- [matchLit g' e], Just θ'' <- [extendSubst θ ρ] ]
            proveAll prover θ' rest
      -- First the nuclei and goals with no prover, then Twee only for what
      -- is still open. Asked per body atom, Twee would be called for atoms
      -- the proof derives later and for nuclei no goal needs.
      remaining <- translateNuclei noProver debug thetaCtx' allNuclei posToName goalLits
      proveOpenGoals noProver
      open2 <- openGoalsOf goalLits
      unless (null open2 || null remaining) $
        void (translateNuclei tweeProver debug thetaCtx' remaining posToName goalLits)
      proveOpenGoals tweeProver
      open3 <- openGoalsOf goalLits
      unless (null open3) $
        throwError ("goal(s) could not be proved: "
               ++ intercalate ", " (map ppLiteral open3)
               ++ " (neither the input proof nor the prover gives a proof of it)")
      -- A negated conclusion is proved by deriving $false from its conjuncts,
      -- with their proofs as premises and the closing clause as the rule.
      -- The proof of one conjunct alone proves nothing (SWW469_1).
      negation <- gets stNegationConj
      -- the contradiction route may have recorded the derivation already
      known <- gets stClosing
      -- the derivation of $false by ax, from premises cited by name or
      -- named here from their proofs
      let close ax prems = do
            named <- forM prems $ \(g, src) -> (g,) <$> either return (ensureNamed g . return) src
            let ls = [ (if i == (0 :: Int) then Have else And) g nm | (i, (g, nm)) <- zip [0 ..] named ]
            modify $ \st -> st { stClosing = Just (HaveHence (ls ++ [Hence falsumLit (ByAxiom ax)])) }
      when (negation && isNothing known) $ case closerName goalLits posToName of
        Just ax -> gets stGoals >>= close ax . map (second Right)
        -- The closing clause may also rest on named units beside the goals,
        -- as g(Z) /\ p(Z) => $false on a hypothesis g(s) and a derived p(s).
        -- Its body is established atom by atom under one substitution.
        Nothing -> do
          gs    <- gets stGoals
          units <- gets stUnits
          let named = [ (ueUnit u, Left nm) | u <- units, Just nm <- [ueName u] ]
                   ++ [ (g, Right b) | (g, b) <- gs ]
              establish sigma [] = [(sigma, [])]
              establish sigma (b : bs) =
                [ (sigma'', (applySubstLit sigma'' b, src) : rest)
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
          mapM_ (uncurry close) (take 1 closers)
    -- a hypothesis from a FOF conjecture has the whole formula as its
    -- source, so the leaf's own clause is read then
    closerClause e = convertDeclToClause (leSrcDecl e) <|> convertDeclToClause (leDecl e)
    -- the display name of the clause that closes the refutation on the goals
    closerName goalLits posToName = listToMaybe
      [ nm | e <- piNuclei info
           , Just (Clause bs Nothing) <- [closerClause e]
           , length bs == length goalLits
           , all (\b -> any (\g -> isJust (matchLit b g) || isJust (matchLit g b)) goalLits) bs
           , Just nm <- [Map.lookup (lePos e) posToName] ]

