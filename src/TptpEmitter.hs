-- Prints the structured proof as a TPTP derivation for GDV. The input units
-- and the Skolem definitions a prover left out come first, then the
-- hypotheses as assumptions, the clausified axioms and the proof steps. The
-- conjecture is the final theorem and discharges the assumptions.
module TptpEmitter (emitTptp) where

import Control.Monad (foldM, guard)
import Data.Char (isDigit)
import Data.Foldable (toList)
import Data.List.NonEmpty (nonEmpty)
import Data.List (intercalate, isPrefixOf, nub, nubBy, sortOn, tails, union)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe, isJust, isNothing, listToMaybe, mapMaybe, maybeToList)
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import Types
import Helpers
import Emitter (axiomRenaming, blockRenaming, dropUnusedAndNumber)
import TptpConvert (convertDeclToClause, convertLit, declSymbols, isFileSourced, splitAtClosing, topLevelArgs, tptpLitVars, tptpLiteral, tptpSymbol, unitNameOf, unitNameStr, unitParents)

-- One line of the derivation. An input unit is printed as read, with the
-- new_symbols info it needs. A step has a role, a rule and its parents.
data Line
  = Input T.Unit String
  | Assume String Formula
  | Step String String Formula String [String]

-- Our literal or clause, the conjecture as read, or text built from printed
-- parts.
data Formula = LitFormula Literal | ClauseFormula Clause | Verbatim T.Formula | Raw String

-- The proof as a TPTP derivation between SZS markers, typed when the problem is.
emitTptp :: StructuredProof -> String
emitTptp sp0 = unlines $
     ["% SZS output start Proof"]
  ++ typeLines
  ++ map (ppLine env deps) allLines
  ++ ["% SZS output end Proof"]
  where
    spNumbered   = dropUnusedAndNumber sp0
    input = spInput spNumbered
    -- A typed problem gives a typed proof. Type declarations come first,
    -- input units are printed in their typed form, and each variable gets
    -- the sort of its argument position.
    typing    = inTyped input
    env       | null typing = Nothing
              | otherwise   = Just (Map.fromList [ (Text.unpack a, (map sortName as, sortName r))
                                                 | T.Unit _ (T.Typing (T.Atom a) (T.Type as r)) _ <- typing ])
    typeLines = [ show (pretty u) | u@(T.Unit _ d _) <- typing, isTypeDecl d ]
    isTypeDecl (T.Typing _ _) = True
    isTypeDecl (T.Sort _ _)   = True
    isTypeDecl _              = False
    typedUnit u = fromMaybe u (Map.lookup (unitNameStr (unitName u)) typedByName)
    typedByName = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n (T.Formula _ _) _) <- typing ]
    used  = Set.fromList (map (unitNameStr . unitName) (Map.elems (inAxiomUnits input))
                          ++ Map.elems (inHypotheses input)
                          ++ maybeToList (fmap (unitNameStr . unitName) (inConjecture input)))
    fresh n = if Set.member n used then "taelja_" ++ n else n

    -- An axiom whose clause matches its input unit is cited by that unit's
    -- name. A hypothesis is an assumption named after its clause's unit. Any
    -- other axiom keeps a name of its own.
    hyps     = Map.keysSet (inHypotheses input)
    axNames  = map axiomName (axioms spNumbered)
    assumed  = [ (n, c) | n <- axNames, Just c <- [Map.lookup n (inHypotheses input)] ]
    -- an axiom with no recorded unit is found by its clause among the input
    -- units
    inputOf n = fmap canonical $ case Map.lookup n (inAxiomUnits input) of
      Just u  -> Just u
      Nothing -> listToMaybe [ u | u <- inUnits input, isInputUnit u, sameAsInput u n ]
    -- a unit that only copies its one parent, as E's renamed file clauses
    -- do, stands for that parent
    canonical u = case unitParents u of
      [p] | Just pu <- Map.lookup p byName
          , Just c1 <- convertDeclToClause (unitDecl u)
          , Just c2 <- convertDeclToClause (unitDecl pu)
          , variantClause c1 c2 -> canonical pu
      _ -> u
    axTarget n
      | Just a <- lookup n assumed = a
      | Just u <- inputOf n, sameAsInput u n = unitNameStr (unitName u)
      | otherwise = fresh (tptpName n)
    sameAsInput u n = case (axiomOf n, convertDeclToClause (unitDecl u)) of
      (Just a, Just c) -> variantClause (axiomClause a) c
      _                -> False
    axiomOf n = lookup n [ (axiomName a, a) | a <- axioms spNumbered ]
    lemmaTarget n = fresh (tptpName n)
    -- A goal variable that replaced a Skolem term is that term again, since
    -- a TPTP step cannot hold a fixed variable. The final theorem generalizes
    -- over it.
    restoreSkolems = inGeneralized input
    restoreSkolemsLit  = mapLiteralTerms (subVars restoreSkolems)
    subVars s (Var v)    = fromMaybe (Var v) (lookup v s)
    subVars s (App f ts) = App f (map (subVars s) ts)
    subVars _ t          = t
    sp  = renameCitations (Map.fromList ([ (n, axTarget n) | n <- axNames ]
                                       ++ [ (n, lemmaTarget n) | (n, _, _) <- lemmas spNumbered ])) spNumbered
    axiomVarNames = axiomRenaming (axioms spNumbered)

    -- The input units behind the axioms and the prover's definitions, each
    -- with its ancestors, in the prover's order so parents come first.
    inputLines = map (\(_, u) -> Input (typedUnit u) (newSymbols u)) $ sortOn (unitIndex . fst) $ nubBy (\a b -> fst a == fst b) $ concat
      [ withParents u | n <- axNames, not (Set.member n hyps), Just u <- [inputOf n] ]
      ++ concat [ withParents d | n <- axNames, dn <- definitionsBehind n, Just d <- [Map.lookup dn byName] ]
      ++ concat [ withParents d | d <- proverSkolemDefs ]
    -- the prover's own definitions of the goals' Skolem symbols, which the
    -- generalization step cites
    proverSkolemDefs =
      [ u | u@(T.Unit _ d (Just (T.Introduced _ _, _))) <- inUnits input
          , let (fs, _) = declSymbols d
          , any (`elem` (generalizedSyms ++ goalSkolems)) [ s | s <- fs, Set.notMember s fileSyms ] ]
    -- The fresh symbols the theorem generalizes over. They come from the
    -- generalized terms, and from the goals and hypotheses when the problem
    -- and the other axioms do not mention them.
    generalizedSyms = nub $
      [ s | s <- concatMap (termSymbols . snd) (inGeneralized input), Set.notMember s fileSyms ]
      ++ [ s | s <- concatMap (litSymbols . fst) (goals spNumbered)
                    ++ concat [ axSyms ax | ax <- axioms spNumbered, isJust (lookup (axiomName ax) assumed) ]
             , Set.notMember s fileSyms
             , s `notElem` concat [ axSyms ax | ax <- axioms spNumbered, isNothing (lookup (axiomName ax) assumed) ] ]
    -- the symbols of the units read from the problem file
    fileSyms = let ps = [ declSymbols d | u@(T.Unit _ d _) <- inUnits input, isFileSourced u ]
               in Set.fromList (concatMap fst ps ++ concatMap snd ps)
    unitIndex n = fromMaybe maxBound (Map.lookup n unitOrder)
    unitOrder = Map.fromList (zip [ unitNameStr (unitName u) | u <- inUnits input ] [0 :: Int ..])
    -- GDV wants a definition to list its new symbols in new_symbols(...),
    -- which E and Vampire leave out. A symbol is new in the first definition
    -- that mentions it, unless the problem has it.
    newSymbols u = case u of
      T.Unit n d (Just (T.Introduced _ _, _)) ->
        let (fs, ps) = declSymbols d
            earlier = Set.fromList $ concat
              [ let (fs', ps') = declSymbols d' in fs' ++ ps'
              | T.Unit n' d' (Just (T.Introduced _ _, _)) <- inUnits input
              , unitIndex (unitNameStr n') < unitIndex (unitNameStr n) ]
            isNew s = Set.notMember s fileSyms && Set.notMember s earlier
        in newSymbolsInfo (nub (filter isNew (fs ++ ps)))
      _ -> ""
    -- the prover's definitions between an axiom's input unit and its clause,
    -- such as Vampire's Skolem definitions, which the clausify step cites
    definitionsBehind n =
      nub [ unitNameStr (unitName u) | u@(T.Unit _ _ (Just (T.Introduced _ _, _))) <- unitsBehind n ]
    -- the prover's units between an axiom's input unit and its clause, with
    -- the definitions they cite
    unitsBehind n = maybe [] (\leaf -> walk Set.empty [leaf]) (Map.lookup n (inAxiomLeaves input))
      where
        walk _ [] = []
        walk seen (x : xs)
          | Set.member x seen = walk seen xs
          | otherwise = case Map.lookup x byName of
              Just u | not (isFileSourced u) -> u : walk (Set.insert x seen) (unitParents u ++ xs)
              _ -> walk (Set.insert x seen) xs
    byName = Map.fromList [ (unitNameStr (unitName u), u) | u <- inUnits input ]
    -- E and Twee Skolemize some axioms without defining the new symbols, so
    -- the clause does not follow from the axiom alone. For each Skolemizing
    -- step S behind an axiom A we print the definition A => S, which every
    -- model of A satisfies for some choice of the new symbols.
    skolemStepsBehind n = case inputOf n of
      Just root -> [ (root, u) | u <- unitsBehind n, esaStep u, not (null (skolemSyms u)) ]
      Nothing   -> []
    esaStep (T.Unit _ _ (Just (src, _))) = hasEsa src
    esaStep _ = False
    hasEsa (T.Inference _ infos ps) = any isEsa infos || or [ hasEsa src | T.Parent src _ <- ps ]
    hasEsa _ = False
    isEsa (T.Status (T.Standard T.ESA)) = True
    isEsa _                             = False
    -- the function symbols a step brings in, absent from its parents, the
    -- problem and the prover's definitions
    skolemSyms u =
      let parentSyms = concat [ fst (declSymbols (unitDecl p)) | pn <- unitParents u, Just p <- [Map.lookup pn byName] ]
      in nub [ f | f <- fst (declSymbols (unitDecl u)), Set.notMember f fileSyms
                 , f `notElem` parentSyms, Set.notMember f definedSyms ]
    axiomSkolemDef root u = do
      f <- case (unitDecl root, unitDecl u) of
             (T.Formula _ (T.FOF a), T.Formula _ (T.FOF b))   -> Just (T.FOF (T.Connected a T.Implication b))
             (T.Formula _ (T.TFF0 a), T.Formula _ (T.TFF0 b)) -> Just (T.TFF0 (T.Connected a T.Implication b))
             _                                                -> Nothing
      let nm = fresh ("skolem_" ++ unitNameStr (unitName u))
      return (nm, Input (T.Unit (unitNameOf nm) (T.Formula (T.Standard T.Plain) f)
                                (Just (T.Introduced (T.Standard T.ByDefinition) Nothing, Nothing)))
                        (newSymbolsInfo (skolemSyms u)))
    -- A symbol may be declared new only once, and a prover may Skolemize the
    -- same axiom twice, so a later step cites the definition already printed.
    skolemChosen = pick Set.empty [ p | n <- axNames, isNothing (lookup n assumed), p <- skolemStepsBehind n ]
      where
        pick _ [] = []
        pick seen ((root, u) : rest)
          | any (`Set.notMember` seen) (skolemSyms u)
          , Just (nm, line) <- axiomSkolemDef root u
          = (unitNameStr (unitName u), nm, Just line) : pick (foldr Set.insert seen (skolemSyms u)) rest
          | Just nm <- lookup (Set.fromList (skolemSyms u)) declaredBy
          = (unitNameStr (unitName u), nm, Nothing) : pick seen rest
          | otherwise = pick seen rest
        declaredBy = [ (Set.fromList (skolemSyms u), nm)
                     | (root, u) <- [ p | n <- axNames, isNothing (lookup n assumed), p <- skolemStepsBehind n ]
                     , Just (nm, _) <- [axiomSkolemDef root u] ]
    skolemDefsBehind n =
      nub [ (nm, ()) | (un, nm, _) <- skolemChosen
                     , un `elem` map (unitNameStr . unitName . snd) (skolemStepsBehind n) ]
    skolemAxLines = [ (nm, line) | (_, nm, Just line) <- skolemChosen ]
    withParents u = concat [ withParents p | n <- unitParents u, Just p <- [Map.lookup n byName] ]
                    ++ [(unitNameStr (unitName u), u)]
    axiomLines = concat
      [ case (lookup n assumed, inputOf n) of
          (Just a, _) -> [Assume a (axiomFormula ax)]
          (Nothing, Just u)
            | sameAsInput u n -> []
            | otherwise ->
                [Step (axTarget n) "plain" (axiomFormula ax) "clausify"
                      (unitNameStr (unitName u) : definitionsBehind n ++ map fst (skolemDefsBehind n))]
          (Nothing, Nothing) -> [Step (axTarget n) "axiom" (axiomFormula ax) "" []]
      | n <- axNames, Just ax <- [axiomOf n] ]
    axiomFormula (AUnit _ l)    = LitFormula (renameLit axiomVarNames (restoreSkolemsLit l))
    axiomFormula (ANucleus _ (Clause bs mh)) =
      ClauseFormula (Clause (map (renameLit axiomVarNames . restoreSkolemsLit) bs) (fmap (renameLit axiomVarNames . restoreSkolemsLit) mh))

    -- the unit axioms and lemmas a have or and line may merely restate
    facts = [ (axTarget n, l) | AUnit n l <- axioms spNumbered ]
         ++ [ (lemmaTarget n, l) | (n, l, _) <- lemmas spNumbered ]

    -- a goal is an ordinary numbered step when a separate theorem line
    -- concludes from it
    blocks = [ (Just n, "lemma", lit, blk) | (n, lit, blk) <- lemmas sp ]
          ++ [ (goalName i, goalRole, lit, blk) | (i, (lit, blk)) <- zip [1 :: Int ..] (goals sp) ]
    goalName i | goalRole == "plain" = Nothing
               | otherwise           = Just (fresh ("goal_" ++ show i))
    conj      = inConjecture input
    conjName  = maybe "goal" (unitNameStr . unitName) conj
    conjAtom  = conj >>= conjLiteral . unitDecl
    -- When the only goal is the conjecture and there are no hypotheses, its
    -- last step is the theorem. A goal over fresh symbols is not, since its
    -- parents mention them, so it goes through the generalization below.
    merged = case (goals sp, conjAtom) of
      ([(g, _)], Just c) -> null assumed && variantLit g c && not (null stepLines)
                            && null generalizedSyms && null conjSkolems
      _                  -> False
    goalRole | isJust conj && not merged = "plain"
             | otherwise                 = "theorem"
    blockResults = go 1 blocks
    go _ [] = []
    go k ((name, role, lit, blk) : rest) =
      let (k', steps, final) = blockSteps fresh facts k name role (restoreSkolemsLit lit) (restoreSkolemsBlock blk)
      in (steps, final) : go k' rest
    restoreSkolemsBlock = mapShownTerms (subVars restoreSkolems)
    stepLines  = concatMap fst blockResults
    goalFinals = map snd (drop (length (lemmas sp)) blockResults)
    theoremLine = case conj of
      Just u | merged -> [ asTheorem (Verbatim (unitFormula (typedUnit u))) conjName (last stepLines) ]
      Just u
        | null generalizedSyms, null conjSkolems ->
            [ Step conjName "theorem" (Verbatim (unitFormula (typedUnit u)))
                   (if null assumed then "conclude" else "implies")
                   (goalFinals ++ map snd assumed) ]
        -- the discharged formula mentions the fresh symbols, and their
        -- definitions justify generalizing it to the conjecture
        | otherwise ->
            [ Step (fresh "discharged") "plain" (Raw dischargedText)
                   (if null assumed then "conclude" else "implies")
                   (goalFinals ++ map snd assumed)
            , Step conjName "theorem" (Verbatim (unitFormula (typedUnit u))) "generalization"
                   (fresh "discharged" : [ unitNameStr (unitName d) | d <- conjSkolemDefs ]
                    ++ [ unitNameStr (unitName d) | d <- proverSkolemDefs ]) ]
      Nothing -> []
    -- E and Twee do not define the Skolem symbols of the negated conjecture,
    -- so we print their definitions, as Vampire prints its own
    undefinedSkolems = nub (conjSkolems ++ [ f | f <- generalizedSyms, Set.notMember f definedSyms ])
    conjSkolemDefs = case conj of
      Just u | not (null undefinedSkolems) ->
        skolemDefinition fresh (typedUnit u) undefinedSkolems
          (map restoreSkolemsLit ([ l | (l, _) <- goals spNumbered ] ++ [ l | ax@(AUnit _ l) <- axioms spNumbered, isJust (lookup (axiomName ax) assumed) ]))
      _ -> []
    skolemDefLines = [ Input d (newSymbolsInfo [ f | f <- undefinedSkolems, f `elem` fst (declSymbols (unitDecl d)) ])
                     | d <- conjSkolemDefs ]
    -- A goal symbol that neither the problem nor another axiom has is a
    -- Skolem symbol of the negated conjecture. When the prover did not
    -- define it, we print a definition and the theorem generalizes over it.
    conjSkolems = [ f | f <- goalSkolems, Set.notMember f definedSyms ]
    goalSkolems =
      [ f | f <- nub (concatMap (litSymbols . fst) (goals spNumbered))
          , Set.notMember f fileSyms
          , f `notElem` concat [ axSyms ax | ax <- axioms spNumbered, isNothing (lookup (axiomName ax) assumed) ] ]
    definedSyms = Set.fromList (concat [ fst (declSymbols d) | T.Unit _ d (Just (T.Introduced _ _, _)) <- inUnits input ])
    axSyms = concatMap litSymbols . axiomLits
    dischargedText =
      let hs = [ ppFormula env (axiomFormula ax) | ax <- axioms spNumbered, isJust (lookup (axiomName ax) assumed) ]
          gs = [ ppFormula env (LitFormula (renameLit (blockRenaming l b) (restoreSkolemsLit l))) | (l, b) <- goals sp ]
          joined xs = case xs of { [x] -> x; _ -> "(" ++ intercalate " & " xs ++ ")" }
      in if null hs then joined gs else "(" ++ joined hs ++ " => " ++ joined gs ++ ")"
    allLines = skolemDefLines ++ inputLines ++ map snd skolemAxLines ++ axiomLines
            ++ (if merged then init stepLines else stepLines)
            ++ theoremLine
    deps = assumptionDeps allLines

-- Defines the Skolem symbols for the universal variables Xs of a conjecture
-- ? [Ys] : ! [Xs] : M as ! [Ys] : ((? [Xs] : ~ M) => ~ M[Xs := sks(Ys)]),
-- reading each symbol off the facts. An X no fact fixes stays existential,
-- and when the prover split M each conjunct gets its own definition.
skolemDefinition :: (String -> String) -> T.Unit -> [String] -> [Literal] -> [T.Unit]
skolemDefinition fresh conjU syms facts = case unitFormula conjU of
  T.FOF f  -> units T.FOF (definitions f)
  T.TFF0 f -> units T.TFF0 (definitions f)
  _        -> []
  where
    units wrap fs =
      [ T.Unit (unitNameOf (fresh name)) (T.Formula (T.Standard T.Plain) (wrap f'))
               (Just (T.Introduced (T.Standard T.ByDefinition) Nothing, Nothing))
      | (name, f') <- zip names' fs ]
      where names' = "skolem_definition" : [ "skolem_definition_" ++ show k | k <- [2 :: Int ..] ]
    -- the whole matrix, or else each of its conjuncts
    definitions :: T.FirstOrder s -> [T.FirstOrder s]
    definitions f = case define syms facts f of
      Just d  -> [d]
      Nothing ->
        let (ys, f1) = existentials f
            (vs, m)  = universals f1
            -- each conjunct with the facts it matches and the Skolem
            -- symbols they mention
            parts   = [ (c, fs, ss) | c <- conjuncts m
                                    , let atoms = [ l | a <- atomsIn c, Just l <- [safeLit a] ]
                                          fs = [ l | l <- facts, any (\a -> any (\a' -> isJust (matchLit a' (unsign l))) [a, flipLit a]) atoms ]
                                          ss = [ s' | s' <- syms, any ((s' `elem`) . litSymbols) fs ]
                                    , not (null ss) ]
            defined = concat [ ss | (_, _, ss) <- parts ]
            defs    = [ define ss fs (T.quantified T.Exists ys (requantify vs c)) | (c, fs, ss) <- parts ]
        in case sequence defs of
             Just ds | length parts > 1
                     , length defined == length (nub defined)
                     , all (`elem` defined) syms -> ds
             _ -> []
    requantify vs c = case nonEmpty vs of
      Just vs' -> T.Quantified T.Forall vs' c
      Nothing  -> c
    conjuncts g = case g of
      T.Connected a T.Conjunction b -> conjuncts a ++ conjuncts b
      _                             -> [g]
    define :: [String] -> [Literal] -> T.FirstOrder s -> Maybe (T.FirstOrder s)
    define ss fs f = do
      let (ys, f1) = existentials f
          (vs, m)  = universals f1
          names    = [ Text.unpack v | (T.Var v, _) <- vs ]
          ynames   = [ Text.unpack v | (T.Var v, _) <- ys ]
      guard (not (null vs) && length (nub (names ++ ynames)) == length (names ++ ynames))
      guard (all (`notElem` names ++ ynames) (boundIn m))
      let atoms   = [ l | a <- atomsIn m, Just l <- [safeLit a] ]
          relevant = [ l | l <- fs, any (`elem` ss) (litSymbols l) ]
      σ <- listToMaybe (solve (names ++ ynames) atoms relevant [])
      -- each fixed X is a Skolem symbol applied to the values of Ys
      let witness a = listToMaybe [ y | y <- ynames, lookup y σ == Just a ]
          skolemOf (v, t) = case t of
            Const c | null ynames -> Just (v, (c, []))
            App g as | not (null ynames) -> (\args -> (v, (g, args))) <$> mapM witness as
            _ -> Nothing
      sks <- mapM skolemOf [ b | b@(v, _) <- σ, v `elem` names ]
      let symbols = map (fst . snd) sks
      guard (length (nub symbols) == length symbols && all (`elem` symbols) ss)
      let unmapped = [ p | p@(T.Var v, _) <- vs, Text.unpack v `notElem` map fst sks ]
      vs' <- nonEmpty vs
      return (T.quantified T.Forall ys
                (T.Connected (T.Quantified T.Exists vs' (T.Negated m)) T.Implication
                             (T.quantified T.Exists unmapped (T.Negated (substFO sks m)))))

    -- the leading existential variables, with what is left
    existentials :: T.FirstOrder s -> ([(T.Var, s)], T.FirstOrder s)
    existentials g = case g of
      T.Quantified T.Exists vs b -> let (ws, m) = existentials b in (toList vs ++ ws, m)
      T.Negated (T.Quantified T.Forall vs b) -> let (ws, m) = existentials (T.Negated b) in (toList vs ++ ws, m)
      _ -> ([], g)

    -- the universal variables of positive polarity, with what is left
    universals :: T.FirstOrder s -> ([(T.Var, s)], T.FirstOrder s)
    universals g = case g of
      T.Quantified T.Forall vs b -> let (ws, m) = universals b in (toList vs ++ ws, m)
      T.Connected a T.Implication b -> let (ws, m) = universals b in (ws, T.Connected a T.Implication m)
      T.Connected a T.ReversedImplication b -> let (ws, m) = universals a in (ws, T.Connected m T.ReversedImplication b)
      T.Connected a c b | c `elem` [T.Conjunction, T.Disjunction] ->
        let (ws, ma) = universals a; (xs, mb) = universals b in (ws ++ xs, T.Connected ma c mb)
      T.Negated (T.Quantified T.Exists vs b) -> let (ws, m) = universals (T.Negated b) in (toList vs ++ ws, m)
      T.Negated (T.Negated b) -> universals b
      _ -> ([], g)

    boundIn :: T.FirstOrder s -> [String]
    boundIn g = case g of
      T.Quantified _ vs b -> [ Text.unpack v | (T.Var v, _) <- toList vs ] ++ boundIn b
      T.Connected a _ b   -> boundIn a ++ boundIn b
      T.Negated b         -> boundIn b
      T.Atomic _          -> []

    atomsIn :: T.FirstOrder s -> [T.Literal]
    atomsIn g = case g of
      T.Atomic l          -> [l]
      T.Negated b         -> atomsIn b
      T.Connected a _ b   -> atomsIn a ++ atomsIn b
      T.Quantified _ _ b  -> atomsIn b

    safeLit l = case l of
      T.Predicate (T.Defined _) ts | all safeTerm ts -> Just (unsign (convertLit l))
      T.Equality a _ b | safeTerm a && safeTerm b     -> Just (unsign (convertLit l))
      _                                               -> Nothing
    safeTerm t = case t of
      T.Variable _                  -> True
      T.Function (T.Defined _) ts   -> all safeTerm ts
      _                             -> False
    unsign (NEq a b) = Eq a b
    unsign l         = l

    -- the ways to match every fact to some atom, binding only the given
    -- variables
    solve _ _ [] σ = [σ]
    solve names atoms (l : ls) σ =
      [ σ'' | a <- atoms, a' <- [a, flipLit a]
            , Just ρ <- [matchLit a' (unsign l)]
            , all ((`elem` names) . fst) ρ
            , Just σ' <- [merge σ ρ]
            , σ'' <- solve names atoms ls σ' ]
    merge = foldM (\acc (v, t) -> case lookup v acc of
                     Nothing -> Just (acc ++ [(v, t)])
                     Just t' -> if t == t' then Just acc else Nothing)

    -- each variable replaced by a symbol applied to variables
    substFO :: [(String, (String, [String]))] -> T.FirstOrder s -> T.FirstOrder s
    substFO σ g = case g of
      T.Atomic l         -> T.Atomic (substLit l)
      T.Negated b        -> T.Negated (substFO σ b)
      T.Connected a c b  -> T.Connected (substFO σ a) c (substFO σ b)
      T.Quantified q vs b -> T.Quantified q vs (substFO σ b)
      where
        substLit (T.Predicate n ts) = T.Predicate n (map substT ts)
        substLit (T.Equality a sg b) = T.Equality (substT a) sg (substT b)
        substT t@(T.Variable (T.Var v)) = maybe t applied (lookup (Text.unpack v) σ)
        substT (T.Function n ts) = T.Function n (map substT ts)
        substT t = t
        applied (c, args) = T.Function (T.Defined (T.Atom (Text.pack c))) [ T.Variable (T.Var (Text.pack a)) | a <- args ]

-- A step turned into the theorem with the given formula and name. Other lines
-- stay as they are.
asTheorem :: Formula -> String -> Line -> Line
asTheorem f name (Step _ _ _ rule ps) = Step name "theorem" f rule ps
asTheorem _ _ l = l

-- The assumptions each line rests on, through its parents. An implies step
-- discharges the assumptions among its parents.
assumptionDeps :: [Line] -> Map.Map String [String]
assumptionDeps = foldl add Map.empty
  where
    add m (Assume n _)         = Map.insert n [n] m
    add m (Step n _ _ rule ps) =
      let inherited  = foldl union [] (mapMaybe (`Map.lookup` m) ps)
          discharged = [ p | rule == "implies", p <- ps, Map.lookup p m == Just [p] ]
      in Map.insert n (filter (`notElem` discharged) inherited) m
    add m (Input _ _)          = m

-- Each symbol's argument and result sorts, or Nothing for an untyped proof.
type SortEnv = Maybe (Map.Map String ([String], String))

-- A sort as TPTP writes it.
sortName :: T.Name T.Sort -> String
sortName (T.Defined (T.Atom a))           = Text.unpack a
sortName (T.Reserved (T.Standard T.I))    = "$i"
sortName (T.Reserved (T.Standard T.O))    = "$o"
sortName (T.Reserved (T.Standard T.Int))  = "$int"
sortName (T.Reserved (T.Standard T.Real)) = "$real"
sortName (T.Reserved (T.Standard T.Rat))  = "$rat"
sortName (T.Reserved (T.Extended e))      = Text.unpack e

-- One line of the derivation as a TPTP unit. A step lists the assumptions it
-- rests on, or for implies the ones it discharges.
ppLine :: SortEnv -> Map.Map String [String] -> Line -> String
ppLine _ _ (Input u info) = completeIntroduced info (show (pretty (asDefinition (dropUnknownInfo u))))
  where
    -- an introduced definition gets the role definition
    asDefinition (T.Unit n (T.Formula _ f) src@(Just (T.Introduced (T.Standard T.ByDefinition) _, _))) =
      T.Unit n (T.Formula (T.Standard T.Definition) f) src
    asDefinition v = v
ppLine env _ (Assume n f) =
  unitKeyword env ++ "(" ++ unitRef n ++ ", assumption, " ++ ppFormula env f ++ ", introduced(assumption, [], []))."
ppLine env deps (Step n role f rule ps) =
  unitKeyword env ++ "(" ++ unitRef n ++ ", " ++ role ++ ", " ++ ppFormula env f ++ ann ++ ")."
  where
    ann | null rule = ""
        | otherwise = ", inference(" ++ rule ++ ", [" ++ intercalate ", " info ++ "], ["
                      ++ intercalate ", " (map unitRef ps) ++ "])"
    assumed = Map.findWithDefault [] n deps
    info
      | rule == "implies" = ["status(thm)", "discharge(implies, [" ++ intercalate ", " (map unitRef onParents) ++ "])"]
      | null assumed      = ["status(thm)"]
      | otherwise         = ["status(thm)", "assumptions([" ++ intercalate ", " (map unitRef assumed) ++ "])"]
    onParents = [ p | p <- ps, Map.lookup p deps == Just [p] ]

-- A unit name as TPTP writes it. Quoted names and integers stay as they are,
-- and any other name is quoted when it needs to be.
unitRef :: String -> String
unitRef n@('\'' : _) = n
unitRef n | not (null n) && all isDigit n = n
          | otherwise                     = tptpSymbol n

-- The unit keyword, tff for a typed proof and fof otherwise.
unitKeyword :: SortEnv -> String
unitKeyword = maybe "fof" (const "tff")

-- A formula of the derivation as TPTP text.
ppFormula :: SortEnv -> Formula -> String
ppFormula env (LitFormula lit)     = quantify env [lit] (tptpLiteral lit)
ppFormula env (ClauseFormula c) = ppTptpClause env c
ppFormula _   (Verbatim f)   = show (pretty f)
ppFormula _   (Raw s)        = s

-- The steps of one block numbered from k, with the next free number and the
-- name of the final step. A have or and line that only restates its fact gives
-- way to the fact unless it is last. The last step states the block's literal
-- up to orientation and takes its name and role, and an empty block proves a
-- reflexive equation.
blockSteps :: (String -> String) -> [(String, Literal)] -> Int -> Maybe String -> String -> Literal -> ProofBlock -> (Int, [Line], String)
blockSteps fresh facts k mName role lit blk =
  case reverse steps of
    Step own _ (LitFormula _) rule ps : earlier ->
      let name = fromMaybe own mName
      in (k' - 1 + maybe 1 (const 0) mName, reverse (Step name role (LitFormula lit') rule ps : earlier), name)
    [] -> let name = fromMaybe (stepName k') mName
          in (k' + 1, [Step name role (LitFormula lit') "reflexivity" []], name)
    _ -> (k', steps, fromMaybe (stepName k') mName)
  where
    renaming    = blockRenaming lit blk
    lit'        = renameLit renaming lit
    (k', steps) = rawSteps k (renameBlock renaming blk)
    stepName n  = fresh ("s" ++ show n)
    restatesFact lit0 nm = maybe False (variantLit lit0) (lookup nm facts)

    rawSteps k0 (HaveHence ls) = loop k0 Nothing [] [] (zip ls (drop 1 (map Just ls) ++ [Nothing]))
      where
        -- cur is the line a hence continues from, extras the and lines since
        loop n _ _ acc [] = (n, reverse acc)
        loop n cur extras acc ((l, next) : rest) = case l of
          Have lit0 nm
            | restatesFact lit0 nm, isJust next -> loop n (Just nm) [] acc rest
            | otherwise -> loop (n + 1) (Just me) [] (plain lit0 "instantiate" [nm] : acc) rest
          And lit0 nm
            | restatesFact lit0 nm, isJust next -> loop n cur (extras ++ [nm]) acc rest
            | otherwise -> loop (n + 1) cur (extras ++ [me]) (plain lit0 "instantiate" [nm] : acc) rest
          Hence lit0 j ->
            let (rule, ps) = case j of
                  ByAxiom nm      -> ("mp", nm : maybeToList cur ++ extras)
                  ByRw nm _       -> ("rewrite", nm : maybeToList cur)
                  ByContradiction -> ("contradiction", maybeToList cur)
            in loop (n + 1) (Just me) [] (plain lit0 rule ps : acc) rest
          where
            me = stepName n
            plain lit0 = Step me "plain" (LitFormula lit0)
    rawSteps k0 (EqChain s chain)
      -- a relational chain ends in true, so read backwards each atom follows
      -- from the next by the equation between them
      | isRelLit lit', (_, Const "true") : _ <- reverse chain
      , Just atoms <- mapM termAtom (atomTerms s chain) =
          let eqs = map (rwName . fst) chain
          in numbered (reverse (zip atoms eqs))
      | otherwise =
          numbered [ (Eq s t, rwName rw) | (rw, t) <- chain ]
      where
        -- a first step that restates the fact it cites is the citation itself
        numbered ((f, nm) : more@(_ : _)) | restatesFact f nm = numberedFrom (Just nm) more
        numbered pairs                                   = numberedFrom Nothing pairs
        numberedFrom start pairs =
          ( k0 + length pairs
          , [ Step (stepName n) "plain" (LitFormula f) rule (nm : prev)
            | (n, (f, nm)) <- zip [k0 ..] pairs
            , let prev = if n > k0 then [stepName (n - 1)] else maybeToList start
                  rule = if null prev then "instantiate" else "rewrite" ] )

-- The conjecture as a single literal, when it is one.
conjLiteral :: T.Declaration -> Maybe Literal
conjLiteral (T.Formula _ (T.CNF (T.Clause lits))) = case foldr (:) [] lits of
  [(T.Positive, l)] -> Just (convertLit l)
  _                 -> Nothing
conjLiteral (T.Formula _ (T.FOF f)) = go f
  where
    go (T.Quantified T.Forall _ body) = go body
    go (T.Atomic l)                   = Just (convertLit l)
    go _                              = Nothing
conjLiteral _ = Nothing

-- The info that a definition brings in the symbols.
newSymbolsInfo :: [String] -> String
newSymbolsInfo syms = "new_symbols(definition, [" ++ intercalate "," syms ++ "])"

-- The parser keeps at most two arguments of introduced, but current TPTP
-- wants the kind, the info and the parents, so the missing lists are added.
completeIntroduced :: String -> String -> String
completeIntroduced info s = case breakOnLast ", introduced(" s of
  Just (before, rest) ->
    let (inner, after) = splitAtClosing rest
        args = map (dropWhile (== ' ')) (topLevelArgs inner)
        -- a missing or empty info list gets the unit's new_symbols info
        args' = case args of
          [k]        -> [k, "[" ++ info ++ "]"]
          [k, "[]"]  -> [k, "[" ++ info ++ "]"]
          _          -> args
    in before ++ ", introduced(" ++ intercalate ", " (args' ++ replicate (3 - length args') "[]") ++ ")" ++ after
  Nothing -> s
  where
    breakOnLast pat str =
      case [ i | (i, t) <- zip [0 ..] (tails str), pat `isPrefixOf` t ] of
        [] -> Nothing
        is -> let i = last is in Just (take i str, drop (i + length pat) str)

-- Vampire writes file(path, unknown) when it lacks the unit's name. The
-- problem has no unit of that name, so the name is dropped.
dropUnknownInfo :: T.Unit -> T.Unit
dropUnknownInfo (T.Unit n d (Just (T.File f (Just (Left (T.Atom i))), info)))
  | i == Text.pack "unknown" = T.Unit n d (Just (T.File f Nothing, info))
dropUnknownInfo u = u

-- A unit read from the file, stated bare, or introduced by the prover.
isInputUnit :: T.Unit -> Bool
isInputUnit u@(T.Unit _ _ ann) = isFileSourced u || case ann of
  Just (T.Introduced _ _, _) -> True
  _                          -> False
isInputUnit _ = False

-- A unit's name, or the empty name for an include.
unitName :: T.Unit -> T.UnitName
unitName (T.Unit n _ _) = n
unitName _              = Left (T.Atom mempty)

-- A unit's declaration, or an empty atom for an include.
unitDecl :: T.Unit -> T.Declaration
unitDecl (T.Unit _ d _) = d
unitDecl _              = T.Formula (T.Standard T.Plain) (T.FOF (T.Atomic (T.Predicate (T.Defined (T.Atom mempty)) [])))

-- A unit's formula. A clause, as Twee writes some conjectures, becomes its
-- universal closure, since a fof formula must be closed.
unitFormula :: T.Unit -> T.Formula
unitFormula u = case unitDecl u of
  T.Formula _ (T.CNF (T.Clause lits)) ->
    let fo (T.Positive, l) = T.Atomic l
        fo (T.Negative, l) = T.Negated (T.Atomic l)
        body = foldr1 (`T.Connected` T.Disjunction) (map fo (toList lits))
        vars = nub [ Text.unpack v | (_, l) <- toList lits, T.Var v <- tptpLitVars l ]
    in T.FOF (T.quantified T.Forall [ (T.Var (Text.pack v), T.Unsorted ()) | v <- vars ] body)
  T.Formula _ f -> f
  _             -> T.FOF (T.Atomic (T.Predicate (T.Defined (T.Atom mempty)) []))

-- A display name such as "axiom 3" as a TPTP name. An integer stays as it is.
tptpName :: String -> String
tptpName s | all isDigit s = s
           | otherwise     = tptpSymbol (map (\c -> if c == ' ' then '_' else c) s)

-- A clause as the closed implication from its body to its head or $false.
ppTptpClause :: SortEnv -> Clause -> String
ppTptpClause env (Clause bs mh) =
  quantify env (bs ++ maybeToList mh) $
    "(" ++ ppBody bs ++ " => " ++ maybe "$false" tptpLiteral mh ++ ")"
  where
    ppBody [b] = tptpLiteral b
    ppBody bs' = "(" ++ intercalate " & " (map tptpLiteral bs') ++ ")"

-- The universal closure over the literals' variables, each with its sort when
-- the proof is typed.
quantify :: SortEnv -> [Literal] -> String -> String
quantify env lits f = case nub (concatMap litVars lits) of
  [] -> f
  vs -> "! [" ++ intercalate "," (map bind vs) ++ "] : " ++ f
  where
    bind v = case env of
      Nothing -> v
      Just m  -> v ++ ": " ++ fromMaybe "$i" (lookup v (concatMap (litSorts m) lits))

-- The sort of each variable of a literal, read off the argument positions it
-- fills. A variable on one side of an equation takes the other side's sort.
litSorts :: Map.Map String ([String], String) -> Literal -> [(String, String)]
litSorts m lit = case lit of
  Rel p ts   -> args p ts
  NRel p ts  -> args p ts
  Eq l r     -> eqn l r
  NEq l r    -> eqn l r
  where
    args f ts = concat (zipWith term (map Just (maybe [] fst (Map.lookup f m)) ++ repeat Nothing) ts)
    term (Just s) (Var v) = [(v, s)]
    term _ (Var _)        = []
    term _ (App f ts)     = args f ts
    term _ _              = []
    eqn l r = let s = listToMaybe (mapMaybe resultSort [l, r])
              in term s l ++ term s r
    resultSort (App f _) = snd <$> Map.lookup f m
    resultSort (Const c) = snd <$> Map.lookup c m
    resultSort _         = Nothing

