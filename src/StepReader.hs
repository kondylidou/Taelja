-- Reads an equational step of an E, Vampire or Twee proof as the rewrites
-- that take one side of its equation to the other, each with its premise and
-- instance. The translation can then show the step without calling a prover.
module StepReader
  ( readableUnits
  , isAtomEquation
  , stepRewrites
  , instantiateChain
  , reverseChain
  ) where

import Control.Applicative ((<|>))
import Data.Bifunctor (bimap)
import Data.List (foldl', nub)
import Data.Maybe (listToMaybe)
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import Types
import Helpers (applySubstTerm, deepApplySubstTerm, diffCtxs, flipDir, matchLit, notVar, placesOf,
                putTermAt, replaceAllTerm, suffixVarsLit, termAt, termCtxs, termVars, unifyApart)
import ProofTree (coreInferenceNames, equationRuleNames)
import TptpConvert (sourceParents, sourceRules, unitNameStr)

-- The units whose whole derivation uses only steps the translation can read
-- itself. These are the equational rules, resolution, which the nuclei
-- replay, and rules outside coreInferenceNames, which only restate a clause.
readableUnits :: [T.Unit] -> Set.Set String
readableUnits = foldl' add Set.empty
  where
    -- a unit's parents come before it in the proof
    add done (T.Unit n _ src)
      | readable src = Set.insert (unitNameStr n) done
      | otherwise    = done
      where
        readable (Just (i@(T.Inference {}), _)) =
          all isRead (sourceRules i) && all (`Set.member` done) (sourceParents i)
        -- a copy is as readable as the unit it copies
        readable (Just (T.UnitSource p, _)) = Set.member (unitNameStr p) done
        readable _ = True
        isRead r = r `elem` equationRuleNames || r == Text.pack "resolution"
                 || Set.notMember r coreInferenceNames
    add done _ = done

-- An equation with an atom on one side, so it rewrites atoms, not terms.
isAtomEquation :: Set.Set String -> Literal -> Bool
isAtomEquation preds (Eq l r) = atom l || atom r
  where
    atom (App f _) = Set.member f preds
    atom (Const c) = Set.member c preds
    atom _         = False
isAtomEquation _ _ = False

-- From one side of an equation to the other by one rewrite with each
-- premise, in either order. Only premise variables are bound, and one left
-- free takes a leaf of the left side, as the premise holds for every value.
-- The result also gives the side the chain starts from and its middle term.
twoRewrites :: Term -> Term -> (Term, Term) -> (Term, Term)
            -> Maybe (Bool, (Int, Dir, Bool, (Term, Term)), (Int, Dir, Bool, (Term, Term)), Term)
twoRewrites gl gr e1 e2 = listToMaybe
  (  [ (False, (1, dA, rA, iA), (2, dB, rB, iB), m) | (dA, rA, iA, dB, rB, iB, m) <- via gl gr e1 e2 ]
  ++ [ (True,  (1, dA, rA, iA), (2, dB, rB, iB), m) | (dA, rA, iA, dB, rB, iB, m) <- via gr gl e1 e2 ]
  ++ [ (False, (2, dA, rA, iA), (1, dB, rB, iB), m) | (dA, rA, iA, dB, rB, iB, m) <- via gl gr e2 e1 ]
  ++ [ (True,  (2, dA, rA, iA), (1, dB, rB, iB), m) | (dA, rA, iA, dB, rB, iB, m) <- via gr gl e2 e1 ] )
  where
    rigid = nub (termVars gl ++ termVars gr)
    leaf  = firstLeaf gl
    via start end ea eb = do
      let ea' = renameEqApart "_t1" ea
          eb' = renameEqApart "_t2" eb
      (dA, fromA, toA) <- rewriteDirections ea'
      (i, (sub, ctx)) <- zip [0 :: Int ..] (termCtxs start)
      Just s1 <- [unifyApart rigid fromA sub []]
      let mid0 = deepApplySubstTerm s1 (ctx toA)
      (dB, fromB, toB) <- rewriteDirections eb'
      -- the second rewrite is the last, so it works where mid0 and end differ
      (k, (sub2, ctx2)) <- zip [0 :: Int ..] (diffCtxs mid0 end)
      Just s2 <- [unifyApart rigid fromB sub2 s1]
      Just s3 <- [unifyApart rigid (deepApplySubstTerm s2 (ctx2 toB)) end s2]
      let mid1 = deepApplySubstTerm s3 mid0
          inst (l, r) = (deepApplySubstTerm s3 l, deepApplySubstTerm s3 r)
          (iA, iB) = (inst ea', inst eb')
          fill = [ (v, leaf) | v <- nub (termVars mid1 ++ concatMap termVars [fst iA, snd iA, fst iB, snd iB])
                             , v `notElem` rigid ]
          filled (l, r) = (deepApplySubstTerm fill l, deepApplySubstTerm fill r)
      return (dA, i == 0, filled iA, dB, k == 0, filled iB, deepApplySubstTerm fill mid1)

-- From one side of an equation to the other when the step rewrote every
-- occurrence of a term in an instance of one premise by the other, as E and
-- Vampire can. The chain undoes those rewrites on the left, applies the
-- rewritten premise at the root and redoes them on the right.
rewriteEveryOccurrence :: Term -> Term -> (Term, Term) -> (Term, Term) -> Maybe [(Int, Dir, Bool, (Term, Term), Term)]
rewriteEveryOccurrence gl gr e1 e2 = listToMaybe (reading 1 e1 2 e2 ++ reading 2 e2 1 e1)
  where
    rigid = nub (termVars gl ++ termVars gr)
    leaf  = firstLeaf gl
    -- premise p is the one rewritten, by premise f
    reading iP p iF f = do
      let p' = renameEqApart "_t1" p
          f' = renameEqApart "_t2" f
      (dF, from, to) <- rewriteDirections f'
      (dP, pl, pr) <- rewriteDirections p'
      -- The rewritten places are every occurrence in the equation of the
      -- rewrite's result, which may be a variable, or every occurrence in the
      -- premise of the term it replaced. The second is needed when the result
      -- also occurs where nothing was rewritten.
      (s1, placesL, placesR) <- leftByRewrite to ++ rewrittenInPremise from to pl pr
      let u = deepApplySubstTerm s1 from
          undone = foldl (\t path -> putTermAt path u t)
      True <- [length placesL + length placesR >= 2]
      True <- [all (\path -> termAt path gl /= u) placesL && all (\path -> termAt path gr /= u) placesR]
      Just s2 <- [unifyApart rigid pl (undone gl placesL) s1]
      Just s3 <- [unifyApart rigid pr (undone gr placesR) s2]
      let app = deepApplySubstTerm s3
          fill = [ (x, leaf) | x <- nub (concatMap (termVars . app) [u, fst p', snd p', fst f', snd f'])
                             , x `notElem` rigid ]
          fin = deepApplySubstTerm fill . app
          u'  = fin u
          instP = bimap fin fin p'
          instF = bimap fin fin f'
          lefts  = drop 1 (scanl (\t path -> putTermAt path u' t) gl placesL)
          midL   = last (gl : lefts)
          midR   = foldl (\t path -> putTermAt path u' t) gr placesR
          rights = drop 1 (scanl (\t path -> putTermAt path (termAt path gr) t) midR placesR)
      True <- [fin pl == midL && fin pr == midR]
      return ( [ (iF, flipDir dF, null path, instF, t) | (path, t) <- zip placesL lefts ]
            ++ [ (iP, dP, True, instP, midR) ]
            ++ [ (iF, dF, null path, instF, t) | (path, t) <- zip placesR rights ] )
    leftByRewrite to = do
      v <- nub [ t | side <- [gl, gr], (t, _) <- termCtxs side ]
      Just s1 <- [unifyApart rigid to v []]
      return (s1, placesOf v gl, placesOf v gr)
    -- a rewrite never applies at a variable of the premise
    rewrittenInPremise from to pl pr = do
      w <- nub [ t | side <- [pl, pr], (t, _) <- termCtxs side, notVar t ]
      Just s1 <- [unifyApart rigid from w []]
      let a = deepApplySubstTerm s1 from
          b = deepApplySubstTerm s1 to
          rewritten = replaceAllTerm a b . deepApplySubstTerm s1
      Just s2 <- [unifyApart rigid (rewritten pl) gl s1]
      Just s3 <- [unifyApart rigid (rewritten pr) gr s2]
      let a' = deepApplySubstTerm s3 from
      return (s3, placesOf a' (deepApplySubstTerm s3 pl), placesOf a' (deepApplySubstTerm s3 pr))

-- A premise with its variables renamed apart from the equation read.
renameEqApart :: String -> (Term, Term) -> (Term, Term)
renameEqApart sfx (l, r) = case suffixVarsLit sfx (Eq l r) of
  Eq l' r' -> (l', r')
  _        -> (l, r)

-- An equation as a rewrite in either direction, giving the direction, the
-- side rewritten and its replacement.
rewriteDirections :: (Term, Term) -> [(Dir, Term, Term)]
rewriteDirections (l, r) = [(LR, l, r), (RL, r, l)]

-- The first leaf of a term. A premise variable no rewrite fixes takes it, so
-- the lines stay small.
firstLeaf :: Term -> Term
firstLeaf t = head ([ u | (u, _) <- termCtxs t, isLeaf u ] ++ [t])
  where
    isLeaf (App _ (_ : _)) = False
    isLeaf _               = True

-- The rewrites, in chain order, that take the left side of a step's equation
-- to the right. Each gives its premise (1 or 2), its direction, whether it is
-- at the root, the premise instance and the term it rewrites to.
stepRewrites :: Term -> Term -> (Term, Term) -> (Term, Term) -> Maybe [(Int, Dir, Bool, (Term, Term), Term)]
stepRewrites gl gr e1 e2 = (inOrder <$> twoRewrites gl gr e1 e2) <|> rewriteEveryOccurrence gl gr e1 e2
  where
    inOrder (back, (ia, dA, rA, iA), (ib, dB, rB, iB), mid)
      | back      = [ (ib, flipDir dB, rB, iB, mid), (ia, flipDir dA, rA, iA, gr) ]
      | otherwise = [ (ia, dA, rA, iA, mid), (ib, dB, rB, iB, gr) ]

-- A chain from pl to pr, reversed when the equation is applied right to left
-- and instantiated to run from `from` to `to`.
instantiateChain :: Dir -> Term -> Term -> (Term, Term) -> (Term, [(UnitEntry, Dir, Term)])
         -> Maybe [(UnitEntry, Dir, Term)]
instantiateChain d from to (pl, pr) (_, steps) = do
  let (a, b, ordered) = case d of
        LR -> (pl, pr, steps)
        RL -> (pr, pl, reverseChain pl steps)
  sigma <- matchLit (Eq a b) (Eq from to)
  return [ (u, dir, applySubstTerm sigma t) | (u, dir, t) <- ordered ]

-- The same chain read backwards, from its last term to its first.
reverseChain :: Term -> [(UnitEntry, Dir, Term)] -> [(UnitEntry, Dir, Term)]
reverseChain start steps =
  reverse [ (u, flipDir d, prev) | ((u, d, _), prev) <- zip steps (start : map (\(_, _, t) -> t) steps) ]
