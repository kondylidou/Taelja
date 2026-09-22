-- E closes a refutation with cdclpropres, one step from the clauses its SAT
-- solver used.  The step states no unifier, so Theorem 1's substitution has
-- nothing to read at that position and leaves the goal's variables to become
-- fresh constants, which no unit then proves.  Over Horn clauses unit
-- propagation is a complete refutation procedure, so the step is replaced here
-- by the chain of binary resolutions propagation takes, each with its own
-- premises and unifier.
module PropRes (expandPropRes) where

import Data.List (inits, sortOn, tails)
import Data.Maybe (listToMaybe, mapMaybe)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import Helpers (clauseKey, deepApplySubstTerm, mapLiteralTerms, suffixVarsLit, unifyLits)
import TptpConvert (clauseToDecl, convertDeclToClause)

-- A derived clause with the two units it resolves.
type Step = (String, String, String, Clause)

expandPropRes :: [T.Unit] -> [T.Unit]
expandPropRes units = concatMap expand units
  where
    declOf = Map.fromList [ (unitName n, d) | T.Unit n d _ <- units ]
    expand u@(T.Unit n _ (Just (T.Inference (T.Atom rule) info ps, ann)))
      | rule == Text.pack "cdclpropres"
      , prem@(_ : _) <- mapMaybe clauseOf (parentNames ps)
      , Just steps   <- propRefute (unitName n) prem
      = [ T.Unit (mkName nm) (clauseToDecl c) (Just (mkSource l r, Nothing))
        | (nm, l, r, c) <- init steps ]
        ++ [ case last steps of
               (_, l, r, _) -> T.Unit n (declOf Map.! unitName n)
                                        (Just (T.Inference (T.Atom (Text.pack "resolution")) info
                                                           [parentOf l, parentOf r], ann)) ]
      | otherwise = [u]
    expand u = [u]

    clauseOf nm = do
      d <- Map.lookup nm declOf
      c <- convertDeclToClause d
      return (nm, c)

    mkName nm = Left (T.Atom (Text.pack nm))
    parentOf nm = T.Parent (T.UnitSource (mkName nm)) []
    mkSource l r = T.Inference (T.Atom (Text.pack "resolution"))
                               [T.Status (T.Standard T.THM)]
                               [parentOf l, parentOf r]

unitName :: T.UnitName -> String
unitName (Left (T.Atom t)) = Text.unpack t
unitName (Right n)         = show n

parentNames :: [T.Parent] -> [String]
parentNames ps = [ unitName pn | T.Parent (T.UnitSource pn) _ <- ps ]

-- Unit propagation over the cited clauses, as the chain of resolutions that
-- derives $false.  Only a resolution with a unit is taken, which is what
-- propagation does and what keeps the clauses shrinking, and the shortest
-- resolvent is taken first so a fact is used as soon as it is there.
propRefute :: String -> [(String, Clause)] -> Maybe [Step]
propRefute base prem = go prem [] (Set.fromList (map (clauseKey . snd) prem)) (1 :: Int)
  where
    go avail steps seen i = case nextStep avail seen of
      Nothing -> Nothing
      Just (l, r, c)
        | isFalseClause c -> Just (reverse ((base, l, r, c) : steps))
        | otherwise ->
            let nm = base ++ "_pr" ++ show i
            in go (avail ++ [(nm, c)]) ((nm, l, r, c) : steps)
                  (Set.insert (clauseKey c) seen) (i + 1)

    nextStep avail seen = listToMaybe
      (sortOn (\(_, _, c) -> length (body c))
        [ (ln, rn, c)
        | (ln, a) <- avail, (rn, b) <- avail, ln /= rn
        , isUnitClause a || isUnitClause b
        , (_, c) <- resolvents' a b
        , Set.notMember (clauseKey c) seen ])

isUnitClause :: Clause -> Bool
isUnitClause (Clause bs mh) = length bs + length mh == 1

isFalseClause :: Clause -> Bool
isFalseClause (Clause bs mh) = null bs && null mh

-- Resolution of the two clauses, the head of one against a body literal of
-- the other, with their variables renamed apart.
resolvents' :: Clause -> Clause -> [(Bool, Clause)]
resolvents' a b =
  [ (True, r) | r <- headInto a b' ] ++ [ (False, r) | r <- headInto b' a ]
  where
    b' = Clause (map (suffixVarsLit "_q") (body b)) (fmap (suffixVarsLit "_q") (hd b))
    headInto x y = case hd x of
      Nothing -> []
      Just h  ->
        [ inst sigma (Clause (body x ++ rest) (hd y))
        | (l, rest) <- picks (body y), Just sigma <- [unifyLits h l []] ]
    inst sigma (Clause bs mh) =
      Clause (map (mapLiteralTerms (deepApplySubstTerm sigma)) bs)
             (fmap (mapLiteralTerms (deepApplySubstTerm sigma)) mh)
    picks xs = [ (x, before ++ after) | (before, x : after) <- zip (inits xs) (tails xs) ]
