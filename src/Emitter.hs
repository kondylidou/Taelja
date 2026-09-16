module Emitter (emit, applyRenaming, pruneUnusedLemmas, axiomRenaming, blockRenaming) where

import Data.Char (toUpper)
import Data.List (intercalate, isPrefixOf, nub, partition)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Types
import Helpers

cap :: String -> String
cap s = toUpper (head s) : tail s

emit :: StructuredProof -> String
emit sp0 = unlines $ concat
  [ axiomLines (axioms sp)
  , [ "" | not (null (axioms sp)) ]
  , concatMap (lemmaLines hyps (lemmaDeps (lemmas sp))) (lemmas sp)
  , intercalate [""] (zipWith (goalLines hyps negated) [1..] (goals sp))
  ]
  where
    hypNames = Map.keysSet (inHypotheses (spInput sp0))
    negated  = inNegated (spInput sp0)
    -- the hypotheses in the order the goal states them, the antecedent's
    -- first, named assumption 1, 2, ... in that order
    hyps0    = [ ax | ax <- axioms sp0, Set.member (axiomName ax) hypNames ]
    (negHyps0, anteHyps0) = partition ((`elem` negated) . axiomName) hyps0
    hyps     = [ setAxName ("assumption " ++ show i) ax | (i, ax) <- zip [1 :: Int ..] (anteHyps0 ++ negHyps0) ]
    assumptionNames = Map.fromList (zip (map axiomName (anteHyps0 ++ negHyps0)) (map axiomName hyps))
    sp       = renumberAxioms (pruneUnusedLemmas (dropHypotheses assumptionNames sp0))

setAxName :: String -> Axiom -> Axiom
setAxName n (AUnit _ l)    = AUnit n l
setAxName n (ANucleus _ c) = ANucleus n c

-- The assumptions each lemma rests on, through the lemmas it cites.
lemmaDeps :: [(String, Literal, ProofBlock)] -> Map.Map String [String]
lemmaDeps ls = fixpoint (Map.fromList [ (n, direct b) | (n, _, b) <- ls ])
  where
    direct b = nub [ r | r <- blockRefNames b, "assumption " `isPrefixOf` r ]
    fixpoint m =
      let m' = Map.fromList [ (n, nub (direct b ++ concat [ Map.findWithDefault [] r m | r <- blockRefNames b ]))
                            | (n, _, b) <- ls ]
      in if m' == m then m else fixpoint m'

axiomName :: Axiom -> String
axiomName (AUnit n _)    = n
axiomName (ANucleus n _) = n

axiomVars :: Axiom -> [String]
axiomVars (AUnit _ l)                 = litVars l
axiomVars (ANucleus _ (Clause bs mh)) = concatMap litVars bs ++ maybe [] litVars mh

-- The hypotheses of an implication conjecture are assumed in the goal's proof
-- rather than listed as axioms, and a step citing one names the assumption.
dropHypotheses :: Map.Map String String -> StructuredProof -> StructuredProof
dropHypotheses names sp =
  (applyRenaming names sp)
    { axioms = [ ax | ax <- axioms sp, Map.notMember (axiomName ax) names ] }

-- Renumber axioms to close the gaps left by lemma promotion, and update every
-- reference in lemma and goal blocks.
renumberAxioms :: StructuredProof -> StructuredProof
renumberAxioms sp =
  let oldNames = [ case ax of AUnit n _ -> n; ANucleus n _ -> n
                 | ax <- axioms sp ]
      renaming  = Map.fromList (zip oldNames
                    ["axiom " ++ show i | i <- [(1 :: Int) ..]])
      newAxioms = zipWith setName [(1 :: Int) ..] (axioms sp)
      setName i (AUnit    _ lit) = AUnit    ("axiom " ++ show i) lit
      setName i (ANucleus _ cls) = ANucleus ("axiom " ++ show i) cls
  in (applyRenaming renaming sp) { axioms = newAxioms }

-- A single global renaming covers all axiom entries so that a variable shared
-- across multiple axioms (including non-unit clauses) gets the same display name.
axiomLines :: [Axiom] -> [String]
axiomLines entries = map ppEntry entries
  where
    globalRenaming = axiomRenaming entries
    ppEntry (AUnit n l)    = cap n ++ ": " ++ ppLiteral (renameLit globalRenaming l)
    ppEntry (ANucleus n c) = cap n ++ ": " ++ ppClauseWith globalRenaming c

axiomRenaming :: [Axiom] -> [(String, String)]
axiomRenaming entries = zip (nub (concatMap axiomVars entries)) prettyVarNames

ppClauseWith :: [(String, String)] -> Clause -> String
ppClauseWith renaming (Clause bodyLits mHead) =
  ppBodies renamedBody ++ " => " ++ maybe "$false" ppLiteral renamedHead
  where
    renamedBody  = map (renameLit renaming) bodyLits
    renamedHead  = fmap (renameLit renaming) mHead
    ppBodies []  = "(empty)"
    ppBodies [l] = ppLiteral l
    ppBodies ls  = intercalate " /\\ " (map ppLiteral ls)

prettyVarNames :: [String]
prettyVarNames = ["X", "Y", "Z", "A", "B", "C", "U", "V", "W"]
              ++ ["X" ++ show n | n <- [(1 :: Int)..]]

-- Variable names are local to each block.  The same name may mean different
-- things in different lemmas, as is usual in mathematics.
blockRenaming :: Literal -> ProofBlock -> [(String, String)]
blockRenaming lit block = zip (nub (litVars lit ++ blockVars block)) prettyVarNames

-- A lemma that rests on assumptions of the goal states them, as the goal
-- does, and discharges them.
lemmaLines :: [Axiom] -> Map.Map String [String] -> (String, Literal, ProofBlock) -> [String]
lemmaLines hyps deps (name, lit, block) =
  (cap name ++ ": " ++ stated) :
  "Proof:" :
  blockLines hyps (renameBlock renaming block) ++
  [ l | not (null used), l <- ["  hence " ++ stated, "    by discharge"] ] ++
  [""]
  where
    used     = [ ax | ax <- hyps, axiomName ax `elem` Map.findWithDefault [] name deps ]
    renaming = zip (nub (litVars lit ++ concatMap axiomVars used ++ blockVars block)) prettyVarNames
    stated   = (if null used then "" else intercalate " /\\ " (map ppHyp used) ++ " => ")
               ++ ppLiteral (renameLit renaming lit)
    ppHyp (AUnit _ l)    = ppLiteral (renameLit renaming l)
    ppHyp (ANucleus _ c) = "(" ++ ppClauseWith renaming c ++ ")"

-- A goal under hypotheses is stated as the conjecture was, H1 /\ H2 => G, and
-- its proof ends by discharging them.  When the conclusion is a negation the
-- hypotheses it supplied are the negated conjuncts and the block derives
-- $false.
goalLines :: [Axiom] -> [String] -> Int -> (Literal, ProofBlock) -> [String]
goalLines hyps negated n (lit, block) =
  ("Goal " ++ show n ++ ": " ++ stated) :
  "Proof:" :
  blockLines hyps (renameBlock renaming block) ++
  [ l | not (null hyps), l <- ["  hence " ++ stated, "    by discharge"] ]
  where
    (negHyps, anteHyps) = partition ((`elem` negated) . axiomName) hyps
    stated | null negHyps = ppHyps anteHyps ++ ppLiteral (renameLit renaming lit)
           | otherwise    = ppHyps anteHyps ++ "~(" ++ intercalate " /\\ " (map ppHyp negHyps) ++ ")"
    renaming = zip (nub (litVars lit ++ concatMap axiomVars hyps ++ blockVars block)) prettyVarNames
    ppHyps hs | null hs   = ""
              | otherwise = intercalate " /\\ " (map ppHyp hs) ++ " => "
    ppHyp (AUnit _ l)    = ppLiteral (renameLit renaming l)
    ppHyp (ANucleus _ c) = "(" ++ ppClauseWith renaming c ++ ")"

blockLines :: [Axiom] -> ProofBlock -> [String]
blockLines hyps (HaveHence ls) = concatMap (renderLine hyps) ls
blockLines _ (EqChain s steps) = renderEqChain s steps

-- A hypothesis is assumed where the proof states it as it was assumed, and
-- an instance of it is a step citing the assumption like an axiom.
renderLine :: [Axiom] -> ProofLine -> [String]
renderLine hyps (Have lit nm)
  | "assumption " `isPrefixOf` nm
  , or [ clauseKey (Clause [] (Just l)) == clauseKey (Clause [] (Just lit)) | AUnit n l <- hyps, n == nm ]
  = ["  assume " ++ ppLiteral lit]
renderLine _ (Have  lit nm) = ["  have "  ++ ppLiteral lit, "    by " ++ nm]
renderLine _ (And   lit nm) = ["   and "  ++ ppLiteral lit, "    by " ++ nm]
renderLine _ (Hence lit j)  = ["  hence " ++ ppLiteral lit, "    " ++ ppJust j]

ppJust :: Justification -> String
ppJust (ByAxiom nm)        = "by " ++ nm
ppJust (ByRw nm Nothing)   = "by rw " ++ nm
ppJust (ByRw nm (Just RL)) = "by rw " ++ nm ++ " R->L"
ppJust (ByRw nm (Just LR)) = "by rw " ++ nm
ppJust ByContradiction     = "by contradiction"

renderEqChain :: Term -> [(RwStep, Term)] -> [String]
renderEqChain s steps =
  ("  " ++ ppTerm s) : concatMap renderStep steps
  where
    renderStep (RwStep nm _ dir, cur) =
      [ "= { by " ++ nm ++ dirStr dir ++ " }"
      , "  " ++ ppTerm cur
      ]
    dirStr LR = ""
    dirStr RL = " R->L"

ppLiteral :: Literal -> String
ppLiteral (Eq l r)    = ppTerm l ++ " = " ++ ppTerm r
ppLiteral (NEq l r)   = ppTerm l ++ " != " ++ ppTerm r
ppLiteral (Rel n [])  = n
ppLiteral (Rel n ts)  = n ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"
ppLiteral (NRel n []) = "~" ++ n
ppLiteral (NRel n ts) = "~" ++ n ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

-- Apply a name→name mapping throughout lemma and goal proof blocks.
applyRenaming :: Map.Map String String -> StructuredProof -> StructuredProof
applyRenaming mapping sp0 = sp0
  { lemmas = [(ren n, lit, renBlock b) | (n, lit, b) <- lemmas sp0]
  , goals  = [(lit, renBlock b)        | (lit, b)    <- goals sp0]
  }
  where
    ren nm   = Map.findWithDefault nm nm mapping
    renBlock = renameRefsBlock ren

pruneUnusedLemmas :: StructuredProof -> StructuredProof
pruneUnusedLemmas sp = renumber (fixpoint prune sp)
  where
    prune sp0 =
      let refs            = allRefs sp0
          (kept, dropped) = partition (\(nm, _, _) -> Set.member nm refs) (lemmas sp0)
      in (sp0 { lemmas = kept }, not (null dropped))

    allRefs sp0 = Set.fromList $
      concatMap (blockRefNames . snd) (goals sp0) ++
      concatMap (\(_, _, b) -> blockRefNames b) (lemmas sp0)

    fixpoint f x =
      let (x', changed) = f x
      in if changed then fixpoint f x' else x'

    renumber sp0 =
      let lemmaNames = map (\(n, _, _) -> n) (lemmas sp0)
          axCount    = length (axioms sp0)
          mapping    = Map.fromList (zip lemmaNames ["lemma " ++ show k | k <- [axCount+1..]])
      in applyRenaming mapping sp0
