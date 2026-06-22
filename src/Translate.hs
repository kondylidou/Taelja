module Translate (translate, phaseOne) where

import Control.Monad (foldM)
import Control.Monad.State
import Data.List (find, sortBy)
import Data.List.NonEmpty (toList)
import Data.Maybe (fromMaybe, isJust, isNothing, listToMaybe)
import Control.Applicative ((<|>))
import Data.Ord (comparing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import Helpers
import ProofTree
  ( ProofTree, buildProofTree, leafList
  , isPositiveUnitFormula, headLitOf, unitNameStr
  )

-- Top-level entry: build the proof tree, run the algorithm, return the structured proof.
translate :: Bool -> T.TSTP -> StructuredProof
translate _ (T.TSTP _ units) =
  case buildProofTree units of
    Nothing   -> error "translate: no refutation found"
    Just tree ->
      case phaseOne tree units of
        Nothing                          -> error "translate: no goal found"
        Just (initUnits, nonUnits, goal) ->
          runAlgorithm initUnits nonUnits goal

-- Phase 1: classify leaf clauses into electrons (Units) and nuclei (NonUnits).
-- Leaves are visited in ≺-increasing (left-first DFS) position order.
phaseOne :: ProofTree -> [T.Unit] -> Maybe ([UnitEntry], [(String, String, T.Declaration)], [Literal])
phaseOne tree units =
  case findGoal units of
    Nothing      -> Nothing
    Just rawGoal ->
      let goal    = map convertLit rawGoal
          unitMap = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n _ _) <- units ]
          resolveName = resolveSourceName unitMap
          -- Negated conjecture leaves keep their own declaration (not the source-resolved
          -- one) so their role is visible when assigning axiom names and building blocks.
          origDecl name leafDecl =
            case resolveSourceUnit unitMap name of
              T.Unit origN origD _
                | isNegatedConjecture leafDecl -> (name, leafDecl)
                | isNegatedConjecture origD    -> (name, leafDecl)
                | otherwise -> (unitNameStr origN, origD)
              _ -> (name, leafDecl)
          ls      = leafList tree
          origUnitLit name decl =
            case resolveSourceUnit unitMap name of
              T.Unit _ od _ -> headLitOf od <|> headLitOf decl
              _             -> headLitOf decl
          us      = [ UnitEntry (Just (resolveName name)) (convertLit lit) Nothing (Just pos)
                    | (pos, name, decl) <- ls
                    , isPositiveUnitFormula decl
                    , Just lit <- [origUnitLit name decl] ]
          nus     = [ (pos, nuName, nuDecl)
                    | (pos, name, decl) <- ls
                    , not (isPositiveUnitFormula decl)
                    , let (nuName, nuDecl) = origDecl name decl ]
      in Just (us, nus, goal)

-- TPTP → internal AST conversions

convertTerm :: T.Term -> Term
convertTerm (T.Variable (T.Var v))                   = Var (Text.unpack v)
convertTerm (T.Function (T.Defined (T.Atom f)) [])   = Const (Text.unpack f)
convertTerm (T.Function (T.Defined (T.Atom f)) args) = App (Text.unpack f) (map convertTerm args)
convertTerm (T.Number (T.IntegerConstant n))          = Const (show n)
convertTerm t = error ("convertTerm: unsupported term: " ++ show t)

convertLit :: T.Literal -> Literal
convertLit (T.Predicate (T.Defined (T.Atom n)) args) = Rel (Text.unpack n) (map convertTerm args)
convertLit (T.Equality l T.Positive r)               = Eq  (convertTerm l) (convertTerm r)
convertLit (T.Equality l T.Negative r)               = NEq (convertTerm l) (convertTerm r)
convertLit t = error ("convertLit: unsupported literal: " ++ show t)

resolveSourceName :: Map.Map String T.Unit -> String -> String
resolveSourceName unitMap name = case resolveSourceUnit unitMap name of
  T.Unit n _ _ -> unitNameStr n
  _            -> name

resolveSourceUnit :: Map.Map String T.Unit -> String -> T.Unit
resolveSourceUnit unitMap = go
  where
    -- Follow inference steps back to the original input clause,
    -- but stop at "negated_conjecture" (semantic transformation, not preprocessing).
    go name = case Map.lookup name unitMap of
      Just u@(T.Unit _ _ (Just (T.Inference (T.Atom rule) _ parents, _)))
        | rule /= Text.pack "negated_conjecture" ->
            case concatMap flatParents parents of
              (p:_) -> go p
              []    -> u
      Just u  -> u
      Nothing -> error ("resolveSourceUnit: not found: " ++ name)

    flatParents (T.Parent (T.UnitSource n) _)     = [unitNameStr n]
    flatParents (T.Parent (T.Inference _ _ ps) _) = concatMap flatParents ps
    flatParents _                                  = []

findGoal :: [T.Unit] -> Maybe [T.Literal]
findGoal units =
  case listToMaybe [ lits | T.Unit _ decl _ <- units
                           , isConjecture decl
                           , Just lits <- [goalLiterals decl] ] of
    Just lits -> Just lits
    Nothing   -> listToMaybe
      [ lits | T.Unit _ decl (Just (T.File _ _, _)) <- units
             , isNegatedConjecture decl
             , Just lits <- [unnegateDecl decl] ]

goalLiterals :: T.Declaration -> Maybe [T.Literal]
goalLiterals decl = case headLitOf decl of
  Just lit -> Just [lit]
  Nothing  -> case decl of
    T.Formula _ (T.FOF f) -> conjunctLits f
    _                     -> Nothing

conjunctLits :: T.UnsortedFirstOrder -> Maybe [T.Literal]
conjunctLits (T.Quantified T.Forall _ body) = conjunctLits body
conjunctLits (T.Atomic lit)                 = Just [lit]
conjunctLits (T.Connected l T.Conjunction r) =
  (++) <$> conjunctLits l <*> conjunctLits r
conjunctLits _                              = Nothing

isConjecture :: T.Declaration -> Bool
isConjecture (T.Formula (T.Standard T.Conjecture) _) = True
isConjecture _                                       = False

isNegatedConjecture :: T.Declaration -> Bool
isNegatedConjecture (T.Formula (T.Standard T.NegatedConjecture) _) = True
isNegatedConjecture _                                              = False

unnegateDecl :: T.Declaration -> Maybe [T.Literal]
unnegateDecl (T.Formula _ (T.CNF (T.Clause lits))) = case toList lits of
  [(T.Negative, lit)]                       -> Just [lit]
  [(T.Positive, T.Equality l T.Negative r)] -> Just [T.Equality l T.Positive r]
  _                                         -> Nothing
unnegateDecl (T.Formula _ (T.FOF f)) = fmap (:[]) (unnegateFOF f)
unnegateDecl _                       = Nothing

unnegateFOF :: T.UnsortedFirstOrder -> Maybe T.Literal
unnegateFOF (T.Quantified T.Forall _ body) = unnegateFOF body
unnegateFOF (T.Negated (T.Atomic lit))     = Just lit
unnegateFOF _                              = Nothing

-- Declaration → Clause conversion

convertDeclToClause :: T.Declaration -> Maybe Clause
convertDeclToClause (T.Formula _ (T.CNF (T.Clause lits))) =
  let ls       = toList lits
      bodyLits = [convertLit l | (T.Negative, l) <- ls]
      headLits = [convertLit l | (T.Positive, l) <- ls, not (isReservedTLit l)]
  in mkClause bodyLits headLits
convertDeclToClause (T.Formula _ (T.FOF f)) = convertFOFToClause f
convertDeclToClause _ = Nothing

-- A NEq in head position represents ¬(s=t), so it becomes a body equality with L0=⊥.
-- Multiple NEqs arise from negated conjunctive conjectures; all are kept as body equalities.
mkClause :: [Literal] -> [Literal] -> Maybe Clause
mkClause body []                  = Just (Clause body Nothing)
mkClause body [NEq s t]           = Just (Clause (body ++ [Eq s t]) Nothing)
mkClause body [h]                 = Just (Clause body (Just h))
mkClause body hs | all isNEq hs  = Just (Clause (body ++ [Eq s t | NEq s t <- hs]) Nothing)
mkClause _    _                  = Nothing

isNEq :: Literal -> Bool
isNEq (NEq _ _) = True
isNEq _         = False

isReservedTLit :: T.Literal -> Bool
isReservedTLit (T.Predicate (T.Reserved _) _) = True
isReservedTLit _                              = False

convertFOFToClause :: T.UnsortedFirstOrder -> Maybe Clause
convertFOFToClause fof =
  case collectDisjuncts fof of
    Nothing -> Nothing
    Just pairs ->
      let bodyLits = [convertLit l | (T.Negative, l) <- pairs]
          headLits = [convertLit l | (T.Positive, l) <- pairs, not (isReservedTLit l)]
      in mkClause bodyLits headLits

collectDisjuncts :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
collectDisjuncts (T.Quantified T.Forall _ body) = collectDisjuncts body
collectDisjuncts (T.Atomic lit)                  = Just [(T.Positive, lit)]
collectDisjuncts (T.Negated (T.Atomic lit))      = Just [(T.Negative, lit)]
collectDisjuncts (T.Connected l T.Disjunction r) =
  (++) <$> collectDisjunct l <*> collectDisjunct r
-- Handle implication A => B: body literals from A (negated), head from B.
-- This preserves the orientation of equality literals from original axioms.
collectDisjuncts (T.Connected body T.Implication hd) =
  (++) <$> collectImplBody body <*> collectDisjuncts hd
  where
    collectImplBody (T.Quantified T.Forall _ b) = collectImplBody b
    collectImplBody (T.Atomic lit)              = Just [(T.Negative, lit)]
    collectImplBody (T.Connected l T.Conjunction r) =
      (++) <$> collectImplBody l <*> collectImplBody r
    collectImplBody f = collectDisjuncts (T.Negated f)
collectDisjuncts _ = Nothing

-- Like collectDisjuncts but for one branch of a disjunction.
-- l≠r inside a disjunction is a negative body literal ¬(l=r), not a standalone NEq.
collectDisjunct :: T.UnsortedFirstOrder -> Maybe [(T.Sign, T.Literal)]
collectDisjunct (T.Atomic (T.Equality l T.Negative r)) =
  Just [(T.Negative, T.Equality l T.Positive r)]
collectDisjunct f = collectDisjuncts f

-- Assign "axiom N" names to non-negated-conjecture leaves in DFS position order.
-- Returns: (axiom list, position→axiom-name map, initUnits with names filled in).
assignAxiomNames
  :: [UnitEntry]
  -> [(String, String, T.Declaration)]
  -> ([Axiom], Map.Map String String, [UnitEntry])
assignAxiomNames initUnits nonUnits =
  let unitTags    = [(pos, Left ue)            | ue <- initUnits, Just pos <- [uePos ue]]
      nonUnitTags = [(pos, Right (name, decl)) | (pos, name, decl) <- nonUnits]
      allLeaves   = sortBy (comparing fst) (unitTags ++ nonUnitTags)
      (axiomList, posToName, _) = foldl step ([], Map.empty, Map.empty) allLeaves
      namedUnits =
        [ ue { ueName = Map.lookup pos posToName }
        | ue <- initUnits
        , Just pos <- [uePos ue]
        ]
  in (axiomList, posToName, namedUnits)
  where
    step (axAcc, posMap, origSeen) (pos, Left ue) =
      let origKey = fromMaybe ("@" ++ pos) (ueName ue)
      in case Map.lookup origKey origSeen of
           Just existingName ->
             (axAcc, Map.insert pos existingName posMap, origSeen)
           Nothing ->
             let n      = length axAcc + 1
                 axName = "axiom " ++ show n
                 ax     = AUnit axName (ueUnit ue)
             in (axAcc ++ [ax], Map.insert pos axName posMap, Map.insert origKey axName origSeen)

    step (axAcc, posMap, origSeen) (pos, Right (origName, decl)) =
      case Map.lookup origName origSeen of
        Just existingName ->
          (axAcc, Map.insert pos existingName posMap, origSeen)
        Nothing ->
          case convertDeclToClause decl of
            Just cls@(Clause _ (Just _)) ->
              let n      = length axAcc + 1
                  axName = "axiom " ++ show n
                  ax     = ANonUnit axName cls
              in (axAcc ++ [ax], Map.insert pos axName posMap, Map.insert origName axName origSeen)
            _ ->
              (axAcc, posMap, origSeen)

type AlgM a = State AlgState a

addUnit :: UnitEntry -> AlgM ()
addUnit ue = modify $ \s -> s { stUnits = stUnits s ++ [ue] }

nextCounter :: AlgM Int
nextCounter = do
  k <- gets stCounter
  modify $ \s -> s { stCounter = k + 1 }
  return k

-- ELECTRONS(p, Units): all units with position q ≺ p.
-- Unnamed (derived) units come before named (axiom) units — they tend to be more
-- specific and match body literals directly, so trying them first avoids picking
-- a generic axiom that only works after additional rewriting.
getElectrons :: String -> AlgM [UnitEntry]
getElectrons p = gets (\s ->
  let available = filter (\ue -> case uePos ue of { Just q -> q < p; Nothing -> False }) (stUnits s)
      unnamed   = filter (isNothing . ueName) available
      named     = filter (isJust    . ueName) available
  in unnamed ++ named)

-- ENSURE_NAMED: return the name of a unit, promoting it to a lemma if unnamed.
ensureNamed :: Literal -> AlgM String
ensureNamed lit = do
  units <- gets stUnits
  case find (\u -> ueUnit u == lit) units of
    Just ue ->
      case ueName ue of
        Just name -> return name
        Nothing   ->
          case ueProof ue of
            Just blk -> promoteToLemma lit blk
            Nothing  -> error ("ensureNamed: unnamed unit has no proof: " ++ show lit)
    Nothing -> error ("ensureNamed: unit not found: " ++ show lit)

promoteToLemma :: Literal -> ProofBlock -> AlgM String
promoteToLemma lit blk = do
  k <- nextCounter
  let name = "lemma " ++ show k
  modify $ \s -> s
    { stLemmas = stLemmas s ++ [(name, lit, blk)]
    , stUnits  = map (promote name) (stUnits s)
    }
  return name
  where
    promote name u
      | ueUnit u == lit && isNothing (ueName u) =
          u { ueName = Just name, ueProof = Nothing }
      | otherwise = u

-- MATCH: for each body literal find an electron and substitutions (σ0, σi) such
-- that K_i[σ_i] rewrites to L_i[σ0].  Returns Nothing on failure.
matchBody :: String -> [Literal] -> [UnitEntry] -> AlgM (Maybe (Subst, [(UnitEntry, Subst, Literal)]))
matchBody pos bodyLits electrons = go bodyLits [] []
  where
    go [] σ0 acc = return $ Just (σ0, reverse acc)
    go (li:rest) σ0 acc = do
      mElec <- findElec (applySubst σ0 li) σ0
      case mElec of
        Just (ue, σi, σ0') -> go rest σ0' ((ue, σi, applySubst σ0' li) : acc)
        Nothing            -> return Nothing

    findElec li' σ0 = case direct li' σ0 electrons of
      Just res -> return (Just res)
      Nothing  -> do
        let symbolic = not (null (litVars li'))
        r1 <- if symbolic then eqChainFallback li' σ0 else eqRwFallback li' σ0
        case r1 of
          Just _  -> return r1
          Nothing -> do
            r2 <- if symbolic then eqRwFallback li' σ0 else eqChainFallback li' σ0
            case r2 of
              Just _  -> return r2
              Nothing -> relFallback li' σ0

    direct _   _   []       = Nothing
    direct li' σ0 (ue:ues) =
      case tryMatch li' (ueUnit ue) σ0 of
        Just (σi, σ0') -> Just (ue, σi, σ0')
        Nothing        -> direct li' σ0 ues

    -- Build an EqChain unit from the rewrite path to the body literal.
    eqChainFallback (Eq l r) σ0 = do
      units <- gets stUnits
      (cur, steps) <- rwChainToTerm l r units
      if cur /= r || null steps
        then return Nothing
        else do
          let proof = EqChain l steps
              ue    = UnitEntry Nothing (Eq l r) (Just proof) (Just pos)
          addUnit ue
          return $ Just (ue, [], σ0)
    eqChainFallback _ _ = return Nothing

    -- Find an equational electron that can be rewritten to reach the body literal.
    -- Uses a pure (side-effect-free) exploration to rank candidates by chain length.
    eqRwFallback li'@(Eq _ _) σ0 = do
      allUnits <- gets stUnits
      let targets  = [li', flipLit li']
          eqUnits  = filter (isEqLit . ueUnit) allUnits
          ordered  = filter (isNothing . ueName) eqUnits
                  ++ filter (not . isNothing . ueName) eqUnits
          hits     = [ (ue, n)
                     | ue <- ordered
                     , let (cur, n) = rwChainToLitPure (ueUnit ue) li' allUnits
                     , cur `elem` targets ]
      case sortBy (comparing snd) hits of
        []           -> return Nothing
        (ue, _) : _ -> return $ Just (ue, [], σ0)
      where
        isEqLit (Eq _ _) = True
        isEqLit _        = False
    eqRwFallback _ _ = return Nothing

    -- For relational body literals: find an electron with the same predicate
    -- that can be rewritten (or matched after rewriting) to the target.
    relFallback li'@(Rel _ _) σ0 = do
      units <- gets stUnits
      tryElecs units units
      where
        tryElecs [] _ = return Nothing
        tryElecs (ue:rest) allUnits
          | samePred (ueUnit ue) li' = do
              (cur, _) <- rwChainToLit (ueUnit ue) li' allUnits
              if cur == li'
                then return $ Just (ue, [], σ0)
                else case matchLit cur li' of
                  Just σi -> return $ Just (ue, σi, σ0)
                  Nothing -> tryElecs rest allUnits
          | otherwise = tryElecs rest allUnits
        samePred (Rel n1 _) (Rel n2 _) = n1 == n2
        samePred _ _ = False
    relFallback _ _ = return Nothing

-- One-way matching: body literal li against electron ki.
-- 1. Try li as pattern against ki → extends σ0 with nucleus-var bindings.
-- 2. Try ki as pattern against li → gives σi (electron-var bindings); σ0 unchanged.
-- Both directions also try flipped equality (Eq is symmetric).
-- Intentionally no unification — binding nucleus and electron vars simultaneously
-- causes naming-collision bugs.
tryMatch :: Literal -> Literal -> Subst -> Maybe (Subst, Subst)
tryMatch li ki σ0 =
  tryAsPattern li ki
  <|> tryAsPattern (flipEq li) ki
  <|> tryKiPattern ki
  <|> tryKiPattern (flipEq ki)
  <|> tryKiPattern ki `againstFlip` li
  <|> tryBothSides li ki
  <|> tryBothSides (flipEq li) ki
  where
    tryAsPattern li_form k = case matchLit li_form k of
      Just σ_new -> case extendSubst σ0 σ_new of
        Just σ0' -> Just ([], σ0')
        Nothing  -> Nothing
      Nothing -> Nothing
    tryKiPattern k = case matchLit k li of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    againstFlip m li_form = m <|> case matchLit ki (flipEq li_form) of
      Just σi -> Just (σi, σ0)
      Nothing -> Nothing
    -- Bidirectional: nucleus vars (in li_form) → σ0, electron vars (in ki) → σi.
    -- Compose σi into σ0' before the consistency check to handle shared variable names.
    tryBothSides li_form k = case matchBothLit li_form k σ0 [] of
      Just (σ0', σi) ->
        let σ0composed = [(x, applySubstTerm σi t) | (x, t) <- σ0']
        in if applySubst σ0composed li_form == applySubst σi k
           then Just (σi, σ0composed)
           else Nothing
      _ -> Nothing
    flipEq (Eq l r) = Eq r l
    flipEq x        = x

-- RW_CHAIN_TO (literal version): pure exploration pass with no side effects,
-- used only for ranking candidate electrons. Returns (final literal, step count).
rwChainToLitPure :: Literal -> Literal -> [UnitEntry] -> (Literal, Int)
rwChainToLitPure s t units
  | s == t         = (s, 0)
  | flipLit s == t = (t, 0)
  | otherwise      = go s 0 (Set.singleton s)
  where
    go cur n seen
      | cur == t || flipLit cur == t = (t, n)
      | otherwise =
          case findRwStep cur seen of
            Nothing              -> (cur, n)
            Just (_, _, cur', _) -> go cur' (n+1) (Set.insert cur' seen)

    findRwStep cur seen = listToMaybe (sortCandidates candidates)
      where
        candidates =
          [ (ue, (l, r), cur', dir)
          | ue <- units
          , Eq l r <- [ueUnit ue]
          , (dir, cur') <- litDirs l r cur
          , Set.notMember cur' seen
          ]
        sortCandidates cs =
          filter (\(_,_,c,_) -> c == t || flipLit c == t) cs ++
          sortBy (comparing (\(_,_,c,_) -> litSize c))
                 (filter (\(_,_,c,_) -> c /= t && flipLit c /= t && litSize c <= litSize cur) cs) ++
          sortBy (comparing (\(_,_,c,_) -> litSize c))
                 (filter (\(_,_,c,_) -> c /= t && flipLit c /= t && litSize c > litSize cur) cs)

    litDirs l r cur =
      [(LR, c) | Just c <- [rewriteLit cur (l,r) LR]] ++
      [(RL, c) | Just c <- [rewriteLit cur (l,r) RL]]

-- RW_CHAIN_TO (literal version, with side effects): calls ensureNamed at each step
-- so intermediate equations are promoted to lemmas as needed.
rwChainToLit :: Literal -> Literal -> [UnitEntry] -> AlgM (Literal, [(RwStep, Literal)])
rwChainToLit s t units
  | s == t          = return (s, [])
  | flipLit s == t  = return (t, [])
  | otherwise = go s [] (Set.singleton s)
  where
    go cur steps seen =
      case findRwStep cur seen of
        Nothing              -> return (cur, reverse steps)
        Just (ue, eq, cur', dir)
          | cur' == t || flipLit cur' == t -> do
              name <- ensureNamed (ueUnit ue)
              return (t, reverse ((RwStep name eq dir, cur') : steps))
          | otherwise -> do
              name <- ensureNamed (ueUnit ue)
              go cur' ((RwStep name eq dir, cur') : steps) (Set.insert cur' seen)

    findRwStep cur seen = listToMaybe (sortCandidates candidates)
      where
        candidates =
          [ (ue, (l, r), cur', dir)
          | ue <- units
          , Eq l r <- [ueUnit ue]
          , (dir, cur') <- litDirs l r cur
          , Set.notMember cur' seen
          ]
        sortCandidates cs =
          filter (\(_,_,c,_) -> c == t || flipLit c == t) cs ++
          sortBy (comparing (\(_,_,c,_) -> litSize c))
                 (filter (\(_,_,c,_) -> c /= t && flipLit c /= t && litSize c <= litSize cur) cs) ++
          sortBy (comparing (\(_,_,c,_) -> litSize c))
                 (filter (\(_,_,c,_) -> c /= t && flipLit c /= t && litSize c > litSize cur) cs)

    litDirs l r cur =
      [(LR, c) | Just c <- [rewriteLit cur (l,r) LR]] ++
      [(RL, c) | Just c <- [rewriteLit cur (l,r) RL]]

-- RW_CHAIN_TO (term version): used in Phase 2 for equational goal proofs.
-- The step limit prevents divergence when only size-increasing rules are available.
rwChainToTerm :: Term -> Term -> [UnitEntry] -> AlgM (Term, [(RwStep, Term)])
rwChainToTerm s t units
  | s == t    = return (s, [])
  | otherwise = go s [] (Set.singleton s) (0 :: Int)
  where
    maxSteps = 30

    go cur steps seen n
      | cur == t  = return (cur, reverse steps)
      | n >= maxSteps = return (cur, reverse steps)
      | otherwise =
          case findRwStep cur seen of
            Nothing              -> return (cur, reverse steps)
            Just (ue, eq, cur', dir) -> do
              name <- ensureNamed (ueUnit ue)
              go cur' ((RwStep name eq dir, cur') : steps) (Set.insert cur' seen) (n+1)

    findRwStep cur seen = listToMaybe (sortCandidates candidates)
      where
        candidates =
          [ (ue, (l, r), cur', dir)
          | ue <- units
          , Eq l r <- [ueUnit ue]
          , (dir, cur') <- termDirs l r cur
          , Set.notMember cur' seen
          ]
        -- Exact target first; then size-non-increasing; then size-increasing as last resort.
        sortCandidates cs =
          filter (\(_,_,c,_) -> c == t) cs ++
          sortBy (comparing (\(_,_,c,_) -> termSize c))
                 (filter (\(_,_,c,_) -> c /= t && termSize c <= termSize cur) cs) ++
          sortBy (comparing (\(_,_,c,_) -> termSize c))
                 (filter (\(_,_,c,_) -> c /= t && termSize c > termSize cur) cs)

    termDirs l r cur =
      [(LR, c) | c <- rewriteTermAll cur (l,r) LR] ++
      [(RL, c) | c <- rewriteTermAll cur (l,r) RL]

-- MAKE_BLOCK: build the proof block for an electron K with substitution σ and
-- a list of rewrite steps leading from K[σ] to the target body literal.
makeBlock :: UnitEntry -> Subst -> [(RwStep, Literal)] -> AlgM ProofBlock
makeBlock electronUe σi rwSteps = do
  units <- gets stUnits
  b     <- buildBase units
  foldM extendStep b rwSteps
  where
    lit = ueUnit electronUe

    buildBase units =
      case find (\u -> ueUnit u == lit && isNothing (ueName u)) units of
        Just unnamed ->
          case ueProof unnamed of
            Just stored
              | isEqChain stored -> do
                  -- An EqChain proof cannot be inlined inside a HaveHence block
                  -- (only names can be cited), so we promote it to a lemma first.
                  name <- ensureNamed lit
                  return $ HaveHence [Have (applySubst σi lit) name]
              | otherwise ->
                  return $ applySubstBlock σi stored
            _ -> namedCase units
        Nothing -> namedCase units

    namedCase units =
      case find (\u -> ueUnit u == lit) units of
        Just u  ->
          let name = fromMaybe (error ("makeBlock: unnamed unit: " ++ show lit)) (ueName u)
          in return $ HaveHence [Have (applySubst σi lit) name]
        Nothing -> error ("makeBlock: electron not found in Units: " ++ show lit)

    extendStep b (rw, cur) =
      return $ appendLine b (Hence cur (ByRw (rwName rw) (dirFlag (rwDir rw))))

    dirFlag LR = Nothing
    dirFlag RL = Just RL

processNonUnit
  :: String
  -> Maybe String  -- axiom name (Nothing for negated conjecture)
  -> Clause
  -> Literal       -- goal literal
  -> AlgM Bool     -- True when a goal was emitted
processNonUnit pos mAxiomName (Clause bodyLits mHead) goalLit = do
  elecs <- getElectrons pos
  mMatch <- matchBody pos bodyLits elecs
  case mMatch of
    Nothing -> return False
    Just (σ0, matched) ->
      case mHead of
        Nothing ->
          -- L0 = ⊥: electrons directly prove the goal.
          -- If the single electron has an unnamed EqChain proof, emit it directly
          -- rather than wrapping it in "have X by lemma N".
          case matched of
            [(elecUe, σi, _)]
              | isNothing (ueName elecUe)
              , Just chain@(EqChain {}) <- ueProof elecUe ->
                  emitGoalProof goalLit (applySubstBlock σi chain) >> return True
            _ -> do
              blk <- buildElectronBlock σ0 matched
              emitGoalProof goalLit blk >> return True
        Just l0 -> do
          blk <- buildElectronBlock σ0 matched
          let l0σ0   = applySubst σ0 l0
              axName = fromMaybe (error "processNonUnit: no axiom name") mAxiomName
              blk1   = appendLine blk (Hence l0σ0 (ByAxiom axName))
          -- If l0σ0 matches the goal via variable instantiation (ρ0), emit directly.
          -- Calling rwChainToLit on a symbolic l0σ0 would diverge.
          case matchLit l0σ0 goalLit <|> matchLit (flipLit l0σ0) goalLit of
            Just ρ0 ->
              emitGoalProof goalLit (applySubstBlock ρ0 blk1) >> return True
            Nothing -> do
              units' <- gets stUnits
              (cur, rwSteps) <- rwChainToLit l0σ0 goalLit units'
              let blk2 = foldl addRwLine blk1 rwSteps
              if cur == goalLit
                then emitGoalProof goalLit blk2 >> return True
                else
                  let mρ0 = matchLit cur goalLit <|> matchLit (flipLit cur) goalLit
                  in case mρ0 of
                    Just ρ0 ->
                      emitGoalProof goalLit (applySubstBlock ρ0 blk2) >> return True
                    Nothing -> do
                      addUnit (UnitEntry Nothing l0σ0 (Just blk1) (Just pos))
                      return False
  where
    addRwLine b (rw, c) =
      appendLine b (Hence c (ByRw (rwName rw) (dirFlag (rwDir rw))))
    dirFlag LR = Nothing
    dirFlag RL = Just RL

emitGoalProof :: Literal -> ProofBlock -> AlgM ()
emitGoalProof lit blk = modify $ \s -> s { stGoals = stGoals s ++ [(lit, blk)] }

-- Build the combined proof block from all matched electrons.
-- The first electron becomes the "have" base; subsequent ones become "and" lines
-- (with forced lemmatization if the target is unnamed).
buildElectronBlock :: Subst -> [(UnitEntry, Subst, Literal)] -> AlgM ProofBlock
buildElectronBlock _ [] = error "buildElectronBlock: empty electron list"
buildElectronBlock _σ0 ((k1, σ1, target1):rest) = do
  units <- gets stUnits
  (_, rw1) <- rwChainToLit (applySubst σ1 (ueUnit k1)) target1 units
  blk0 <- makeBlock k1 σ1 rw1
  foldM addAndLine blk0 rest
  where
    addAndLine blk (ki, σi, targeti) = do
      units <- gets stUnits
      (_, rwi) <- rwChainToLit (applySubst σi (ueUnit ki)) targeti units
      nameI <- nameForAnd targeti ki σi rwi
      return $ appendLine blk (And targeti nameI)

    nameForAnd targeti ki σi rwi = do
      units <- gets stUnits
      case find (\u -> ueUnit u == targeti) units of
        Just ue | isNothing (ueName ue) -> do
          subBlk <- makeBlock ki σi rwi
          promoteToLemma targeti subBlk
        Just ue ->
          return $ fromMaybe (error "nameForAnd: unit has nil name") (ueName ue)
        Nothing -> do
          subBlk <- makeBlock ki σi rwi
          k <- nextCounter
          let nm = "lemma " ++ show k
          modify $ \s -> s { stLemmas = stLemmas s ++ [(nm, targeti, subBlk)] }
          addUnit (UnitEntry (Just nm) targeti Nothing Nothing)
          return nm

-- Phase 2: NonUnits is empty — prove each goal conjunct directly from the unit set.
runPhase2 :: Literal -> AlgM ()
runPhase2 goal = do
  units <- gets stUnits
  case findUnitForGoal goal units of
    Just (ue, σ) -> do
      units' <- gets stUnits
      (_, rw) <- rwChainToLit (applySubst σ (ueUnit ue)) goal units'
      blk <- makeBlock ue σ rw
      emitGoalProof goal blk
    Nothing ->
      case goal of
        Eq s t -> do
          units' <- gets stUnits
          (_, steps) <- rwChainToTerm s t units'
          emitGoalProof goal (EqChain s steps)
        _ -> error ("runPhase2: no unit matches relational goal: " ++ show goal)

findUnitForGoal :: Literal -> [UnitEntry] -> Maybe (UnitEntry, Subst)
findUnitForGoal goal units = listToMaybe
  [ (ue, σ)
  | ue <- units
  , Just σ <- [matchLit (ueUnit ue) goal]
  ]

-- Try to prove an equational goal directly via a named-equation-only rewrite chain.
-- Used as a Phase-2-style shortcut inside Phase 3 when the negated conjecture has
-- a single equational body literal and no electrons are needed.
tryEqChainGoal :: Term -> Term -> Literal -> AlgM Bool
tryEqChainGoal s t goalLit = do
  allUnits <- gets stUnits
  let namedEqs = [ue | ue <- allUnits, isJust (ueName ue), isEqLit (ueUnit ue)]
      (lhs, rhs) = case goalLit of { Eq gl gr -> (gl, gr); _ -> (s, t) }
  (cur, steps) <- rwChainToTerm lhs rhs namedEqs
  if cur == rhs
    then emitGoalProof goalLit (EqChain lhs steps) >> return True
    else return False
  where
    isEqLit (Eq _ _) = True
    isEqLit _        = False

-- Phase 3 loop: process non-unit clauses until all goals are emitted.
runPhase3
  :: [(String, String, T.Declaration)]
  -> Map.Map String String
  -> [Literal]
  -> AlgM ()
runPhase3 nonUnits posToName goalLits = go nonUnits
  where
    nGoals  = length goalLits
    goalLit = head goalLits

    go [] = return ()
    go ((pos, _, decl):rest) = do
      nDone <- gets (length . stGoals)
      if nDone >= nGoals then return ()
      else case convertDeclToClause decl of
        Nothing  -> error ("runPhase3: cannot convert non-unit clause at position "
                        ++ pos ++ ": " ++ show decl)
        Just cls -> do
          let mAxiomName = Map.lookup pos posToName
          eqDone <- case cls of
            Clause [Eq s t] Nothing | isNothing mAxiomName ->
              tryEqChainGoal s t goalLit
            Clause _ Nothing | isNothing mAxiomName, nGoals > 1 ->
              tryAllEqChain goalLits
            _ -> return False
          if eqDone then return ()
          else do
            finished <- processNonUnit pos mAxiomName cls goalLit
            if finished then return () else go rest

-- For conjunctive conjectures: prove each goal conjunct independently via EqChain.
tryAllEqChain :: [Literal] -> AlgM Bool
tryAllEqChain goalLits = do
  results <- mapM tryOne goalLits
  return (and results)
  where
    tryOne glit = case glit of
      Eq lhs rhs -> do
        allUnits <- gets stUnits
        let namedEqs = [ue | ue <- allUnits, isJust (ueName ue), isEqLit (ueUnit ue)]
        (cur, steps) <- rwChainToTerm lhs rhs namedEqs
        if cur == rhs
          then emitGoalProof glit (EqChain lhs steps) >> return True
          else return False
      _ -> return False
    isEqLit (Eq _ _) = True
    isEqLit _        = False

runAlgorithm
  :: [UnitEntry]
  -> [(String, String, T.Declaration)]
  -> [Literal]
  -> StructuredProof
runAlgorithm initUnits nonUnits goalLits =
  let (axiomList, posToName, namedUnits) = assignAxiomNames initUnits nonUnits
      initSt = AlgState
        { stUnits   = namedUnits
        , stLemmas  = []
        , stGoals   = []
        , stCounter = length axiomList + 1
        }
      action
        | null nonUnits = mapM_ runPhase2 goalLits
        | otherwise     = runPhase3 nonUnits posToName goalLits
      finalSt = execState action initSt
  in if null (stGoals finalSt)
     then error "translate: algorithm terminated without producing a goal proof"
     else StructuredProof axiomList (stLemmas finalSt) (stGoals finalSt)
