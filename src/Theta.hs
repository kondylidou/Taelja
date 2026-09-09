-- Algorithm 1's θ (paper, Section 4): the one substitution derived from the
-- input proof, traced top-down from the root, and the coherence check that
-- validates an assembled hyperresolution step before it is emitted.
module Theta
  ( ThetaCtx (..)
  , computeNucleusTheta
  , sharedNodeTheta
  , resolutionCoherent
  ) where

import Control.Applicative ((<|>))
import Control.Monad (foldM)
import Data.Bifunctor (second)
import Data.List (nub, partition, sortBy)
import Data.Maybe (catMaybes, fromMaybe, isJust, listToMaybe)
import Data.Ord (comparing)
import qualified Data.Map.Lazy as LMap
import qualified Data.Map.Strict as Map
import qualified Data.TPTP as T

import Types
import Helpers
import TptpConvert (convertDeclToClause)

-- θ as the paper defines it (Section 4, Algorithm 1): the one substitution
-- derived from the input proof, shared by both stages (the --debug "θ = {...}"
-- line shows it). See nodeThetaMap for how a position's θ|p is traced.
-- What computeNucleusTheta needs: the proof entries and the clause at every
-- tree position.
data ThetaCtx = ThetaCtx
  { tcDeclAt  :: Map.Map String T.Declaration
  , tcSimpl   :: Map.Map String [(String, Dir)]  -- demodulation chain folded into the inference at a position
  , tcEqOf    :: String -> Maybe (Term, Term)    -- the chain's equations by name
  , tcShared  :: LMap.Map String Subst  -- θ|p for every position, computed once per run (see sharedNodeTheta)
  }

-- The prover may fold a demodulation into the inference (E's rw around an
-- spm step): the conclusion the proof shows is then the head instance after
-- rewriting.  The recorded chain is replayed on the abstract head, as
-- rw_chain does for electrons, and the paper's match is applied to that.
computeNucleusTheta :: ThetaCtx -> LeafEntry -> Subst
computeNucleusTheta ctx entry =
  let abstractDecl = if leRole entry == OrigAxiom then leSrcDecl entry else leDecl entry
      leafClause = convertDeclToClause abstractDecl
      θraw = nodeTheta (tcDeclAt ctx) (tcShared ctx) leafClause unrewritten (lePos entry)
      -- a variable the proof merely renames to a parent variable it never
      -- instantiates (and links to nothing else) is one θ leaves free
      loneRename (_, Var w) = length [ () | (_, t) <- θraw, w `elem` termVars t ] == 1
      loneRename _          = False
      θ = filter (not . loneRename) θraw
      -- Paper (Thm. 6, θ'_k): variables occurring in the head but in no body
      -- literal stay free, so the derived electron is as general as the
      -- proof allows (e.g. c_plus(c_0,Y,X) = Y keeps Y)
      headOnly = case convertDeclToClause (leSrcDecl entry) of
        Just (Clause bs (Just h)) -> filter (`notElem` concatMap litVars bs) (litVars h)
        _                          -> []
  in filter (\(v, _) -> v `notElem` headOnly) θ
  where
    pos = lePos entry
    chain = Map.findWithDefault [] pos (tcSimpl ctx)
    -- the conclusion as it was before the demodulation folded into this
    -- inference (the literal Algorithm 1 assumes to be there)
    unrewritten c = if null chain then c else fromMaybe c (unrewriteLit (tcEqOf ctx) c chain)

-- θ|p for every position p in the tree, traced top-down from the root: a
-- node's literals are matched into its parent's literals after the parent's
-- own θ is applied, so instantiations propagate through non-ground inner
-- clauses. Exactly one literal may fail to match — the one resolved away or
-- rewritten at the parent inference — and the sibling only breaks a tie over
-- which one, contributing no bindings itself. A resolved-away literal's
-- variables stay free (the paper's τ); a rewritten literal's are instantiated
-- through the rewrite.
--
-- sharedBase already holds θ|p for most positions (computed once, shared
-- across every nucleus); only leafPos is recomputed here, with leafClause's
-- override applied on top. That's safe because the override only ever
-- touches leafPos itself, never an ancestor or sibling reached while
-- computing it — so the shared, generic value is exactly what this call
-- would derive for that position anyway.
nodeThetaMap :: Map.Map String T.Declaration -> LMap.Map String Subst -> Maybe Clause -> (Literal -> Literal) -> String -> LMap.Map String Subst
nodeThetaMap declAt sharedBase leafClause unrewriteParentHead leafPos = memo
  where
    -- the leaf itself uses its abstract (source) clause; ancestors and
    -- siblings come from the real tree
    clauseOf p | p == leafPos = leafClause
               | otherwise    = Map.lookup p declAt >>= convertDeclToClause
    polLits (Clause bs mh) = [ (False, l) | l <- bs ] ++ [ (True, h) | Just h <- [mh] ]

    -- go p recurses into both the parent chain and each sibling's parent
    -- chain; memoise per position or the sharing explodes exponentially in
    -- the tree depth.  The map must be VALUE-LAZY (Data.Map.Lazy): a strict
    -- map would force every position eagerly and loop on the mutual
    -- parent/sibling references (which are only demanded selectively).
    -- sharedBase is consulted first (left-biased union): when it already
    -- covers every position (as sharedNodeTheta's result does), the
    -- generic fallback on the right is never actually forced for anything
    -- but leafPos, which is inserted on top regardless.
    memo :: LMap.Map String Subst
    memo = LMap.insert leafPos (compute leafPos)
             (sharedBase `LMap.union`
               LMap.mapWithKey (\p _ -> compute p) (LMap.fromAscList (Map.toAscList declAt)))

    go p = LMap.findWithDefault [] p memo

    compute "" = []
    compute p  = fromMaybe [] $ do
      let pp = init p
          θP = go pp
          sp = pp ++ [if last p == '0' then '1' else '0']
      pc <- clauseOf pp
      cc <- clauseOf p
      -- the leaf's parent shows the conclusion after any demodulation folded
      -- into the inference; its head is taken as it was before
      let parentWith sub = [ (b, suffixVarsLit "_p" (applySubst sub (if b && p == leafPos then unrewriteParentHead l else l)))
                           | (b, l) <- polLits pc ]
          childLits  = polLits cc
          mSib       = Map.lookup sp declAt >>= convertDeclToClause
          isProv     = last p == '0' && isJust mSib
          -- the parent's θ in the child's view of the parent's variables
          θPs        = [ (v ++ "_p", sufT t) | (v, t) <- θP ]
          sufT (Var x)    = Var (x ++ "_p")
          sufT (App f ts) = App f (map sufT ts)
          sufT t          = t
      -- The paper's match is into C₀σ, the parent's clause as the prover
      -- printed it, and θ is applied afterwards (σθ): matching the printed
      -- clause keeps the orientation the inference used (an equation head
      -- read the other way round is not the same instance) and the parent's
      -- variables are then instantiated by the parent's own θ.  Only when
      -- nothing matches the printed clause is the instantiated one tried.
      -- The premise at p0 provides the literal the parent inference consumes
      -- (the paper's tree order); the premise at p1 keeps its head.
      return $ case groundChild isProv childLits (parentWith []) mSib (go sp) of
        Just s  -> [ (v, applySubstTerm θPs t) | (v, t) <- s ]
        Nothing -> fromMaybe [] (groundChild isProv childLits (parentWith θP) mSib (go sp))

    -- Match child literals into parent literals (each parent literal used at
    -- most once), allowing skips; prefer the fewest skips.
    matchInto [] ps s = [(s, [], ps)]
    matchInto (c : cs) ps s =
      [ (s'', sk, un)
      | (m, rest) <- picks ps
      , s' <- matchPol c m s
      , (s'', sk, un) <- matchInto cs rest s' ]
      ++ [ (s'', c : sk, un) | (s'', sk, un) <- matchInto cs ps s ]

    picks xs = [ (x, take i xs ++ drop (i + 1) xs) | (i, x) <- zip [0 ..] xs ]

    -- both orientations of an equation are candidates (as the inference
    -- oriented it first); the sibling decides between them when they tie
    matchPol (b1, l1) (b2, l2) s
      | b1 /= b2  = []
      | otherwise = nub (catMaybes [matchLitWith l1 l2 s, matchLitWith (flipLit l1) l2 s])

    notVar (Var _) = False
    notVar _       = True

    groundChild isProvider childLits parentLits mSib θSib =
      let (heads, bodies) = partition fst childLits
          -- a provider's head is what the parent consumes; only its body
          -- survives into the conclusion (it must not be matched, even if the
          -- conclusion happens to be an instance of it).  A consumer keeps
          -- its head and loses one body literal, so candidates that match
          -- the head come first.
          (lits, forced) = if isProvider then (bodies, heads) else (childLits, [])
          key sk = (any fst sk, length sk)
          cands = map snd $ sortBy (comparing fst)
                    [ (key sk', (s, sk', un)) | (s, sk, un) <- matchInto lits parentLits []
                                              , let sk' = forced ++ sk ]
          childVars = concatMap (litVars . snd) childLits
          restrict = filter ((`elem` childVars) . fst)
      in case cands of
        [] -> Nothing
        ((s0, sk0, _) : _)
          | null sk0  -> Just (restrict s0)        -- every literal accounted for
          | otherwise -> Just $
              -- several candidates may tie (e.g. a symmetric head); the
              -- sibling decides which literal the parent consumed
              let tied  = takeWhile (\(_, sk, _) -> key sk == key sk0) cands
              -- (an explanation that needs the literal flipped, e.g. a
              -- symmetric equation, is taken only if no candidate is
              -- explained as the inference oriented it)
              in restrict $ fromMaybe s0 $ listToMaybe
                   ([ s' | c <- tied, Just s' <- [explain False c] ]
                    ++ [ s' | c <- tied, Just s' <- [explain True c] ])
      where
       matchOrFlipped allowFlip l1 l2 s =
         matchLitWith l1 l2 s <|> (if allowFlip then matchLitWith (flipLit l1) l2 s else Nothing)
       explain allowFlip (s, skipped, unused) =
          -- unit child resolved against a body literal of the sibling nucleus:
          -- its instance is that body literal under the sibling's θ (the body
          -- literal that does not survive into the parent is the resolved one)
          let resolvedAgainstSib = case (skipped, mSib) of
                ([(True, lC)], Just (Clause sbs _))
                  | length childLits == 1, not (null sbs) ->
                      let sibBody = [ (False, applySubst θSib l) | l <- sbs ]
                          skippedSib = case sortBy (comparing (\(_, sk, _) -> length sk))
                                              (matchInto sibBody parentLits []) of
                            ((_, sk, _) : _) -> sk
                            []               -> []
                      in s <$ listToMaybe
                           [ () | (_, lS) <- skippedSib
                                , Just _ <- [matchOrFlipped allowFlip lC lS s] ]
                _ -> Nothing
              -- child literal rewritten at the parent by the sibling unit equation
              asRewritten = case (skipped, unused, mSib) of
                ([(bS, lS)], [(bU, lU)], Just (Clause [] (Just (Eq a b))))
                  | bS == bU -> listToMaybe
                      [ s'
                      | let lSi = applySubst s lS
                      , (u, ctx) <- litSubtermCtxs lSi
                      , notVar u   -- rewrite rules apply to non-variable subterms
                      , let a' = suffixVarsLit "_r" (Eq a b)
                      , (lhs, rhs) <- case a' of { Eq x y -> [(x, y), (y, x)]; _ -> [] }
                      , Just (σR, ρC) <- [matchBothTerm lhs u [] []]
                      , let lS' = applySubst ρC (ctx (applySubstTerm σR rhs))
                      , Just s' <- [matchLitWith lS' lU (s ++ ρC)] ]
                _ -> Nothing
              -- child IS the unit equation used as a rewrite rule at the parent:
              -- only the variables of its rewriting side reach the conclusion
              asRule = case (skipped, mSib) of
                ([(True, Eq a b)], Just sibC)
                  | length childLits == 1 -> listToMaybe
                      [ [ (v, applySubstTerm s'' t) | (v, t) <- σC, v `elem` termVars rhs ]
                      | (bS, lS) <- map (second (suffixVarsLit "_s")) (polLits sibC)
                      , (bP, lP) <- parentLits
                      , bS == bP
                      , (lhs, rhs) <- [(a, b), (b, a)]
                      , (u, ctx) <- litSubtermCtxs lS
                      , notVar u
                      , Just (σC, ρS) <- [matchBothTerm lhs u [] []]
                      , let lS' = applySubst ρS (ctx (applySubstTerm σC rhs))
                      , Just s'' <- [matchLitWith lS' lP []] ]
                _ -> Nothing
              -- body literal resolved against the sibling unit: its variables stay
              -- free.  The candidate is explained when the literal, under it,
              -- still unifies with the unit (the inference's own criterion,
              -- occurs check included).  A one-sided match in either direction
              -- is wrong here: the literal may hold a constant where the unit
              -- has a variable, and the unit a variable where the literal has
              -- one (GRP012-3/E: product(identity,X1,X2) against
              -- product(Y,Z,multiply(Y,Z)) explains only the orientation of
              -- the head that binds X2 to multiply(identity,X1)).
              bodyVsSibUnit = case (skipped, mSib) of
                ([(False, lS)], Just (Clause [] (Just sl))) ->
                  let sl' = suffixVarsLit "_s" sl
                  in case unifyOrFlipped allowFlip (applySubst s lS) sl' of
                       Just _  -> Just s
                       Nothing -> Nothing
                _ -> Nothing
              unifyOrFlipped allowFlip' l1 l2 =
                unifyOriented l1 l2 <|> (if allowFlip' then unifyOriented (flipLit l1) l2 else Nothing)
              unifyOriented (Eq a b) (Eq c d) = unifyTerms a c [] >>= unifyTerms b d
              unifyOriented l1 l2             = unifyLits l1 l2 []
          in asRewritten <|> asRule <|> bodyVsSibUnit <|> resolvedAgainstSib

-- One position's θ|p, per computeNucleusTheta's call.
nodeTheta :: Map.Map String T.Declaration -> LMap.Map String Subst -> Maybe Clause -> (Literal -> Literal) -> String -> Subst
nodeTheta declAt sharedBase leafClause unrewriteParentHead leafPos =
  LMap.findWithDefault [] leafPos (nodeThetaMap declAt sharedBase leafClause unrewriteParentHead leafPos)

-- Computed once per run, before any nucleus is processed: θ|p for every
-- position, generic throughout since "\0" can never equal a real position
-- (all real ones are '0'/'1' strings), so nodeThetaMap's override never
-- fires. Each nucleus's computeNucleusTheta call passes this as sharedBase,
-- adding only its own leaf's entry on top instead of re-tracing the tree.
sharedNodeTheta :: Map.Map String T.Declaration -> LMap.Map String Subst
sharedNodeTheta declAt = nodeThetaMap declAt LMap.empty Nothing id "\0"

-- Validates one assembled hyperresolution step: the rule's body atoms are
-- unified (shared rule variables, fresh-renamed) against the matched electron
-- targets; the step is coherent when the unifier exists and the head it
-- derives covers the head instance about to be stored.  This is the same
-- judgement the Lean check makes, applied before anything is emitted, so a
-- spurious premise match cannot justify a θ-derived head (LCL416-1).
resolutionCoherent :: [Literal] -> Literal -> [Literal] -> Literal -> Bool
resolutionCoherent bodyAbs headAbs targets headInst
  -- a step whose conclusion is one of its own premises is vacuous
  | headInst `elem` targets = False
  | otherwise =
  case foldM step [] (zip bodyAbs' targets) of
    Nothing -> False
    Just s  ->
      let derived = mapLitTerms (deepApplySubstTerm s) headAbs'
      in derived `notElem` targets
         && (derived == headInst || isJust (matchLit derived headInst)
         || (case (derived, headInst) of
               (Eq l r, _) -> let d' = Eq r l
                              in d' == headInst || isJust (matchLit d' headInst)
               _           -> False))
  where
    ren = suffixVarsLit "_rc"
    bodyAbs' = map ren bodyAbs
    headAbs' = ren headAbs
    -- equations may have been matched in flipped orientation
    step s (b, t) = case (litTerm b, litTerm t) of
      (Just tb, Just tt) -> case unifyTerms tb tt s of
        Just s' -> Just s'
        Nothing -> case t of
          Eq l r -> litTerm (Eq r l) >>= \tt' -> unifyTerms tb tt' s
          _      -> Nothing
      _                  -> Nothing
    litTerm (Rel n as) = Just (App n as)
    litTerm (Eq l r)   = Just (App "=" [l, r])
    litTerm _          = Nothing
    mapLitTerms f (Rel n as) = Rel n (map f as)
    mapLitTerms f (Eq l r)   = Eq (f l) (f r)
    mapLitTerms _ l          = l
