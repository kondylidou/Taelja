-- E may close a refutation with a single cdclpropres step over the clauses its
-- SAT solver used. That step has no unifier for θ to read, so it is replaced
-- by the chain of unit resolutions that derives $false. Unit resolution is
-- complete for Horn clauses, so such a chain exists.
module PropRes (expandPropRes) where

import Data.List (sortOn)
import Data.Maybe (listToMaybe, maybeToList)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import Helpers (clauseKey, foldLiteralTerms, notVar, resolveHead, subterms, suffixVarsClause)
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
