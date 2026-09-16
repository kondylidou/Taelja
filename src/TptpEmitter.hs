-- The structured proof as a TPTP derivation, one formula per line.  The input
-- units the proof rests on come first, printed as they were read, then the
-- hypotheses of an implication conjecture as assumptions, then every proof
-- step as a plain formula with an inference record naming its parents.  Each
-- lemma and goal is the last step of its own block, and the conjecture is
-- the final theorem, discharging the assumptions.  No step derives $false, so
-- a reader sees a direct proof.
module TptpEmitter (emitTptp) where

import Data.Char (isAlphaNum, isAsciiLower, isDigit)
import Data.List (intercalate, isPrefixOf, nub, nubBy, sortOn, tails, union)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe, isJust, listToMaybe, mapMaybe, maybeToList)
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)
import Types
import Helpers
import Emitter (applyRenaming, axiomRenaming, blockRenaming, pruneUnusedLemmas)
import ProofTree (unitNameStr)
import TptpConvert (convertDeclToClause, convertLit, declSymbols)

-- One line of the derivation.  An input unit is printed as it was read, and
-- every other line has a name, a role, a formula and the parents its inference
-- record names.
data Line
  = Input T.Unit String
  | Assume String Formula
  | Step String String Formula String [String]

-- A derived formula is one of ours, or the conjecture printed as it was read,
-- or text assembled from printed parts.
data Formula = Ours Literal | OursClause Clause | Verbatim T.Formula | Raw String

emitTptp :: StructuredProof -> String
emitTptp sp0 = unlines $
     ["% SZS output start Proof"]
  ++ typeLines
  ++ map (ppLine env deps) allLines
  ++ ["% SZS output end Proof"]
  where
    sp1   = pruneUnusedLemmas sp0
    input = spInput sp1
    -- A typed proof is printed typed.  Its type declarations come first, the
    -- input units are the typed ones as read, and a variable of a derived
    -- formula gets the sort of the argument position it occurs in.
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

    -- Every axiom is cited by its input unit's name.  A hypothesis becomes an
    -- assumption named after the clause that stated it, and an axiom with no
    -- input unit, or whose clause reading differs from it, keeps a name of
    -- its own.
    hyps     = Map.keysSet (inHypotheses input)
    axNames  = map axiomName (axioms sp1)
    assumed  = [ (n, c) | n <- axNames, Just c <- [Map.lookup n (inHypotheses input)] ]
    -- an axiom a re-proof added has no recorded unit and is looked up by its
    -- statement among the input units
    inputOf n = fmap canonical $ case Map.lookup n (inAxiomUnits input) of
      Just u  -> Just u
      Nothing -> listToMaybe [ u | u <- inUnits input, isInputUnit u, sameAsInput u n ]
    -- a unit that only copies its one parent, as E's renamed and simplified
    -- file clauses do, stands for the unit it copies
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
    axiomOf n = lookup n [ (axiomName a, a) | a <- axioms sp1 ]
    lemmaTarget n = fresh (tptpName n)
    -- a goal variable that stands for a fresh constant of the prover is that
    -- constant again here, since a TPTP formula cannot hold a fixed variable,
    -- and the final theorem generalizes over it
    reSk = [ (v, Const c) | (v, c) <- inGeneralized input ]
    skolemVars = map fst reSk
    reSkLit  = mapLiteralTerms (subVars reSk)
    subVars s (Var v)    = fromMaybe (Var v) (lookup v s)
    subVars s (App f ts) = App f (map (subVars s) ts)
    subVars _ t          = t
    sp  = applyRenaming (Map.fromList ([ (n, axTarget n) | n <- axNames ]
                                       ++ [ (n, lemmaTarget n) | (n, _, _) <- lemmas sp1 ])) sp1
    ren = axiomRenaming (axioms sp1)

    -- an input unit that E derived from an introduced definition cites it,
    -- so such parents are printed first
    -- the units in the proof's own order, so a definition follows the units
    -- it mentions
    inputLines = map (\(_, u) -> Input (typedUnit u) (newSymbols u)) $ sortOn (unitIndex . fst) $ nubBy (\a b -> fst a == fst b) $ concat
      [ withParents u | n <- axNames, not (Set.member n hyps), Just u <- [inputOf n] ]
      ++ concat [ withParents d | n <- axNames, dn <- definitionsBehind n, Just d <- [Map.lookup dn byName] ]
    -- The symbols an introduced definition defines, which GDV wants named in
    -- its info as new_symbols(definition, [...]) and E and Vampire leave out.
    -- They are the symbols of the unit that no input unit has.
    fileSyms = let ps = [ declSymbols d | T.Unit _ d ann <- inUnits input, isFileAnn ann ]
               in Set.fromList (concatMap fst ps ++ concatMap snd ps)
    isFileAnn Nothing                = True
    isFileAnn (Just (T.File _ _, _)) = True
    isFileAnn _                      = False
    -- a symbol is new in the first definition that mentions it
    unitIndex n = fromMaybe maxBound (Map.lookup n unitOrder)
    unitOrder = Map.fromList (zip [ unitNameStr (unitName u) | u <- inUnits input ] [0 :: Int ..])
    newSymbols u = case u of
      T.Unit n d (Just (T.Introduced _ _, _)) ->
        let (fs, ps) = declSymbols d
            earlier = Set.fromList $ concat
              [ let (fs', ps') = declSymbols d' in fs' ++ ps'
              | T.Unit n' d' (Just (T.Introduced _ _, _)) <- inUnits input
              , unitIndex (unitNameStr n') < unitIndex (unitNameStr n) ]
            isNew s = Set.notMember s fileSyms && Set.notMember s earlier
        in "new_symbols(definition, [" ++ intercalate "," (nub (filter isNew (fs ++ ps))) ++ "])"
      _ -> ""
    -- the definitions the prover introduced on the way from an input unit to
    -- an axiom's clause, such as Vampire's Skolem definitions, which the
    -- clausify step cites as well
    definitionsBehind n = case Map.lookup n (inAxiomLeaves input) of
      Nothing   -> []
      Just leaf -> nub (walk Set.empty [leaf])
      where
        walk _ [] = []
        walk seen (x : xs)
          | Set.member x seen = walk seen xs
          | otherwise = case Map.lookup x byName of
              Just u@(T.Unit _ _ (Just (T.Introduced _ _, _))) -> unitNameStr (unitName u) : walk (Set.insert x seen) xs
              Just u | not (isInputUnit u) -> walk (Set.insert x seen) (unitParents u ++ xs)
              _ -> walk (Set.insert x seen) xs
    byName = Map.fromList [ (unitNameStr (unitName u), u) | u <- inUnits input ]
    withParents u = concat [ withParents p | n <- unitParents u, Just p <- [Map.lookup n byName] ]
                    ++ [(unitNameStr (unitName u), u)]
    axiomLines = concat
      [ case (lookup n assumed, inputOf n) of
          (Just a, _) -> [Assume a (axiomFormula ax)]
          (Nothing, Just u)
            | sameAsInput u n -> []
            | otherwise ->
                [Step (axTarget n) "plain" (axiomFormula ax) "clausify"
                      (unitNameStr (unitName u) : definitionsBehind n)]
          (Nothing, Nothing) -> [Step (axTarget n) "axiom" (axiomFormula ax) "" []]
      | n <- axNames, Just ax <- [axiomOf n] ]
    axiomFormula (AUnit _ l)    = Ours (renameLit ren (reSkLit l))
    axiomFormula (ANucleus _ (Clause bs mh)) =
      OursClause (Clause (map (renameLit ren . reSkLit) bs) (fmap (renameLit ren . reSkLit) mh))

    -- facts a have or and line may restate word for word
    facts = [ (axTarget n, l) | AUnit n l <- axioms sp1 ]
         ++ [ (lemmaTarget n, l) | (n, l, _) <- lemmas sp1 ]

    -- a goal that a final theorem line concludes from is an ordinary step
    blocks = [ (Just n, "lemma", lit, blk) | (n, lit, blk) <- lemmas sp ]
          ++ [ (goalName i, goalRole, lit, blk) | (i, (lit, blk)) <- zip [1 :: Int ..] (goals sp) ]
    goalName i | goalRole == "plain" = Nothing
               | otherwise           = Just (fresh ("goal_" ++ show i))
    conj      = inConjecture input
    conjName  = fromMaybe "goal" (fmap (unitNameStr . unitName) conj)
    conjAtom  = conj >>= conjLiteral . unitDecl
    -- the one goal states the conjecture itself, so its step is the theorem
    merged = case (goals sp, conjAtom) of
      ([(g, _)], Just c) -> null assumed && variantLit g c && not (null stepLines)
      _                  -> False
    goalRole | isJust conj && not merged = "plain"
             | otherwise                 = "theorem"
    blockResults = go 1 blocks
    go _ [] = []
    go k ((name, role, lit, blk) : rest) =
      let (k', steps, final) = blockSteps fresh facts k name role (reSkLit lit) (reSkBlock blk)
      in (steps, final) : go k' rest
    reSkBlock (HaveHence ls)    = HaveHence (map reSkLine ls)
    reSkBlock (EqChain s chain) = EqChain (subVars reSk s) [ (rw, subVars reSk t) | (rw, t) <- chain ]
    reSkLine (Have l n)  = Have (reSkLit l) n
    reSkLine (And l n)   = And (reSkLit l) n
    reSkLine (Hence l j) = Hence (reSkLit l) j
    stepLines  = concatMap fst blockResults
    goalFinals = map snd (drop (length (lemmas sp)) blockResults)
    theoremLine = case conj of
      Just u | merged -> [ asTheorem (Verbatim (unitFormula (typedUnit u))) conjName (last stepLines) ]
      Just u
        | null skolemVars ->
            [ Step conjName "theorem" (Verbatim (unitFormula (typedUnit u)))
                   (if null assumed then "conclude" else "implies")
                   (goalFinals ++ map snd assumed) ]
        -- the discharge holds for the prover's fresh constants, and the
        -- conjecture follows by generalizing over them
        | otherwise ->
            [ Step (fresh "discharged") "plain" (Raw dischargedText)
                   (if null assumed then "conclude" else "implies")
                   (goalFinals ++ map snd assumed)
            , Step conjName "theorem" (Verbatim (unitFormula (typedUnit u))) "generalization" [fresh "discharged"] ]
      Nothing -> []
    dischargedText =
      let hs = [ ppFormula env (axiomFormula ax) | ax <- axioms sp1, isJust (lookup (axiomName ax) assumed) ]
          gs = [ ppFormula env (Ours (renameLit (blockRenaming l b) (reSkLit l))) | (l, b) <- goals sp ]
          joined xs = case xs of { [x] -> x; _ -> "(" ++ intercalate " & " xs ++ ")" }
      in if null hs then joined gs else "(" ++ joined hs ++ " => " ++ joined gs ++ ")"
    allLines = inputLines ++ axiomLines
            ++ (if merged then init stepLines else stepLines)
            ++ theoremLine
    deps = assumptionDeps allLines

asTheorem :: Formula -> String -> Line -> Line
asTheorem f name (Step _ _ _ rule ps) = Step name "theorem" f rule ps
asTheorem _ _ l = l

-- The assumptions each line rests on, through its parents.  An implies step
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

-- The symbol types of a typed proof, as argument sorts and result sort.
type SortEnv = Maybe (Map.Map String ([String], String))

sortName :: T.Name T.Sort -> String
sortName (T.Defined (T.Atom a))           = Text.unpack a
sortName (T.Reserved (T.Standard T.I))    = "$i"
sortName (T.Reserved (T.Standard T.O))    = "$o"
sortName (T.Reserved (T.Standard T.Int))  = "$int"
sortName (T.Reserved (T.Standard T.Real)) = "$real"
sortName (T.Reserved (T.Standard T.Rat))  = "$rat"
sortName (T.Reserved (T.Extended e))      = Text.unpack e

ppLine :: SortEnv -> Map.Map String [String] -> Line -> String
-- an introduced definition has the role definition, whatever the prover wrote
ppLine _ _ (Input u@(T.Unit _ _ (Just (T.Introduced (T.Standard T.ByDefinition) _, _))) info) =
  currentIntro info (definitionRole (show (pretty (dropUnknownInfo u))))
  where
    definitionRole s = case breakOnFirst ", plain, " s of
      Just (before, after) -> before ++ ", definition, " ++ after
      Nothing              -> s
    breakOnFirst pat str = case [ i | (i, t) <- zip [0 ..] (tails str), pat `isPrefixOf` t ] of
      []      -> Nothing
      (i : _) -> Just (take i str, drop (i + length pat) str)
ppLine _ _ (Input u info) = currentIntro info (show (pretty (dropUnknownInfo u)))
ppLine env _ (Assume n f) =
  keyword env ++ "(" ++ n ++ ", assumption, " ++ ppFormula env f ++ ", introduced(assumption, [], []))."
ppLine env deps (Step n role f rule ps) =
  keyword env ++ "(" ++ n ++ ", " ++ role ++ ", " ++ ppFormula env f ++ ann ++ ")."
  where
    ann | null rule = ""
        | otherwise = ", inference(" ++ rule ++ ", [" ++ intercalate ", " info ++ "], ["
                      ++ intercalate ", " ps ++ "])"
    assumed = Map.findWithDefault [] n deps
    info
      | rule == "implies" = ["status(thm)", "discharge(implies, [" ++ intercalate ", " onParents ++ "])"]
      | null assumed      = ["status(thm)"]
      | otherwise         = ["status(thm)", "assumptions([" ++ intercalate ", " assumed ++ "])"]
    onParents = [ p | p <- ps, Map.lookup p deps == Just [p] ]

keyword :: SortEnv -> String
keyword = maybe "fof" (const "tff")

ppFormula :: SortEnv -> Formula -> String
ppFormula env (Ours lit)     = ppLit env lit
ppFormula env (OursClause c) = ppClause env c
ppFormula _   (Verbatim f)   = show (pretty f)
ppFormula _   (Raw s)        = s

-- The steps of one block, numbered from k, and the name of the one stating
-- the lemma or goal.  A have or and line that restates the fact it cites word
-- for word adds nothing, so the citation is used directly, unless the line is
-- the whole block.  The block's last step states the lemma or goal itself and
-- takes its name and role, or a restating step is added when the two differ
-- by more than orientation.  With no name the step keeps its number.
blockSteps :: (String -> String) -> [(String, Literal)] -> Int -> Maybe String -> String -> Literal -> ProofBlock -> (Int, [Line], String)
blockSteps fresh facts k mName role lit blk =
  case reverse steps of
    Step own _ (Ours l) rule ps : earlier
      | l == lit' || flipLit l == lit' ->
          let name = fromMaybe own mName
          in (k' - 1 + maybe 1 (const 0) mName, reverse (Step name role (Ours lit') rule ps : earlier), name)
      | otherwise ->
          let name = fromMaybe (stepName k') mName
          in (k' + 1, steps ++ [Step name role (Ours lit') "restate" [stepName (k' - 1)]], name)
    -- an empty block proves a reflexive equation, and anything else it
    -- claims is left visibly unproved
    [] -> let name = fromMaybe (stepName k') mName
              rule = case lit' of
                Eq s t | s == t -> "reflexivity"
                _               -> "unproved"
          in (k' + 1, [Step name role (Ours lit') rule []], name)
    _ -> (k', steps, fromMaybe (stepName k') mName)
  where
    renaming    = blockRenaming lit blk
    lit'        = renameLit renaming lit
    (k', steps) = rawSteps k (renameBlock renaming blk)
    stepName n  = fresh ("s" ++ show n)
    trivial lit0 nm = maybe False (variantLit lit0) (lookup nm facts)

    rawSteps k0 (HaveHence ls) = loop k0 Nothing [] [] (zip ls (drop 1 (map Just ls) ++ [Nothing]))
      where
        -- cur is the chain hypothesis and extras the and-items for the next hence
        loop n _ _ acc [] = (n, reverse acc)
        loop n cur extras acc ((l, next) : rest) = case l of
          Have lit0 nm
            | trivial lit0 nm, isJust next -> loop n (Just nm) [] acc rest
            | otherwise -> loop (n + 1) (Just me) [] (plain lit0 "instantiate" [nm] : acc) rest
          And lit0 nm
            | trivial lit0 nm, isJust next -> loop n cur (extras ++ [nm]) acc rest
            | otherwise -> loop (n + 1) cur (extras ++ [me]) (plain lit0 "instantiate" [nm] : acc) rest
          Hence lit0 j ->
            let (rule, ps) = case j of
                  ByAxiom nm      -> ("mp", nm : maybeToList cur ++ extras)
                  ByRw nm _       -> ("rewrite", nm : maybeToList cur)
                  ByContradiction -> ("contradiction", maybeToList cur)
            in loop (n + 1) (Just me) [] (plain lit0 rule ps : acc) rest
          where
            me = stepName n
            plain lit0 = Step me "plain" (Ours lit0)
    rawSteps k0 (EqChain s chain)
      -- a relational chain ends in true, and reading it backwards each atom is
      -- derived from the next by the equation between them
      | isRel lit', (_, Const "true") : _ <- reverse chain =
          let atoms = map atomOf (s : map snd (init chain))
              eqs   = map (rwName . fst) chain
          in numbered (reverse (zip atoms eqs))
      | otherwise =
          numbered [ (Eq s t, rwName rw) | (rw, t) <- chain ]
      where
        isRel (Rel _ _) = True
        isRel _         = False
        atomOf (App f ts) = Rel f ts
        atomOf (Const c)  = Rel c []
        atomOf (Var v)    = Rel v []
        -- a first step that restates the fact it cites is the citation itself
        numbered ((f, nm) : more@(_ : _)) | trivial f nm = numberedFrom (Just nm) more
        numbered pairs                                   = numberedFrom Nothing pairs
        numberedFrom start pairs =
          ( k0 + length pairs
          , [ Step (stepName n) "plain" (Ours f) rule (nm : prev)
            | (n, (f, nm)) <- zip [k0 ..] pairs
            , let prev = if n > k0 then [stepName (n - 1)] else maybeToList start
                  rule = if null prev then "instantiate" else "rewrite" ] )

variantLit :: Literal -> Literal -> Bool
variantLit a b = isJust (matchLit a b) && isJust (matchLit b a)

variantClause :: Clause -> Clause -> Bool
variantClause a b = clauseInstance a b && clauseInstance b a

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

-- The parser keeps two arguments of introduced at most, and current TPTP
-- wants the kind, the info list and the parent list, so the missing lists
-- are added.
currentIntro :: String -> String -> String
currentIntro info s = case breakOnLast ", introduced(" s of
  Just (before, rest) ->
    let (inner, after) = balancedParen rest
        args = map (dropWhile (== ' ')) (topLevelArgs inner)
        -- an empty info list gets the symbols the unit introduces
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
    balancedParen = walk (0 :: Int)
      where
        walk _ [] = ([], [])
        walk d (x : xs)
          | x == ')' && d == 0 = ([], xs)
          | x `elem` "([" = first (x :) (walk (d + 1) xs)
          | x `elem` ")]" = first (x :) (walk (d - 1) xs)
          | otherwise     = first (x :) (walk d xs)
        first f (a, b) = (f a, b)

-- Vampire writes file(path, unknown) when the problem names no unit, and
-- the TPTP syntax has no such name, so the info is dropped.
dropUnknownInfo :: T.Unit -> T.Unit
dropUnknownInfo (T.Unit n d (Just (T.File f (Just (Left (T.Atom i))), info)))
  | i == Text.pack "unknown" = T.Unit n d (Just (T.File f Nothing, info))
dropUnknownInfo u = u

-- A unit read from the file, stated bare, or introduced by the prover.
isInputUnit :: T.Unit -> Bool
isInputUnit (T.Unit _ _ Nothing)                      = True
isInputUnit (T.Unit _ _ (Just (T.File _ _, _)))       = True
isInputUnit (T.Unit _ _ (Just (T.Introduced _ _, _))) = True
isInputUnit _                                         = False

unitParents :: T.Unit -> [String]
unitParents (T.Unit _ _ (Just (src, _))) = go src
  where
    go (T.UnitSource n)       = [unitNameStr n]
    go (T.Inference _ _ ps)   = concat [ go s | T.Parent s _ <- ps ]
    go _                      = []
unitParents _ = []

unitName :: T.Unit -> T.UnitName
unitName (T.Unit n _ _) = n
unitName _              = Left (T.Atom mempty)

unitDecl :: T.Unit -> T.Declaration
unitDecl (T.Unit _ d _) = d
unitDecl _              = T.Formula (T.Standard T.Plain) (T.FOF (T.Atomic (T.Predicate (T.Defined (T.Atom mempty)) [])))

unitFormula :: T.Unit -> T.Formula
unitFormula u = case unitDecl u of
  T.Formula _ f -> f
  _             -> T.FOF (T.Atomic (T.Predicate (T.Defined (T.Atom mempty)) []))

axiomName :: Axiom -> String
axiomName (AUnit n _)    = n
axiomName (ANucleus n _) = n

axiomClause :: Axiom -> Clause
axiomClause (AUnit _ l)    = Clause [] (Just l)
axiomClause (ANucleus _ c) = c

-- A display name such as "axiom 3" as a TPTP name.  A name may also be an
-- integer.
tptpName :: String -> String
tptpName s | all isDigit s = s
           | otherwise     = symbol (map (\c -> if c == ' ' then '_' else c) s)

-- A lower word is printed as it is, and anything else single-quoted.  A
-- string of digits is quoted too, since a constant such as E's '0' is an
-- atom and not a number.
symbol :: String -> String
symbol s@(c : cs)
  | c == '$' = s
  | isAsciiLower c && all (\x -> isAlphaNum x || x == '_') cs = s
symbol s = "'" ++ concatMap esc s ++ "'"
  where
    esc '\'' = "\\'"
    esc '\\' = "\\\\"
    esc c    = [c]

ppLit :: SortEnv -> Literal -> String
ppLit env lit = quantify env [lit] (ppAtom lit)

ppClause :: SortEnv -> Clause -> String
ppClause env (Clause bs mh) =
  quantify env (bs ++ maybeToList mh) $
    "(" ++ ppBody bs ++ " => " ++ maybe "$false" ppAtom mh ++ ")"
  where
    ppBody [b] = ppAtom b
    ppBody bs' = "(" ++ intercalate " & " (map ppAtom bs') ++ ")"

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
-- fills.  A variable on one side of an equation takes the other side's sort.
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
    term _ (Const _)      = []
    term _ (App f ts)     = args f ts
    eqn l r = let s = listToMaybe (mapMaybe resultSort [l, r])
              in term s l ++ term s r
    resultSort (App f _) = snd <$> Map.lookup f m
    resultSort (Const c) = snd <$> Map.lookup c m
    resultSort (Var _)   = Nothing

ppAtom :: Literal -> String
ppAtom (Eq l r)    = ppT l ++ " = " ++ ppT r
ppAtom (NEq l r)   = ppT l ++ " != " ++ ppT r
ppAtom (Rel n ts)  = ppApp n ts
ppAtom (NRel n ts) = "~ " ++ ppApp n ts

ppApp :: String -> [Term] -> String
ppApp n [] = symbol n
ppApp n ts = symbol n ++ "(" ++ intercalate "," (map ppT ts) ++ ")"

ppT :: Term -> String
ppT (Var x)    = x
ppT (Const c)  = symbol c
ppT (App f ts) = ppApp f ts
