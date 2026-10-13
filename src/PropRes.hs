-- E may close a refutation with a single cdclpropres step over the clauses its
-- SAT solver used. That step has no unifier for θ to read, so it is replaced
-- by the chain of unit resolutions that derives $false. Unit resolution is
-- complete for Horn clauses, so such a chain exists. Likewise an ar step, E's
-- AC resolution, is replaced by the rewrites with the associativity and
-- commutativity axioms it cites.
module PropRes (expandPropRes, expandACRes) where

import Control.Monad (guard)
import Data.List (sortOn)
import Data.Maybe (listToMaybe, maybeToList)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import Helpers (clauseKey, foldLiteralTerms, notVar, ppTerm, putTermAt, resolveHead, subterms, suffixVarsClause, termAt)
import TptpConvert (clauseToDecl, convertDeclToClause, resolutionSource, unitNameOf, unitNameStr)

-- The name of a derived clause, the names of the two clauses it resolves, and
-- the clause.
type Step = (String, String, String, Clause)

-- Replaces each cdclpropres step by the unit resolutions that derive its $false.
-- The last resolution keeps the step's name.
expandPropRes :: [T.Unit] -> [T.Unit]
expandPropRes units = concatMap expand units
  where
    declOf = Map.fromList [ (unitNameStr n, d) | T.Unit n d _ <- units ]
    -- a cdclpropres step that can be refuted becomes its resolutions, any other unit stays
    expand (T.Unit n _ (Just (T.Inference (T.Atom rule) info ps, ann)))
      | rule == Text.pack "cdclpropres"
      , prem@(_ : _) <- [ (nm, c) | T.Parent (T.UnitSource pn) _ <- ps, let nm = unitNameStr pn
                                  , Just c <- [Map.lookup nm declOf >>= convertDeclToClause] ]
      , Just steps   <- propRefute (unitNameStr n) prem
      = [ T.Unit (unitNameOf nm) (clauseToDecl c) (Just (resolutionSource [T.Status (T.Standard T.THM)] l r, Nothing))
        | (nm, l, r, c) <- init steps ]
        ++ [ T.Unit n (declOf Map.! unitNameStr n) (Just (resolutionSource info l r, ann))
           | (_, l, r, _) <- [last steps] ]
    expand u = [u]

-- Unit propagation over the cited clauses. Each step resolves with a unit,
-- shortest resolvent first. E's refutation is propositional, so a resolvent
-- may only use terms the cited clauses already contain, which also keeps the
-- search finite.
propRefute :: String -> [(String, Clause)] -> Maybe [Step]
propRefute base prem = go prem [] (Set.fromList (map (clauseKey . snd) prem)) (1 :: Int)
  where
    known = Set.fromList (concatMap (clauseTerms . snd) prem)
    -- the subterms of a clause that are not variables
    clauseTerms (Clause bs mh) = concatMap (filter notVar . foldLiteralTerms subterms) (bs ++ maybeToList mh)
    go avail steps seen i = do
      (l, r, c) <- nextStep avail seen
      let nm = base ++ "_pr" ++ show i
      case c of
        Clause [] Nothing -> Just (reverse ((base, l, r, c) : steps))
        _ -> go (avail ++ [(nm, c)]) ((nm, l, r, c) : steps) (Set.insert (clauseKey c) seen) (i + 1)
    nextStep avail seen = listToMaybe
      (sortOn (\(_, _, c) -> length (body c))
        [ (ln, rn, c)
        | (ln, a) <- avail, (rn, b) <- avail, ln /= rn
        , isUnitClause a || isUnitClause b
        , let b' = suffixVarsClause "_q" b
        , c <- resolveHead a b' ++ resolveHead b' a
        , all (`Set.member` known) (clauseTerms c)
        , Set.notMember (clauseKey c) seen ])

-- Whether a clause has exactly one literal.
isUnitClause :: Clause -> Bool
isUnitClause (Clause bs mh) = length bs + length mh == 1

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
    Nothing <|> b = b
    a       <|> _ = a

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
