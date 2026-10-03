-- Shared helpers on terms, literals, clauses and proof blocks. They cover
-- substitution, matching, unification, rewriting, printing symbols and
-- cleaning prover output before it is parsed.
module Helpers where

import Control.Applicative ((<|>))
import Control.Exception (SomeAsyncException, SomeException, fromException, throwIO, try)
import Data.Bifunctor (bimap)
import Data.Char (isAlphaNum, isAsciiLower, isAsciiUpper, isDigit, toUpper)
import Data.Function (on)
import Data.List ((\\), groupBy, inits, intercalate, isPrefixOf, isSuffixOf, nub, partition, permutations, sortOn, tails)
import Data.Maybe (fromMaybe, isJust, listToMaybe)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import Types

-- The variables of a term, in order of appearance.
termVars :: Term -> [String]
termVars (Var x)    = [x]
termVars (Const _)  = []
termVars (Fresh _)  = []
termVars (App _ ts) = concatMap termVars ts

-- The variables of a literal, in order of appearance.
litVars :: Literal -> [String]
litVars = foldLiteralTerms termVars

-- Variables and fresh constants, which a groundness test treats as open.
termOpen :: Term -> [String]
termOpen (Var x)    = [x]
termOpen (Fresh x)  = [x]
termOpen (Const _)  = []
termOpen (App _ ts) = concatMap termOpen ts

-- The variables and fresh constants of a literal.
litOpen :: Literal -> [String]
litOpen = foldLiteralTerms termOpen

-- Fresh constants back to the variables they stand for. They become
-- variables again when a fact is stored or a goal printed, which is sound
-- because no axiom mentions them.
unrigidTerm :: Term -> Term
unrigidTerm (Fresh x)  = Var x
unrigidTerm (App f ts) = App f (map unrigidTerm ts)
unrigidTerm t          = t

-- The fresh constants of a literal back to their variables.
unrigidLit :: Literal -> Literal
unrigidLit = mapLiteralTerms unrigidTerm

-- The fresh constants of a block back to their variables.
unrigidBlock :: ProofBlock -> ProofBlock
unrigidBlock = mapBlockTerms unrigidTerm

-- The results of a function on each argument term of a literal, joined.
foldLiteralTerms :: (Term -> [a]) -> Literal -> [a]
foldLiteralTerms f (Eq l r)    = f l ++ f r
foldLiteralTerms f (NEq l r)   = f l ++ f r
foldLiteralTerms f (Rel _ ts)  = concatMap f ts
foldLiteralTerms f (NRel _ ts) = concatMap f ts

-- A literal with a function applied to each of its argument terms.
mapLiteralTerms :: (Term -> Term) -> Literal -> Literal
mapLiteralTerms f (Eq l r)    = Eq  (f l) (f r)
mapLiteralTerms f (NEq l r)   = NEq (f l) (f r)
mapLiteralTerms f (Rel n ts)  = Rel n  (map f ts)
mapLiteralTerms f (NRel n ts) = NRel n (map f ts)

-- Map over the terms a block prints. The equations a chain cites are left
-- alone, since their variables are their own.
mapShownTerms :: (Term -> Term) -> ProofBlock -> ProofBlock
mapShownTerms f (HaveHence ls)    = HaveHence (map (mapLineLit (mapLiteralTerms f)) ls)
mapShownTerms f (EqChain s steps) = EqChain (f s) [ (rw, f t) | (rw, t) <- steps ]

-- Map over every term of a block, including the equations a chain cites.
mapBlockTerms :: (Term -> Term) -> ProofBlock -> ProofBlock
mapBlockTerms f blk@(HaveHence _) = mapShownTerms f blk
mapBlockTerms f (EqChain s steps) =
  EqChain (f s) [ (rw { rwEq = bimap f f (rwEq rw) }, f t) | (rw, t) <- steps ]

-- Every term of a block in order, including the equations a chain cites.
blockTerms :: ProofBlock -> [Term]
blockTerms (HaveHence ls)    = blockShownTerms (HaveHence ls)
blockTerms (EqChain s steps) = s : concat [ [l, r, t] | (RwStep _ (l, r) _, t) <- steps ]

-- The terms a block prints, in order.
blockShownTerms :: ProofBlock -> [Term]
blockShownTerms (HaveHence ls)    = concatMap (foldLiteralTerms pure . lineLit) ls
blockShownTerms (EqChain s steps) = s : map snd steps

-- A proof line with a function applied to its literal.
mapLineLit :: (Literal -> Literal) -> ProofLine -> ProofLine
mapLineLit f (Have  lit nm) = Have  (f lit) nm
mapLineLit f (And   lit nm) = And   (f lit) nm
mapLineLit f (Hence lit j)  = Hence (f lit) j

-- Applies a substitution to a term once, without chasing bound values.
applySubstTerm :: Subst -> Term -> Term
applySubstTerm subst (Var x)    = fromMaybe (Var x) (lookup x subst)
applySubstTerm _     (Const c)  = Const c
applySubstTerm _     (Fresh x)  = Fresh x
applySubstTerm subst (App f ts) = App f (map (applySubstTerm subst) ts)

-- Applies a substitution to a literal once.
applySubstLit :: Subst -> Literal -> Literal
applySubstLit subst = mapLiteralTerms (applySubstTerm subst)

-- Instantiate a stored block by the substitution that matched its head.
-- Block variables not in the head are local, and those named like a variable
-- in σ's range are renamed first so σ does not capture them.
instantiateBlock :: Literal -> Subst -> ProofBlock -> ProofBlock
instantiateBlock hd σ block =
  mapBlockTerms (applySubstTerm σ) (renameBlock renaming block)
  where
    headVars  = nub (litVars hd)
    locals    = filter (`notElem` headVars) (blockVars block)
    rangeVars = nub (concatMap (termVars . snd) σ)
    clashing  = filter (`elem` rangeVars) locals
    involved  = nub (blockVars block ++ rangeVars ++ map fst σ)
    suffix    = head [ sfx | n <- [1 :: Int ..], let sfx = concat (replicate n "_e")
                           , not (any (sfx `isSuffixOf`) involved) ]
    renaming  = [ (v, v ++ suffix) | v <- clashing ]

-- Replace constants by terms, as when undoing Skolemization.
applyConstSubstTerm :: [(String, Term)] -> Term -> Term
applyConstSubstTerm s (Const c)   = fromMaybe (Const c) (lookup c s)
applyConstSubstTerm s (App f ts)  = App f (map (applyConstSubstTerm s) ts)
applyConstSubstTerm _ t           = t

-- Replace constants by terms in a literal.
applyConstSubstLit :: [(String, Term)] -> Literal -> Literal
applyConstSubstLit s = mapLiteralTerms (applyConstSubstTerm s)

-- A string padded with spaces to the width.
padRight :: Int -> String -> String
padRight n s = s ++ replicate (n - length s) ' '

-- A term and all its subterms, root first.
subterms :: Term -> [Term]
subterms t = t : case t of { App _ ts -> concatMap subterms ts; _ -> [] }

-- The function and constant symbols of a term.
termSymbols :: Term -> [String]
termSymbols (Const c)  = [c]
termSymbols (Var _)    = []
termSymbols (Fresh _)  = []
termSymbols (App f ts) = f : concatMap termSymbols ts

-- The function and constant symbols of a literal.
litSymbols :: Literal -> [String]
litSymbols = foldLiteralTerms termSymbols

-- The function symbols of a literal with its predicate in front.
litNames :: Literal -> [String]
litNames (Rel n ts)  = n : concatMap termSymbols ts
litNames (NRel n ts) = n : concatMap termSymbols ts
litNames l           = litSymbols l

-- Replace every maximal subterm listed, outermost first.
applyTermSubstTerm :: [(Term, Term)] -> Term -> Term
applyTermSubstTerm s t = case lookup t s of
  Just t' -> t'
  Nothing -> case t of
    App f ts -> App f (map (applyTermSubstTerm s) ts)
    _        -> t

-- Replace every maximal subterm listed in a literal.
applyTermSubstLit :: [(Term, Term)] -> Literal -> Literal
applyTermSubstLit s = mapLiteralTerms (applyTermSubstTerm s)

-- Replace every maximal subterm listed in a block, cited equations included.
applyTermSubstBlock :: [(Term, Term)] -> ProofBlock -> ProofBlock
applyTermSubstBlock s = mapBlockTerms (applyTermSubstTerm s)

-- Replace constants by terms in a block, cited equations included.
applyConstSubstBlock :: [(String, Term)] -> ProofBlock -> ProofBlock
applyConstSubstBlock s = mapBlockTerms (applyConstSubstTerm s)

-- Add bindings to a substitution, composing them so one application resolves
-- every variable. Otherwise X ↦ Y then Y ↦ e would leave Y in place and print
-- an instance as a general lemma. Fails when a variable gets two values.
extendSubst :: Subst -> Subst -> Maybe Subst
extendSubst base []           = Just base
extendSubst base ((x,t):rest) =
  let t1 = applySubstTerm base t
  in case lookup x base of
    Nothing -> extendSubst ((x, t1) : [ (y, applySubstTerm [(x, t1)] u) | (y, u) <- base ]) rest
    Just t' -> if t1 == t' then extendSubst base rest else Nothing

-- Matching that threads a substitution, so several patterns share bindings.
matchTermWith :: Term -> Term -> Subst -> Maybe Subst
matchTermWith = matchTermIf (const True)

-- Matching that binds only the pattern variables the predicate allows. Any
-- other variable must meet itself in the target.
matchTermIf :: (String -> Bool) -> Term -> Term -> Subst -> Maybe Subst
matchTermIf bindable (Var x) t s
  | bindable x = case lookup x s of
      Nothing -> Just ((x, t) : s)
      Just t' -> if t == t' then Just s else Nothing
matchTermIf _ (Var x) (Var y) s | x == y = Just s
matchTermIf _ (Const c) (Const d) s | c == d = Just s
matchTermIf _ (Fresh x) (Fresh y) s | x == y = Just s
matchTermIf bindable (App f ts) (App g us) s | f == g, length ts == length us =
  foldl (\ms (p, u) -> ms >>= matchTermIf bindable p u) (Just s) (zip ts us)
matchTermIf _ _ _ _ = Nothing

-- Matches a pattern term against a target, starting from no bindings.
matchTerm :: Term -> Term -> Maybe Subst
matchTerm pat tgt = matchTermWith pat tgt []

-- Matches a pattern literal against a target, starting from no bindings.
matchLit :: Literal -> Literal -> Maybe Subst
matchLit pat tgt = matchLitWith pat tgt []

-- matchLit from a given substitution. Only positive literals match.
matchLitWith :: Literal -> Literal -> Subst -> Maybe Subst
matchLitWith (Eq  l1 r1) (Eq  l2 r2) s
  = matchTermWith l1 l2 s >>= matchTermWith r1 r2
matchLitWith (Rel n1 ts1) (Rel n2 ts2) s
  | n1 == n2, length ts1 == length ts2
  = foldl (\ms (p, u) -> ms >>= matchTermWith p u) (Just s) (zip ts1 ts2)
matchLitWith _ _ _ = Nothing

-- Every subterm of a literal, with a function that puts another term in its
-- place.
litSubtermCtxs :: Literal -> [(Term, Term -> Literal)]
litSubtermCtxs lit = case lit of
  Eq  l r   -> [ (u, (`Eq` r) . c) | (u, c) <- termCtxs l ]
            ++ [ (u, Eq l . c)     | (u, c) <- termCtxs r ]
  NEq l r   -> [ (u, (`NEq` r) . c) | (u, c) <- termCtxs l ]
            ++ [ (u, NEq l . c)     | (u, c) <- termCtxs r ]
  Rel  n ts -> [ (u, Rel  n . c) | (u, c) <- argCtxs ts ]
  NRel n ts -> [ (u, NRel n . c) | (u, c) <- argCtxs ts ]
  where
    argCtxs ts = [ (u, \x -> take i ts ++ [c x] ++ drop (i + 1) ts)
                 | (i, t) <- zip [0 ..] ts, (u, c) <- termCtxs t ]

-- Drop the steps between two visits of the same term in a chain. Joining two
-- derivations can produce such a loop, when one step undoes another. A chain
-- from a term back to itself has no steps left, as s = s holds by reflexivity.
cutLoops :: (s -> Term) -> Term -> [s] -> [s]
cutLoops termOf start steps = reverse (snd (foldl add ([start], []) steps))
  where
    -- the terms visited and the steps kept, newest first
    add (seen, kept) s = case lookup (termOf s) (zip seen [0 :: Int ..]) of
      Just i  -> (drop i seen, drop i kept)
      Nothing -> (termOf s : seen, s : kept)

-- An equation with a variable only on its right side, such as
-- zero = divide(zero,X), brings that variable into the chain, and a later
-- step uses it at one value. Left free, the line would claim more than that
-- step gives, so the variable is bound to the value the step uses.
tightenChainVars :: Term -> [(RwStep, Term)] -> (Term, [(RwStep, Term)])
tightenChainVars start steps =
  (apply start, [ (st, apply t) | (st, t) <- steps ])
  where
    terms    = start : map snd steps
    -- the variables of the first and last term belong to the stated
    -- equation and are never bound
    stmtVars = termVars start ++ termVars (last terms)
    local v  = v `notElem` stmtVars
    apply    = deepApplySubstTerm sigma
    sigma | all (all (`elem` stmtVars) . termVars) terms = []
          | otherwise = foldl bind [] [0 .. length steps - 1]

    -- When the cited equation does not take a line to the next as they
    -- stand, bind the chain's own variables so that it does.
    bind acc i =
      let prev = deepApplySubstTerm acc (terms !! i)
          cur  = deepApplySubstTerm acc (terms !! (i + 1))
          RwStep _ (l, r) dir = fst (steps !! i)
          (l0, r0) = if dir == LR then (l, r) else (r, l)
          -- rename the equation's variables apart from the line's
          apart = [ (v, Var (v ++ "_ax")) | v <- nub (termVars l0 ++ termVars r0) ]
          (lhs, rhs) = (applySubstTerm apart l0, applySubstTerm apart r0)
      in case diffSpine prev cur of
           [] -> acc
           pairs
             | not (any (any local) [ termVars x ++ termVars y | (x, y) <- pairs ]) -> acc
             | any (uncurry (rewrites lhs rhs)) pairs -> acc
             | otherwise -> case concat [ fixup lhs rhs x y | (x, y) <- pairs ] of
                 (rho : _) -> acc ++ rho
                 []        -> acc

    -- The equation takes x to y as they stand. Only the equation's own
    -- variables may be instantiated, not the line's.
    rewrites lhs rhs x y = or
      [ True
      | Just s  <- [matchTerm lhs x]
      , Just s2 <- [matchTerm (applySubstTerm s rhs) y]
      , all (\(v, t) -> t == Var v || v `notElem` (termVars x ++ stmtVars)) s2 ]

    -- bindings of the chain's own variables under which the equation
    -- applies, found by unifying it with the step
    fixup lhs rhs x y =
      [ rho
      | Just s1 <- [unifyTerms lhs x []]
      , Just s2 <- [unifyTerms (deepApplySubstTerm s1 rhs) (deepApplySubstTerm s1 y) s1]
      -- Values may use only the chain's variables, since an equation's
      -- variable means nothing outside its own step.
      , let s2' = [ (v, deepApplySubstTerm s2 t) | (v, t) <- s2 ]
      , let rho = [ b | b@(v, t) <- orient s2'
                      , local v, t /= Var v, v `elem` (termVars x ++ termVars y)
                      , all (`elem` (termVars x ++ termVars y ++ stmtVars)) (termVars t) ]
      , not (null rho)
      , rewrites lhs rhs (deepApplySubstTerm rho x) (deepApplySubstTerm rho y) ]

    -- of two variables, bind the chain's own one, never the statement's
    orient rho = [ case t of
                     Var w | not (local v), local w -> (w, Var v)
                     _                              -> (v, t)
                 | (v, t) <- rho ]

-- Whether the cited equation, in the cited direction, takes a chain line to
-- the next at one subterm or at every occurrence of one instance.
chainStepJustified :: Dir -> (Term, Term) -> Term -> Term -> Bool
chainStepJustified dir (l0, r0) prev cur =
  case diffSpine prev cur of
    []    -> True
    pairs -> or [ once lhs rhs x y | (x, y) <- pairs ] || everywhere lhs rhs
  where
    apart = [ (v, Var (v ++ "_ax")) | v <- nub (termVars l0 ++ termVars r0) ]
    (l, r) = (applySubstTerm apart l0, applySubstTerm apart r0)
    (lhs, rhs) = case dir of { LR -> (l, r); RL -> (r, l) }
    lineVs = termVars prev ++ termVars cur
    once a b x y = or
      [ True
      | Just s  <- [matchTerm a x]
      , Just s2 <- [matchTerm (applySubstTerm s b) y]
      , all (\(v, t) -> t == Var v || v `notElem` lineVs) s2 ]
    everywhere a b = or
      [ replaceAllTerm (applySubstTerm s a) (applySubstTerm s b) prev == cur
      | (u, _) <- termCtxs prev, Just s <- [matchTerm a u]
      , null (termVars (applySubstTerm s b) \\ termVars (applySubstTerm s a)) ]

-- Runs the actions in order and returns the first Just, without running the
-- rest.
firstJustM :: Monad m => [m (Maybe a)] -> m (Maybe a)
firstJustM []         = return Nothing
firstJustM (m : more) = m >>= maybe (firstJustM more) (return . Just)

-- Every occurrence of one subterm replaced by another.
replaceAllTerm :: Term -> Term -> Term -> Term
replaceAllTerm a b t
  | t == a    = b
  | otherwise = case t of
      App f ts -> App f (map (replaceAllTerm a b) ts)
      _        -> t

-- The subterm at a place, a path of argument indices from the root.
termAt :: [Int] -> Term -> Term
termAt (i : path) (App _ ts) = termAt path (ts !! i)
termAt _ t                   = t

-- A term with the subterm at a place replaced.
putTermAt :: [Int] -> Term -> Term -> Term
putTermAt [] new _ = new
putTermAt (i : path) new (App f ts) = App f (take i ts ++ [putTermAt path new (ts !! i)] ++ drop (i + 1) ts)
putTermAt _ _ t = t

-- The places of every occurrence of a subterm.
placesOf :: Term -> Term -> [[Int]]
placesOf v t
  | t == v        = [[]]
  | App _ ts <- t = [ i : path | (i, ti) <- zip [0 ..] ts, path <- placesOf v ti ]
  | otherwise     = []

-- The subterm pairs from the roots of two terms down to the smallest pair
-- holding every difference. A one-step rewrite is at one of these pairs, but
-- not always the smallest, since the replacement can share structure with
-- the redex.
diffSpine :: Term -> Term -> [(Term, Term)]
diffSpine a b
  | a == b = []
  | otherwise = (a, b) : case (a, b) of
      (App f as, App g bs)
        | f == g, length as == length bs
        , [(x, y)] <- [ p | p@(x, y) <- zip as bs, x /= y ] -> diffSpine x y
      _ -> []

-- The subterms of a, with their contexts, where one rewrite might turn a into
-- b, root first. Equal subterms are skipped, and the search stops where the
-- head symbols differ, since no rewrite below can change that symbol.
diffCtxs :: Term -> Term -> [(Term, Term -> Term)]
diffCtxs a b
  | a == b    = []
  | otherwise = (a, id) : case (a, b) of
      (App f as, App g bs)
        | f == g, length as == length bs ->
            [ (u, \x -> App f (take i as ++ [c x] ++ drop (i + 1) as))
            | (i, (ai, bi)) <- zip [0 ..] (zip as bs), (u, c) <- diffCtxs ai bi ]
      _ -> []

-- Every subterm of a term with a function that puts another term in its
-- place, root first.
termCtxs :: Term -> [(Term, Term -> Term)]
termCtxs t = (t, id) : case t of
  App f ts -> [ (u, \x -> App f (take i ts ++ [c x] ++ drop (i + 1) ts))
              | (i, ti) <- zip [0 ..] ts, (u, c) <- termCtxs ti ]
  _        -> []

-- Apply a triangular substitution until nothing changes, so with X ↦ f(Y)
-- and Y ↦ c, X becomes f(c).
deepApplySubstTerm :: Subst -> Term -> Term
deepApplySubstTerm s t =
  let t' = applySubstTerm s t
  in if t' == t then t else deepApplySubstTerm s t'

-- Append a suffix to every variable of a literal, to rename it apart.
suffixVarsLit :: String -> Literal -> Literal
suffixVarsLit suf = mapLiteralTerms go
  where
    go (Var x)    = Var (x ++ suf)
    go (App f ts) = App f (map go ts)
    go t          = t

-- Whether two literals are the same up to renaming of variables.
variantLit :: Literal -> Literal -> Bool
variantLit a b = isJust (matchLit a b) && isJust (matchLit b a)

-- Whether a unit can be cited, because it has a name or a proof.
isCitable :: UnitEntry -> Bool
isCitable u = isJust (ueName u) || isJust (ueProof u)

-- A name as an unquoted TPTP atom, since any other id would make Twee's
-- input unparseable. Other characters become underscores, and an x is
-- prefixed unless the name starts with a lowercase letter.
sanitizeId :: String -> String
sanitizeId nm =
  let body = map (\c -> if isAsciiLower c || isAsciiUpper c || isDigit c || c == '_' then c else '_') nm
  in case body of
       (c : _) | isAsciiLower c -> body
       _                        -> 'x' : body

-- The name an axiom is cited by.
axiomName :: Axiom -> String
axiomName (AUnit n _)    = n
axiomName (ANucleus n _) = n

-- The names axiom 1, axiom 2, ... that are not taken.
freeAxiomNames :: (String -> Bool) -> [String]
freeAxiomNames taken = [ nm | i <- [1 :: Int ..], let nm = "axiom " ++ show i, not (taken nm) ]

-- The position of the provider beside a consumer at a right child.
providerSibling :: String -> Maybe String
providerSibling pos
  | not (null pos), last pos == '1' = Just (init pos ++ "0")
  | otherwise                       = Nothing

-- A name with underscores appended until the predicate leaves it free.
underscoreApart :: (String -> Bool) -> String -> String
underscoreApart taken x = head [ y | y <- iterate (++ "_") x, not (taken y) ]

-- A literal with each variable frozen into a constant named prefix ++ name,
-- and the map that turns the constants back into the variables. The prefix
-- gets underscores until no taken symbol starts with it.
freezeLitVars :: String -> [String] -> Literal -> (Literal, [(String, Term)])
freezeLitVars base taken lit =
  let prefix = underscoreApart (\p -> any (p `isPrefixOf`) taken) base
      pairs  = [ (v, prefix ++ v) | v <- nub (litVars lit) ]
  in (applySubstLit [ (v, Const c) | (v, c) <- pairs ] lit, [ (c, Var v) | (v, c) <- pairs ])

-- An axiom as a clause. A unit axiom is a clause with an empty body.
axiomClause :: Axiom -> Clause
axiomClause (AUnit _ l)    = Clause [] (Just l)
axiomClause (ANucleus _ c) = c

-- The literals of an axiom, its body and then its head.
axiomLits :: Axiom -> [Literal]
axiomLits ax = let Clause bs mh = axiomClause ax in bs ++ maybe [] pure mh

-- A word with its first letter upper case.
capitalize :: String -> String
capitalize (c : cs) = toUpper c : cs
capitalize []       = []

-- Each element of a list with the others, in order.
picks :: [a] -> [(a, [a])]
picks xs = [ (x, before ++ after) | (before, x : after) <- zip (inits xs) (tails xs) ]

-- A clause with a suffix on every variable, so it shares none with another.
suffixVarsClause :: String -> Clause -> Clause
suffixVarsClause suf (Clause bs mh) = Clause (map (suffixVarsLit suf) bs) (fmap (suffixVarsLit suf) mh)

-- A clause with a substitution applied all the way down.
instClause :: Subst -> Clause -> Clause
instClause σ (Clause bs mh) = Clause (map inst bs) (fmap inst mh)
  where inst = mapLiteralTerms (deepApplySubstTerm σ)

-- The resolvents of the first clause's head with each body atom of the
-- second, instantiated. The two clauses must share no variable.
resolveHead :: Clause -> Clause -> [Clause]
resolveHead x y = case hd x of
  Nothing -> []
  Just h  -> [ instClause σ (Clause (body x ++ rest) (hd y))
             | (l, rest) <- picks (body y), Just σ <- [unifyLits h l []] ]

-- Whether a term is not a variable.
notVar :: Term -> Bool
notVar (Var _) = False
notVar _       = True

-- A clause's literals, each with whether it is the head.
polLits :: Clause -> [(Bool, Literal)]
polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]

-- Every term one rewrite of t with the equation in the given direction can
-- give, at the root or at any subterm.
rewriteTermAll :: Term -> (Term, Term) -> Dir -> [Term]
rewriteTermAll t (l, r) dir = rootResult ++ subResults
  where
    (lhs, rhs) = if dir == LR then (l, r) else (r, l)
    rootResult = case matchTerm lhs t of
      Just σ  -> [applySubstTerm σ rhs]
      Nothing -> []
    subResults = case t of
      App f ts -> [ App f (take i ts ++ [u'] ++ drop (i+1) ts)
                  | (i, u) <- zip [0..] ts
                  , u' <- rewriteTermAll u (l, r) dir
                  ]
      _ -> []

-- Whether an equation may rewrite from its first side to its second. A
-- variable side may, at an instance, unless the other side contains it, since
-- no simplification ordering puts a term above one that contains it.
rewritesFrom :: Term -> Term -> Bool
rewritesFrom (Var x) rhs = x `notElem` termVars rhs
rewritesFrom _       _   = True

-- Like try, but rethrows asynchronous exceptions such as an outside timeout
-- or Ctrl-C.
trySync :: IO a -> IO (Either SomeException a)
trySync act = try act >>= either passAsync (return . Right)
  where
    passAsync e = case fromException e :: Maybe SomeAsyncException of
      Just _  -> throwIO e
      Nothing -> return (Left e)

-- A positive atom as the term Twee rewrites (p(t) as a term, p as a constant).
atomTerm :: Literal -> Term
atomTerm (Rel n [])  = Const n
atomTerm (Rel n as)  = App n as
atomTerm l           = error ("atomTerm: not a positive atom: " ++ show l)

-- A term of a relational chain read back as the atom it stands for.
termAtom :: Term -> Maybe Literal
termAtom (App p ts) = Just (Rel p ts)
termAtom (Const p)  = Just (Rel p [])
termAtom _          = Nothing

-- The atoms of a relational chain, without the closing true.
atomTerms :: Term -> [(RwStep, Term)] -> [Term]
atomTerms s steps = s : [ t | (_, t) <- dropLastTrue steps ]
  where dropLastTrue xs = case reverse xs of
          (_, Const "true") : rest -> reverse rest
          _                        -> xs

-- The equation a chain step rewrites with, either an equation or the P = true
-- encoding of a positive atom.
unitEquation :: Literal -> (Term, Term)
unitEquation (Eq a b) = (a, b)
unitEquation l        = (atomTerm l, Const "true")

-- Unify two positive literals, trying equations both ways round.
unifyLits :: Literal -> Literal -> Subst -> Maybe Subst
unifyLits (Eq a b) (Eq c d) σ =
  (unifyTerms a c σ >>= unifyTerms b d) <|> (unifyTerms a d σ >>= unifyTerms b c)
unifyLits (Rel n as) (Rel m bs) σ | n == m, length as == length bs =
  foldr (\(a, b) acc -> acc >>= unifyTerms a b) (Just σ) (zip as bs)
unifyLits _ _ _ = Nothing

-- The opposite direction.
flipDir :: Dir -> Dir
flipDir LR = RL
flipDir RL = LR

-- $false as a literal. A proof derives it to refute the assumption of a
-- negated conjecture, or when the axioms are contradictory and every goal
-- follows from it.
falsumLit :: Literal
falsumLit = Rel "$false" []

-- Whether a block ends on the literal, or on a fact it is an instance of in
-- either orientation. A chain from an atom to true ends on that atom.
blockConcludes :: Literal -> ProofBlock -> Bool
blockConcludes lit blk = case blk of
  HaveHence ls -> case reverse ls of
    (l : _) -> ok (lineLit l)
    []      -> False
  EqChain start steps -> case reverse steps of
    ((_, t) : _) -> ok (Eq start t)
                    || (t == Const "true" && isRelLit lit && start == atomTerm lit)
    []           -> False
  where
    ok l = isJust (matchLitEither l lit [])

-- A literal as a term, sign dropped and = read as a function symbol.
litTerm :: Literal -> Term
litTerm (Rel n as)  = App n as
litTerm (NRel n as) = App n as
litTerm (Eq l r)    = App "=" [l, r]
litTerm (NEq l r)   = App "=" [l, r]

-- A positive literal as a term, so it can be matched, unified or rewritten
-- like one.
litAsTerm :: Literal -> Maybe Term
litAsTerm l | isEqLit l || isRelLit l = Just (litTerm l)
            | otherwise               = Nothing

-- Undo litAsTerm, taking the kind of literal and its predicate from the first
-- argument.
termAsLit :: Literal -> Term -> Literal
termAsLit (Eq _ _) (App "=" [l, r]) = Eq l r
termAsLit (Rel n _) (App _ as)      = Rel n as
termAsLit lit _                     = lit

-- The literal a proof line states.
lineLit :: ProofLine -> Literal
lineLit (Have l _)  = l
lineLit (And l _)   = l
lineLit (Hence l _) = l

-- Whether a block has no lines or no steps.
isEmptyBlock :: ProofBlock -> Bool
isEmptyBlock (HaveHence []) = True
isEmptyBlock (EqChain _ []) = True
isEmptyBlock _              = False

-- Whether a block is an equality chain.
isEqChain :: ProofBlock -> Bool
isEqChain (EqChain {}) = True
isEqChain _            = False

-- A clause's text with variables named by first occurrence, so variants that
-- list their literals in the same order get the same key.
variantKey :: Clause -> String
variantKey (Clause bs mh) = show (Clause (map ren bs) (fmap ren mh))
  where
    ren = renameLit (zip (nub (concatMap litVars bs ++ maybe [] litVars mh))
                         [ "v" ++ show i | i <- [0 :: Int ..] ])

-- Like variantKey, but the same for every order of the body. The body is
-- sorted by the shape of each literal, its variables blanked, and the order
-- giving the smallest text is chosen among literals of the same shape.
clauseKey :: Clause -> String
clauseKey (Clause bs mh) =
  minimum [ variantKey (Clause (concat body) mh) | body <- mapM permutations (groupBy ((==) `on` shape) (sortOn shape bs)) ]
  where
    shape l = show (renameLit [ (v, "_") | v <- litVars l ] l)

-- Whether two clauses are instances of each other, so equal up to renaming.
variantClause :: Clause -> Clause -> Bool
variantClause a b = clauseInstance a b && clauseInstance b a

-- Whether the second clause is an instance of the first.
clauseInstance :: Clause -> Clause -> Bool
clauseInstance c1 c2 = isJust (clauseInstanceSubst c1 c2)

-- The substitution making the second clause an instance of the first, with
-- body literals matched in any order and equations either way round.
clauseInstanceSubst :: Clause -> Clause -> Maybe Subst
clauseInstanceSubst (Clause bs1 h1) (Clause bs2 h2) =
  if length bs1 /= length bs2 then Nothing else (do
    σ <- case (h1, h2) of
      (Just a, Just b)   -> matchLitEither a b []
      (Nothing, Nothing) -> Just []
      _                  -> Nothing
    bodies bs1 bs2 σ)
  where
    bodies [] [] σ = Just σ
    bodies (a : as) bs σ = listToMaybe
      [ σ'' | (b, rest) <- picks bs, Just σ' <- [matchLitEither a b σ], Just σ'' <- [bodies as rest σ'] ]
    bodies _ _ _ = Nothing

-- Extend a substitution so the second literal is an instance of the first,
-- with an equation matched either way round.
matchLitEither :: Literal -> Literal -> Subst -> Maybe Subst
matchLitEither a b σ = matchLitWith a b σ <|> matchLitWith (flipLit a) b σ

-- An equation or disequation the other way round.
flipLit :: Literal -> Literal
flipLit (Eq l r)  = Eq r l
flipLit (NEq l r) = NEq r l
flipLit x         = x

-- Renames the variables of a term by the given pairs.
renameTerm :: [(String, String)] -> Term -> Term
renameTerm r (Var x)    = maybe (Var x) Var (lookup x r)
renameTerm r (App f ts) = App f (map (renameTerm r) ts)
renameTerm _ t          = t

-- Renames the variables of a literal.
renameLit :: [(String, String)] -> Literal -> Literal
renameLit r = mapLiteralTerms (renameTerm r)

-- Renames the variables of a block, cited equations included.
renameBlock :: [(String, String)] -> ProofBlock -> ProofBlock
renameBlock r = mapBlockTerms (renameTerm r)

-- The variables of a block, cited equations included.
blockVars :: ProofBlock -> [String]
blockVars = nub . concatMap termVars . blockTerms

-- The variables a block prints, in order. A chain cites its equations by
-- name only, so their variables are left out and do not use up the first
-- display names.
blockShownVars :: ProofBlock -> [String]
blockShownVars = nub . concatMap termVars . blockShownTerms

-- The names a block cites, such as axioms, lemmas and hypotheses.
blockRefNames :: ProofBlock -> [String]
blockRefNames (HaveHence ls)    = concatMap lineRef ls
  where
    lineRef (Have _ nm)            = [nm]
    lineRef (And _ nm)             = [nm]
    lineRef (Hence _ (ByAxiom nm)) = [nm]
    lineRef (Hence _ (ByRw nm _))  = [nm]
    lineRef (Hence _ ByContradiction) = []
blockRefNames (EqChain _ steps) = [ rwName rw | (rw, _) <- steps ]

-- A block with each name it cites renamed.
renameRefsBlock :: (String -> String) -> ProofBlock -> ProofBlock
renameRefsBlock ren (HaveHence ls) = HaveHence (map go ls)
  where
    go (Have lit nm)            = Have lit (ren nm)
    go (And lit nm)             = And lit (ren nm)
    go (Hence lit (ByAxiom nm)) = Hence lit (ByAxiom (ren nm))
    go (Hence lit (ByRw nm d))  = Hence lit (ByRw (ren nm) d)
    go l@(Hence _ ByContradiction) = l
renameRefsBlock ren (EqChain s steps) =
  EqChain s [ (rw { rwName = ren (rwName rw) }, t) | (rw, t) <- steps ]

-- Adds a line to the end of a have/hence block. A chain cannot take one.
appendLine :: ProofBlock -> ProofLine -> ProofBlock
appendLine (HaveHence ls) l = HaveHence (ls ++ [l])
appendLine (EqChain {})   _ = error "appendLine: cannot extend EqChain"

-- A term as the proof prints it.
ppTerm :: Term -> String
ppTerm (Var x)    = x
ppTerm (Fresh x)  = x
ppTerm (Const c)  = ppSymbol c
ppTerm (App f ts) = ppSymbol f ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

-- A symbol as printed. Words, operators such as ==> and defined symbols such
-- as $false stay bare, and anything else is quoted as in TPTP.
ppSymbol :: String -> String
ppSymbol f
  | all (\c -> isAlphaNum c || c == '_') f || all (`elem` "+*/^<>=-%&|~") f = f
  | ('$' : rest) <- f, all (\c -> isAlphaNum c || c == '_') rest = f
  | otherwise = quoted f

-- A literal as the text output writes it, with ~ and !=.
ppLiteral :: Literal -> String
ppLiteral (Eq l r)    = ppTerm l ++ " = " ++ ppTerm r
ppLiteral (NEq l r)   = ppTerm l ++ " != " ++ ppTerm r
ppLiteral (Rel n [])  = ppSymbol n
ppLiteral (Rel n ts)  = ppSymbol n ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"
ppLiteral (NRel n []) = "~" ++ ppSymbol n
ppLiteral (NRel n ts) = "~" ++ ppSymbol n ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

-- A clause as the text output writes it, body => head, with $false for no head.
ppClause :: Clause -> String
ppClause (Clause [] Nothing)  = "$false"
ppClause (Clause [] (Just h)) = ppLiteral h
ppClause (Clause bs mh)       = intercalate " /\\ " (map ppLiteral bs) ++ " => " ++ maybe "$false" ppLiteral mh

-- A single-quoted TPTP atom, with its quotes and backslashes escaped.
quoted :: String -> String
quoted s = "'" ++ concatMap esc s ++ "'"
  where
    esc c | c `elem` "'\\" = ['\\', c]
          | otherwise      = [c]

-- Unification that never binds a variable in rigid, so the equation being
-- proved keeps its variables while the premises applied to it are
-- instantiated.
unifyApart :: [String] -> Term -> Term -> Subst -> Maybe Subst
unifyApart rigid s0 t0 = go [(s0, t0)]
  where
    go [] th = Just th
    go ((s, t) : rest) th =
      let s' = deepApplySubstTerm th s
          t' = deepApplySubstTerm th t
      in if s' == t' then go rest th else case (s', t') of
        (Var x, _) | x `notElem` rigid -> bind x t' rest th
        (_, Var y) | y `notElem` rigid -> bind y s' rest th
        (App f as, App g bs) | f == g, length as == length bs -> go (zip as bs ++ rest) th
        _ -> Nothing
    bind x t rest th
      | x `elem` termVars t = Nothing
      | otherwise           = go rest ((x, t) : th)

-- Unification with occurs check. The result is triangular, so apply it with
-- deepApplySubstTerm.
unifyTerms :: Term -> Term -> Subst -> Maybe Subst
unifyTerms = unifyApart []

-- Whether a literal is an equation.
isEqLit :: Literal -> Bool
isEqLit (Eq _ _) = True
isEqLit _        = False

-- Whether a literal is a positive atom.
isRelLit :: Literal -> Bool
isRelLit (Rel _ _) = True
isRelLit _         = False

-- An axiom under another display name.
renameAxiom :: String -> Axiom -> Axiom
renameAxiom n (AUnit _ l)    = AUnit n l
renameAxiom n (ANucleus _ c) = ANucleus n c

-- Renames the lemmas and every citation in lemma and goal blocks. The axiom
-- list itself is left as it is.
renameCitations :: Map.Map String String -> StructuredProof -> StructuredProof
renameCitations mapping sp0 = sp0
  { lemmas = [(ren n, lit, renBlock b) | (n, lit, b) <- lemmas sp0]
  , goals  = [(lit, renBlock b)        | (lit, b)    <- goals sp0]
  }
  where
    ren nm   = Map.findWithDefault nm nm mapping
    renBlock = renameRefsBlock ren

-- The names the goal and lemma proofs cite.
citedNames :: StructuredProof -> Set.Set String
citedNames sp = Set.fromList $
  concatMap (blockRefNames . snd) (goals sp) ++
  concatMap (\(_, _, b) -> blockRefNames b) (lemmas sp)

-- Drops the lemmas no goal needs, directly or through other lemmas.
dropUnusedLemmas :: StructuredProof -> StructuredProof
dropUnusedLemmas = fixpoint prune
  where
    prune sp0 =
      let (kept, dropped) = partition (\(nm, _, _) -> Set.member nm (citedNames sp0)) (lemmas sp0)
      in (sp0 { lemmas = kept }, not (null dropped))
    fixpoint f x =
      let (x', changed) = f x
      in if changed then fixpoint f x' else x'
