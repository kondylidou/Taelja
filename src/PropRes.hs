-- E may close a refutation with a single cdclpropres step over the clauses its
-- SAT solver used, and iProver with a prop_impl_just step. That step has no
-- unifier for θ to read, so it is replaced by the chain of unit resolutions
-- that derives $false. Unit resolution is complete for Horn clauses, so such a
-- chain exists. iProver's global_subsumption_just, which drops literals of a
-- clause its SAT solver shows redundant, and its bin_hyper_res become the
-- resolutions they stand for. Likewise an ar step, E's AC resolution, is
-- replaced by the rewrites with the associativity and commutativity axioms it
-- cites, and iProver's demodulation and normalisation steps, which apply their
-- equations several times at once, by their single rewrites.
module PropRes (expandPropRes, expandACRes, expandDemodulation) where

import Control.Applicative ((<|>))
import Control.Monad (foldM, guard)
import Data.Function (on)
import Data.List (nub, nubBy, partition, sortOn)
import Data.Maybe (fromMaybe, isJust, listToMaybe, maybeToList)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import Helpers (applySubstTerm, clauseInstance, clauseKey, clauseLits, deepApplySubstTerm, fromPolLits, foldLiteralTerms, litAsTerm,
                litVars, mapLiteralTerms, matchTerm, notVar, polLits, ppTerm, putTermAt, resolveHead, subterms, suffixVarsClause,
                suffixVarsLit, termAsLit, termAt, termCtxs, termVars, unifyTerms)
import TptpConvert (clauseToDecl, convertDeclToClause, resolutionSource, unitNameOf, unitNameStr)
import ProofTree (matchClause, resolveCopySource, resolvents)

-- The name of a derived clause, the names of the two clauses it resolves, and
-- the clause.
type Step = (String, String, String, Clause)

-- Replaces each cdclpropres or prop_impl_just step by the unit resolutions that
-- derive its $false, and each global_subsumption_just or bin_hyper_res step by
-- the resolutions that derive its clause. A step modulo equality also gets the
-- rewrites it needs. The last resolution keeps the step's name.
expandPropRes :: [T.Unit] -> [T.Unit]
expandPropRes units = concatMap expand units
  where
    unitMap = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n _ _) <- units ]
    declOf = Map.fromList [ (unitNameStr n, d) | T.Unit n d _ <- units ]
    premises ps = [ (nm, c) | T.Parent (T.UnitSource pn) _ <- ps, let nm = unitNameStr pn
                            , Just c <- [Map.lookup nm declOf >>= convertDeclToClause] ]
    -- an instance of an equality axiom iProver adds to its clauses
    equalityAxiom nm = case Map.lookup (resolveCopySource unitMap nm) unitMap of
      Just (T.Unit _ _ (Just (T.Theory (T.Atom w) _, _))) -> w == Text.pack "equality"
      _                                                   -> False
    -- a global subsumption whose clause a premise already states rests on
    -- that premise alone
    expand (T.Unit n d (Just (T.Inference r@(T.Atom rule) info ps, ann)))
      | rule == Text.pack "global_subsumption_just", Just goal <- convertDeclToClause d
      , pn : _ <- [ nm | (nm, c) <- premises ps, clauseKey c == clauseKey goal ] =
          [T.Unit n d (Just (T.Inference r info [T.Parent (T.UnitSource (unitNameOf pn)) []], ann))]
    -- a propositional step that can be derived becomes its resolutions, any other unit stays
    expand u@(T.Unit n d (Just (T.Inference (T.Atom rule) info ps, ann))) = case steps of
      Just (pre@(_ : _), []) -> pre
      Just (pre, ss@(_ : _)) ->
        pre
        ++ [ T.Unit (unitNameOf nm) (clauseToDecl c) (Just (resolutionSource [T.Status (T.Standard T.THM)] l r, Nothing))
           | (nm, l, r, c) <- init ss ]
        ++ [ T.Unit n d (Just (resolutionSource info l r, ann)) | (_, l, r, _) <- [last ss] ]
      _ -> [u]
      where
        steps
          | rule `elem` map Text.pack ["cdclpropres", "prop_impl_just"], prem@(_ : _) <- premises ps
          , not (any (equalityAxiom . fst) prem) =
              ([],) <$> propRefute (unitNameStr n) prem
          -- iProver's SMT step, and a propositional one citing its equality
          -- axioms, reason modulo equality
          | rule `elem` map Text.pack ["prop_impl_just", "smt_impl_just"], prem@(_ : _) <- premises ps =
              equalityRefute (unitNameStr n) (filter (not . equalityAxiom . fst) prem)
          -- iProver cites the clause it shortens first, and often again later.
          -- Its binary hyper-resolution is resolutions with the cited clauses
          -- too.
          | rule `elem` map Text.pack ["global_subsumption_just", "bin_hyper_res"]
          , prem@(_ : _) <- nubBy ((==) `on` fst) (premises ps)
          , Just goal <- convertDeclToClause d =
              ([],) <$> resolveAway (unitNameStr n) goal prem
          | otherwise = Nothing
    expand u = [u]

-- The resolutions that derive goal, a part of a cited clause. Each resolves
-- the clause so far, starting from any cited clause, with another one. The
-- search is breadth first, duplicate body atoms are dropped, and as in
-- propRefute a resolvent may only use terms the cited clauses contain. The
-- last resolvent may be more general than goal, whose literals it may merge.
resolveAway :: String -> Clause -> [(String, Clause)] -> Maybe [Step]
resolveAway base goal prem = go [ (n, c, []) | (n, c) <- prem ] (Set.fromList (map (clauseKey . snd) prem))
  where
    known = Set.fromList (concatMap (clauseTerms . snd) prem)
    -- each path is the premises used and the clauses they give, the last first
    go [] _ = Nothing
    go ((start, c, path) : queue) seen
      | isJust (matchClause c goal), not (null path) = Just (named start (reverse path))
      | otherwise = go (queue ++ [ (start, r, (pn, r) : path) | (pn, r) <- next ])
                       (foldr (Set.insert . clauseKey . snd) seen next)
      where
        next = nubBy ((==) `on` (clauseKey . snd))
          [ (pn, r)
          | (pn, p) <- prem
          , let p' = suffixVarsClause "_q" p
          , Clause bs h <- resolveHead c p' ++ resolveHead p' c
          , let r = Clause (nub bs) h
          , all (`Set.member` known) (clauseTerms r)
          , Set.notMember (clauseKey r) seen ]
    -- the steps with their names, the last keeping the step's own
    named start path = [ (nm, prev, pn, r) | (nm, (pn, r), prev) <- zip3 names path (start : names) ]
      where names = [ base ++ "_gs" ++ show i | i <- [1 .. length path - 1] ] ++ [base]

-- A refutation modulo equality, as rewrites and then unit propagation. The
-- ground unit equations among the clauses are completed to rewrite rules,
-- each new rule derived by single rewrites, and the other ground clauses are
-- rewritten to normal form. A body equation u = u is then dropped by equality
-- resolution and a clause with the head u = u is left out.
equalityRefute :: String -> [(String, Clause)] -> Maybe ([T.Unit], [Step])
equalityRefute base prem = do
  let ground c = null (concatMap litVars (clauseLits c))
      eqs = [ (n, (l, r)) | (n, c@(Clause [] (Just (Eq l r)))) <- prem, ground c ]
      others = [ p | p@(n, _) <- prem, n `notElem` map fst eqs ]
      name i = base ++ "_eq" ++ show i
      (rules, k, pre1) = completeGround name eqs 1
      (clauses, pre2) = normaliseGround name rules others k
  case [ n | (n, Clause [] Nothing) <- clauses ] of
    -- rewriting closed a disequation, so its equality resolution is the step
    n : _ -> Just ([ if unitNameStr m == n then T.Unit (unitNameOf base) d a else u
                   | u@(T.Unit m d a) <- pre1 ++ pre2 ], [])
    [] -> (pre1 ++ pre2,) <$> propRefute base clauses

-- Ground equations completed to rules that rewrite a term to a smaller one,
-- with the next fresh number and the units that derive the new rules. Each
-- equation is first rewritten by the rules so far, then oriented, and a rule
-- the new one rewrites goes back to be completed again.
completeGround :: (Int -> String) -> [(String, (Term, Term))] -> Int -> ([(String, (Term, Term))], Int, [T.Unit])
completeGround name = go []
  where
    go rules [] k = (rules, k, [])
    go rules ((n, (l, r)) : rest) k =
      let (n1, l', k1, u1) = rewriteSteps name (Clause [] . Just) rules k n (`Eq` r) l
          (n2, r', k2, u2) = rewriteSteps name (Clause [] . Just) rules k1 n1 (Eq l') r
          rule = if groundGreater l' r' then (l', r') else (r', l')
          (hit, kept) = partition (\(_, (a, b)) -> any ((fst rule `elem`) . subterms) [a, b]) rules
          (rules', k3, more) = if l' == r' then go rules rest k2 else go (kept ++ [(n2, rule)]) (hit ++ rest) k2
      in (rules', k3, u1 ++ u2 ++ more)

-- Ground clauses rewritten to normal form by the rules, each rewrite and each
-- dropped body equation u = u its own unit. A clause with the head u = u is
-- left out, and a clause with variables stays as it is.
normaliseGround :: (Int -> String) -> [(String, (Term, Term))] -> [(String, Clause)] -> Int -> ([(String, Clause)], [T.Unit])
normaliseGround name rules = go
  where
    go [] _ = ([], [])
    go ((n, c) : rest) k
      | not (null (concatMap litVars (clauseLits c))) = let (cs, us) = go rest k in ((n, c) : cs, us)
      | otherwise =
          let lits = polLits c
              (n1, lits', k1, units) = foldl literal (n, lits, k, []) [0 .. length lits - 1]
              kept = filter (not . trivial) lits'
              er = T.Unit (unitNameOf (name k1)) (clauseToDecl (fromPolLits kept))
                     (Just (T.Inference (T.Atom (Text.pack "equality_resolution")) [thm] [parent n1], Nothing))
              (n2, c2, k2, units') | length kept < length lits' = (name k1, fromPolLits kept, k1 + 1, units ++ [er])
                                   | otherwise                  = (n1, fromPolLits lits', k1, units)
              (cs, us) = go rest k2
          in case c2 of
               Clause _ (Just (Eq a b)) | a == b -> (cs, units' ++ us)
               _ -> ((n2, c2) : cs, units' ++ us)
    trivial (False, Eq a b) = a == b
    trivial _               = False
    -- the sides of literal i rewritten in turn
    literal (n, lits, k, units) i =
      let (sg, lit) = lits !! i
          put ls x = take i ls ++ (sg, x) : drop (i + 1) ls
          clause x = fromPolLits (put lits x)
          args (App _ xs) = xs
          args _          = []
          (n', lit', k', us) = case lit of
            Eq a b ->
              let (n1, a', k1, u1) = rewriteSteps name clause rules k n (`Eq` b) a
                  (n2, b', k2, u2) = rewriteSteps name clause rules k1 n1 (Eq a') b
              in (n2, Eq a' b', k2, u1 ++ u2)
            Rel p as ->
              let (n1, t, k1, u1) = rewriteSteps name clause rules k n (Rel p . args) (App p as)
              in (n1, Rel p (args t), k1, u1)
            _ -> (n, lit, k, [])
      in (n', put lits lit', k', units ++ us)

-- The single rewrites of term t by ground rules, each a unit with the next
-- fresh number that rewrites the unit before it, the first being n. Its
-- clause is the literal build makes of the term, put into its clause.
-- Returns the last unit's name, the normal form, the next fresh number and
-- the units.
rewriteSteps :: (Int -> String) -> (Literal -> Clause) -> [(String, (Term, Term))] -> Int -> String -> (Term -> Literal) -> Term
             -> (String, Term, Int, [T.Unit])
rewriteSteps name clause rules k n build t =
  case [ (rn, ctx r) | (u, ctx) <- termCtxs t, (rn, (l, r)) <- rules, u == l ] of
    (rn, t') : _ ->
      let unit = T.Unit (unitNameOf (name k)) (clauseToDecl (clause (build t')))
                   (Just (T.Inference (T.Atom (Text.pack "demodulation")) [thm] [parent n, parent rn], Nothing))
          (n', t'', k', us) = rewriteSteps name clause rules (k + 1) (name k) build t'
      in (n', t'', k', unit : us)
    [] -> (n, t, k, [])

-- A total order on ground terms that is a reduction order, the Knuth-Bendix
-- ordering with every symbol weighing 1 and symbols in alphabetical order.
groundGreater :: Term -> Term -> Bool
groundGreater s t
  | size s /= size t = size s > size t
  | f /= g = f > g
  | otherwise = case [ (a, b) | (a, b) <- zip as bs, a /= b ] of
      (a, b) : _ -> groundGreater a b
      []         -> False
  where
    size = length . subterms
    (f, as) = parts s
    (g, bs) = parts t
    parts (App h xs) = (h, xs)
    parts (Const c)  = (c, [])
    parts (Fresh x)  = (x, [])
    parts (Var x)    = (x, [])

-- The status of a step the expansion adds, and a parent it cites.
thm :: T.Info
thm = T.Status (T.Standard T.THM)

parent :: String -> T.Parent
parent x = T.Parent (T.UnitSource (unitNameOf x)) []

-- Unit propagation over the cited clauses. Each step resolves with a unit,
-- shortest resolvent first. The prover's refutation is propositional, so a
-- resolvent may only use terms the cited clauses already contain, which also
-- keeps the search finite.
propRefute :: String -> [(String, Clause)] -> Maybe [Step]
propRefute base prem = go prem [] (Set.fromList (map (clauseKey . snd) prem)) (1 :: Int)
  where
    known = Set.fromList (concatMap (clauseTerms . snd) prem)
    go avail steps seen i = do
      (l, r, c) <- nextStep avail seen
      let nm = base ++ "_pr" ++ show i
          -- A ground clause a unit resolved is used no more, since its
          -- resolvent does all it could. Kept, it would be resolved with the
          -- units in every order, one resolvent per subset of its literals.
          spent = [ n | n <- [l, r], Just d <- [lookup n avail], not (isUnitClause d)
                      , null (concatMap litVars (clauseLits d)) ]
      case c of
        Clause [] Nothing -> Just (reverse ((base, l, r, c) : steps))
        _ -> go ([ p | p@(n, _) <- avail, n `notElem` spent ] ++ [(nm, c)])
                ((nm, l, r, c) : steps) (Set.insert (clauseKey c) seen) (i + 1)
    nextStep avail seen = listToMaybe
      (sortOn (\(_, _, c) -> length (body c))
        [ (ln, rn, c)
        | (ln, a) <- avail, (rn, b) <- avail, ln /= rn
        , isUnitClause a || isUnitClause b
        , let b' = suffixVarsClause "_q" b
        , c <- resolveHead a b' ++ resolveHead b' a
        , all (`Set.member` known) (clauseTerms c)
        , Set.notMember (clauseKey c) seen ])

-- The subterms of a clause that are not variables.
clauseTerms :: Clause -> [Term]
clauseTerms (Clause bs mh) = concatMap (filter notVar . foldLiteralTerms subterms) (bs ++ maybeToList mh)

-- Whether a clause has exactly one literal.
isUnitClause :: Clause -> Bool
isUnitClause (Clause bs mh) = length bs + length mh == 1

-- Replaces each demodulation, light_normalisation or theory_normalisation step
-- of iProver by its single rewrites, each by one cited equation at one place,
-- as Vampire prints them. theory_normalisation rewrites with the associativity
-- and commutativity axioms it cites. light_normalisation looks each subterm up
-- among the equations' sides, so it rewrites only a subterm equal to one, with
-- the same variables, as on GRP461-1. iProver cites the clause it rewrites
-- first. Its superposition by a unit equation rewrites more than one place, so
-- a superposition whose clause is none of the premises' superpositions becomes
-- the superposition at one place and the rewrites at the others. A step whose
-- rewrites are not found stays as it is.
expandDemodulation :: [T.Unit] -> [T.Unit]
expandDemodulation units = concatMap expand units
  where
    declOf = Map.fromList [ (unitNameStr n, d) | T.Unit n d _ <- units ]
    clauseOf nm = Map.lookup nm declOf >>= convertDeclToClause
    unitEquations nms = [ (e, (l, rt)) | e <- nms, Just (Clause [] (Just (Eq l rt))) <- [clauseOf e] ]
    expand (T.Unit n d (Just (T.Inference r@(T.Atom rule) info ps, ann)))
      | rule `elem` map Text.pack ["demodulation", "light_normalisation", "theory_normalisation"]
      , p0 : eqNames@(_ : _) <- parents, Just c0 <- clauseOf p0, Just c <- convertDeclToClause d
      , Just steps@(_ : _) <- rewriteChain (rule == Text.pack "light_normalisation") (unitEquations eqNames) c0 c
      = rewrites n d info ann p0 steps
      | rule == Text.pack "superposition"
      , [p1, p2] <- parents, Just a <- clauseOf p1, Just b <- clauseOf p2, Just c <- convertDeclToClause d
      , not (any ((`clauseInstance` c) . snd) (resolvents a b))
      , (r0, later) : _ <- [ x | x@(_, later@(_ : _)) <- replacingSuperpositions a b, clauseInstance (last later) c ]
      , let sup = unitNameStr n ++ "_sup"
      = T.Unit (unitNameOf sup) (clauseToDecl r0) (Just (T.Inference r [thm] (map parent [p1, p2]), Nothing))
        : rewrites n d info ann sup [ (p1, cl) | cl <- later ]
      where
        parents = [ unitNameStr pn | T.Parent (T.UnitSource pn) _ <- ps ]
    expand u = [u]
    -- the single rewrites from clause p0, the last keeping the step's name
    rewrites n d info ann p0 steps =
      let names = [ unitNameStr n ++ "_dm" ++ show i | i <- [1 :: Int ..] ]
          named = zip3 names (p0 : names) steps
          source inf a b = T.Inference (T.Atom (Text.pack "demodulation")) inf (map parent [a, b])
      in [ T.Unit (unitNameOf nm) (clauseToDecl cl) (Just (source [thm] prev e, Nothing)) | (nm, prev, (e, cl)) <- init named ]
         ++ [ T.Unit n d (Just (source info prev e, ann)) | (_, prev, (e, _)) <- [last named] ]

-- iProver's superpositions of the unit equation a into clause b, each as the
-- superposition at one place and the clauses after each rewrite at another.
-- iProver unifies a side l of the equation with a subterm s of a literal of b,
-- instantiates that literal bottom up and puts the other side in for every
-- subterm that has become the instance of s, also where the rewrites below
-- made one, as on GRP116-1.
replacingSuperpositions :: Clause -> Clause -> [(Clause, [Clause])]
replacingSuperpositions (Clause [] (Just (Eq x y))) b =
  [ (r0, later)
  | (l, r) <- [(x, y), (y, x)]
  , (i, (_, lit)) <- zip [0 :: Int ..] lits
  , Just t <- [litAsTerm lit]
  , (p@(_ : _), s) <- places t, notVar s
  , Just θ <- [unifyTerms l s []]
  , let inst = deepApplySubstTerm θ
        points = p : filter (/= p) (replaced inst (inst l) (inst r) t)
        clauseWith u = fromPolLits [ (sg, if j == i then termAsLit lit u else mapLiteralTerms inst m)
                                   | (j, (sg, m)) <- zip [0 ..] lits ]
  , r0 : later <- [ map clauseWith (tail (scanl (\u q -> putTermAt q (inst r) u) (inst t) points)) ] ]
  where
    lits = polLits (suffixVarsClause "_q" b)
    places u = ([], u) : case u of
      App _ us -> [ (j : q, v) | (j, uj) <- zip [0 ..] us, (q, v) <- places uj ]
      _        -> []
replacingSuperpositions _ _ = []

-- The places of the literal term t where iProver's superposition puts r in for
-- l, in the order it makes the rewrites. It instantiates t bottom up and
-- replaces each subterm that has become l. A variable's binding is not looked
-- into.
replaced :: (Term -> Term) -> Term -> Term -> Term -> [[Int]]
replaced inst l r (App _ ts) = concat [ snd (go [j] tj) | (j, tj) <- zip [0 ..] ts ]
  where
    go path u =
      let (u', ps) = case u of
            App f us -> let rs = [ go (path ++ [j]) uj | (j, uj) <- zip [0 ..] us ]
                        in (App f (map fst rs), concatMap snd rs)
            _        -> (inst u, [])
      in if u' == l then (r, ps ++ [path]) else (u', ps)
replaced _ _ _ _ = []

-- The single rewrites that take clause c0 to c, each with the equation it uses
-- and the clause after it. Each literal of c0 is normalised in turn and must
-- give a literal of c with the same sign, an equation either way round.
-- Rewrites keep the variables of c0, which c may name differently, so one
-- renaming of c's variables into c0's is built up along the way, and so is
-- one symbol precedence. iProver orders terms by Knuth-Bendix, or for some
-- theories by a lexicographic path ordering, which is tried when the first
-- gives no rewrites. With exact set, a rewrite needs a side of the equation
-- itself, not an instance.
rewriteChain :: Bool -> [(String, (Term, Term))] -> Clause -> Clause -> Maybe [(String, Clause)]
rewriteChain exact eqs c0 c = listToMaybe (concatMap chain [const kboGreater, lpoGreater])
  where
    chain greater = walk [] ([], []) (polLits c0) (polLits c)
      where
        walk _ _ [] [] = [[]]
        walk done st ((sg, l) : rest) targets =
          [ [ (e, fromPolLits (done ++ (sg, m) : rest)) | (e, m) <- steps ] ++ later
          | (k, (sg', l')) <- zip [0 :: Int ..] targets, sg == sg'
          , (steps, l'', st') <- literal st l l'
          , later <- walk (done ++ [(sg, l'')]) st' rest (take k targets ++ drop (k + 1) targets) ]
        walk _ _ _ _ = []
        literal st (Eq s t) (Eq a b) = sides st s t a b ++ sides st s t b a
        literal st (Rel p as) (Rel q bs)
          | p == q = [ (steps, Rel p xs, st') | (steps, xs, st') <- arguments (Rel p) st [] as bs ]
        literal _ _ _ = []
        sides st s t a b =
          [ ([ (e, Eq x t) | (e, x) <- cs ] ++ [ (e, Eq s' y) | (e, y) <- ct ], Eq s' t', st2)
          | (s', cs, st1) <- normalAs st (unitSide t) a s, (t', ct, st2) <- normalAs st1 (unitSide s) b t ]
        -- the other side of the equation c0 is, when it is one
        unitSide other = case c0 of
          Clause [] (Just (Eq _ _)) -> Just other
          _                         -> Nothing
        -- each argument normalised in turn, its rewrites put back into the literal
        arguments _ st done [] [] = [([], reverse done, st)]
        arguments build st done (a : rest) (b : bs) =
          [ ([ (e, build (reverse done ++ x : rest)) | (e, x) <- sa ] ++ more, xs, st2)
          | (a', sa, st1) <- normalAs st Nothing b a
          , (more, xs, st2) <- arguments build st1 (a' : done) rest bs ]
        arguments _ _ _ _ _ = []
        -- the normal forms of u that are target renamed
        normalAs (ren, prec) other target u =
          [ (u', steps, (ren', prec')) | (u', steps, prec') <- normalForms exact eqs greater other prec u
                                       , Just ren' <- [renaming ren target u'] ]

-- Extends a renaming of the variables of pattern p into those of term u, one
-- to one, so that p renamed is u.
renaming :: [(String, String)] -> Term -> Term -> Maybe [(String, String)]
renaming ren p u = case (p, u) of
  (Var x, Var y) -> case lookup x ren of
    Just y' -> if y == y' then Just ren else Nothing
    Nothing -> if y `elem` map snd ren then Nothing else Just ((x, y) : ren)
  (App f ps, App g us) | f == g, length ps == length us -> foldM (\r (a, b) -> renaming r a b) ren (zip ps us)
  _ -> if p == u then Just ren else Nothing

-- The terms iProver's demodulation may normalise u to, each with the rewrites,
-- by the equation they use and the term after them, and the symbol precedence
-- it needs. It rewrites a term at its root as long as it can, then each
-- argument in turn, and starts again at the root once an argument changed. A
-- rewrite matches one side of an equation and puts in the other, and goes to
-- a smaller term in the ordering greater. Where the precedence of two symbols
-- decides, both orders are tried, the same one for every rewrite. A term met
-- again at the same place ends that replay, so the replays are finite. When u
-- is a side of an equation that is the whole clause, with other the other
-- side, an equation that matches all of u only by renaming rewrites it only
-- when u or the result is smaller than other, as iProver's encompassment
-- condition demands. With exact set, only a term equal to a side matches it.
normalForms :: Bool -> [(String, (Term, Term))] -> ([(String, String)] -> Term -> Term -> Either (String, String) Bool)
            -> Maybe Term -> [(String, String)] -> Term -> [(Term, [(String, Term)], [(String, String)])]
normalForms exact eqs greater other prec0 u0 = normal [] prec0 u0
  where
    apart = if exact then id else suffixVarsLit "_e"
    match a u = if exact then [] <$ guard (a == u) else matchTerm a u
    encompasses prec u σ r = case other of
      Just t | u == u0, all isVariable (map snd σ), length (nub (map snd σ)) == length σ ->
        greater prec t u == Right True || greater prec t r == Right True
      _ -> True
    isVariable (Var _) = True
    isVariable _       = False
    dirs = [ (e, a, b) | (e, (l, r)) <- eqs, (from, to) <- [(l, r), (r, l)]
                       , Eq a b <- [apart (Eq from to)], all (`elem` termVars a) (termVars b) ]
    normal seen prec u = do
      (u1, s1, p1) <- atRoot seen prec u
      case u1 of
        App f as -> do
          (as', s2, p2) <- arguments f [] p1 as
          if as' == as then return (u1, s1, p2) else do
            let u2 = App f as'
            guard (u2 `notElem` (u1 : seen))
            (u3, s3, p3) <- normal (u1 : seen) p2 u2
            return (u3, s1 ++ s2 ++ s3, p3)
        _ -> return (u1, s1, p1)
    -- The rewrites at the root, taken while one applies. A rewrite the
    -- ordering decides is taken whenever one applies. One that waits on the
    -- precedence of two symbols is taken under one order of them, and
    -- stopping assumes the other.
    atRoot seen prec u =
      let rs = [ (e, r, open)
               | notVar u, (e, a, b) <- dirs, Just σ <- [match a u]
               , let r = applySubstTerm σ b, r `notElem` (u : seen), encompasses prec u σ r
               , open <- case greater prec u r of
                   Right True -> [Nothing]
                   Right False -> []
                   Left (f, g) | (f, g) `elem` prec -> [Nothing]
                               | (g, f) `elem` prec -> []
                               | otherwise -> [Just (f, g)] ]
      in [ (u', (e, r) : more, prec'') | (e, r, open) <- rs
                                        , (u', more, prec'') <- atRoot (u : seen) (maybe prec (: prec) open) r ]
         ++ [ (u, [], prec ++ [ (g, f) | (_, _, Just (f, g)) <- rs ]) | all (\(_, _, open) -> isJust open) rs ]
    -- each argument normalised in turn, its rewrites put back into the term
    arguments _ done prec [] = return (reverse done, [], prec)
    arguments f done prec (a : rest) = do
      (a', sa, p1) <- normal [] prec a
      (as', more, p2) <- arguments f (a' : done) p1 rest
      return (as', [ (e, App f (reverse done ++ x : rest)) | (e, x) <- sa ] ++ more, p2)

-- Whether s is greater than t in a Knuth-Bendix ordering that weighs every
-- symbol and variable 1, as iProver's does by default. Where the precedence of
-- two symbols decides, which is not known, they come back, s being greater
-- exactly when the first precedes the second.
kboGreater :: Term -> Term -> Either (String, String) Bool
kboGreater s t
  | any (\x -> count x t > count x s) (termVars t) = Right False
  | size s /= size t = Right (size s > size t)
  | otherwise = case (s, t) of
      _ | s == t -> Right False
      (App f as, App g bs) | f == g -> lexicographic as bs
      (Var _, _) -> Right False
      (_, Var _) -> Right False
      _ -> Left (symbol s, symbol t)
  where
    size = length . subterms
    count x u = length (filter (== Var x) (subterms u))
    lexicographic (a : as) (b : bs) | a == b = lexicographic as bs | otherwise = kboGreater a b
    lexicographic _ _ = Right False
    symbol (App f _) = f
    symbol (Const c) = c
    symbol (Fresh x) = x
    symbol (Var x)   = x

-- Whether s is greater than t in a lexicographic path ordering under the
-- precedence prec, pairs of a greater and a smaller symbol. Where two symbols
-- prec does not order decide, the first such pair comes back, s being greater
-- exactly when its first symbol precedes the second.
lpoGreater :: [(String, String)] -> Term -> Term -> Either (String, String) Bool
lpoGreater prec s t = case (s, t) of
  _ | s == t -> Right False
  (_, Var x) -> Right (x `elem` termVars s)
  (Var _, _) -> Right False
  _ -> anyOf ([ if si == t then Right True else lpoGreater prec si t | si <- ss ] ++ [top])
  where
    (f, ss) = parts s
    (g, ts) = parts t
    dominates = allOf [ lpoGreater prec s tj | tj <- ts ]
    top | f == g               = allOf [lexicographic ss ts, dominates]
        | (f, g) `elem` prec   = dominates
        | (g, f) `elem` prec   = Right False
        | otherwise            = allOf [dominates, Left (f, g)]
    lexicographic (a : as) (b : bs) | a == b = lexicographic as bs | otherwise = lpoGreater prec a b
    lexicographic _ _ = Right False
    parts (App h xs) = (h, xs)
    parts (Const c)  = (c, [])
    parts (Fresh x)  = (x, [])
    parts (Var x)    = (x, [])
    -- true when one is, false when all are, else the first open pair
    anyOf xs = case [ () | Right True <- xs ] of
      _ : _ -> Right True
      []    -> fromMaybe (Right False) (listToMaybe [ x | x@(Left _) <- xs ])
    -- false when one is, true when all are, else the first open pair
    allOf xs = case [ () | Right False <- xs ] of
      _ : _ -> Right False
      []    -> fromMaybe (Right True) (listToMaybe [ x | x@(Left _) <- xs ])

-- The names of the associativity and commutativity axioms of one operator.
data AC = AC { acAssoc :: Maybe String, acComm :: Maybe String }

-- Replaces each ar step by single rewrites with the axioms it cites, which
-- take each condition s = t it removes to t = t. The last rewrite drops the
-- condition and keeps the step's name. A step these rewrites cannot explain
-- stays, so the translation refuses it.
expandACRes :: [T.Unit] -> [T.Unit]
expandACRes units = concatMap expand units
  where
    declOf = Map.fromList [ (unitNameStr n, d) | T.Unit n d _ <- units ]
    clauseOf nm = Map.lookup nm declOf >>= convertDeclToClause
    expand (T.Unit n d (Just (T.Inference (T.Atom rule) info ps, ann)))
      | rule == Text.pack "ar"
      , p0 : axs <- [ unitNameStr pn | T.Parent (T.UnitSource pn) _ <- ps ]
      , Just c0 <- clauseOf p0, Just c <- convertDeclToClause d
      , Just steps@(_ : _) <- acSteps (acTable [ (a, cl) | a <- axs, Just cl <- [clauseOf a] ]) c0 c
      = let names = [ unitNameStr n ++ "_ac" ++ show i | i <- [1 :: Int ..] ]
            named = zip3 names (p0 : names) steps
        in [ T.Unit (unitNameOf nm) (clauseToDecl cl) (Just (rwSource [T.Status (T.Standard T.THM)] prev ax, Nothing))
           | (nm, prev, (ax, cl)) <- init named ]
           ++ [ T.Unit n d (Just (rwSource info prev ax, ann)) | (_, prev, (ax, _)) <- [last named] ]
    expand u = [u]
    rwSource info l r = T.Inference (T.Atom (Text.pack "rw")) info [ T.Parent (T.UnitSource (unitNameOf p)) [] | p <- [l, r] ]

-- The associativity and commutativity axioms among the cited units, by the
-- operator they are about, in either orientation.
acTable :: [(String, Clause)] -> Map.Map String AC
acTable axs = Map.fromListWith merge
  [ (f, ac) | (nm, Clause [] (Just (Eq l r))) <- axs, (f, ac) <- maybeToList (shape nm l r <|> shape nm r l) ]
  where
    merge (AC a c) (AC a' c') = AC (a <|> a') (c <|> c')
    shape nm (App f [Var x, Var y]) (App g [Var y', Var x'])
      | f == g, x == x', y == y', x /= y = Just (f, AC Nothing (Just nm))
    shape nm (App f [App g [Var x, Var y], Var z]) (App h [Var x', App k [Var y', Var z']])
      | all (== f) [g, h, k], [x, y, z] == [x', y', z'] = Just (f, AC (Just nm) Nothing)
    shape _ _ _ = Nothing

-- The rewrites that take each condition c0 has and c lacks to t = t, each with
-- the axiom it uses and the clause after it. The rewrites of a condition end in
-- a clause without it, and the last one is c.
acSteps :: Map.Map String AC -> Clause -> Clause -> Maybe [(String, Clause)]
acSteps table c0 c = do
  guard (hd c0 == hd c && all (`elem` body c0) (body c))
  let removed = [ b | b <- body c0, b `notElem` body c ]
  guard (not (null removed))
  go c0 removed
  where
    go cur [] = guard (all (`elem` body c) (body cur)) >> Just []
    go cur (l@(Eq s t) : rest) = do
      let ss = acNormal table s
          ts = acNormal table t
          s' = maybe s snd (lastOf ss)
          t' = maybe t snd (lastOf ts)
          with x = Clause [ if b == l then x else b | b <- body cur ] (hd cur)
          dropped = Clause (filter (/= l) (body cur)) (hd cur)
          after = map (with . (`Eq` t) . snd) ss ++ map (with . Eq s' . snd) ts
      guard (s' == t' && not (null after))
      later <- go dropped rest
      Just (zip (map fst (ss ++ ts)) (init after ++ [dropped]) ++ later)
    go _ _ = Nothing
    lastOf xs = if null xs then Nothing else Just (last xs)

-- The rewrites that take a term to its AC normal form, each with the axiom it
-- uses and the term after it. Arguments come first. Then a chain of an
-- associative operator is associated to the right, and the operands of a
-- commutative one are sorted, by swapping neighbours.
acNormal :: Map.Map String AC -> Term -> [(String, Term)]
acNormal table t0 = reverse (snd (norm [] (t0, [])))
  where
    norm p st@(t, _) = case termAt p t of
      App f args ->
        let st' = foldl (\s i -> norm (p ++ [i]) s) st [0 .. length args - 1]
        in maybe st' (\ac -> sortChain p f ac (rightAssoc p f ac st')) (Map.lookup f table)
      _ -> st
    -- one rewrite at a position, recorded with its axiom
    step ax p new (t, acc) = let t' = putTermAt p new t in (t', (ax, t') : acc)
    rightAssoc p f ac st@(t, _) = case (acAssoc ac, termAt p t) of
      (Just a, App g [App h [x, y], z]) | g == f, h == f -> rightAssoc p f ac (step a p (App f [x, App f [y, z]]) st)
      (Just _, App g [_, App h [_, _]]) | g == f, h == f -> rightAssoc (p ++ [1]) f ac st
      _ -> st
    -- the operands of the chain at a position
    operands p f t = case termAt p t of
      App g [x, App h [_, _]] | g == f, h == f -> x : operands (p ++ [1]) f t
      App g [x, y] | g == f -> [x, y]
      u -> [u]
    sortChain p f ac st = case (acAssoc ac, acComm ac) of
      (_, Nothing) -> st
      (Nothing, Just c) -> case termAt p (fst st) of
        App g [x, y] | g == f, ppTerm y < ppTerm x -> step c p (App f [y, x]) st
        _ -> st
      (Just a, Just c) ->
        let n = length (operands p f (fst st))
            swapAt s i =
              let ops = operands p f (fst s)
                  q = p ++ replicate i 1
              in if ppTerm (ops !! (i + 1)) >= ppTerm (ops !! i) then s
                 else case termAt q (fst s) of
                   App _ [x, App _ [y, r]] | i < n - 2 ->
                     step a q (App f [y, App f [x, r]])
                       (step c (q ++ [0]) (App f [y, x]) (step a q (App f [App f [x, y], r]) s))
                   App _ [x, y] -> step c q (App f [y, x]) s
                   _ -> s
            pass s = foldl swapAt s [0 .. n - 2]
        in iterate pass st !! n
