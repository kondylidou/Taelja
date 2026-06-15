module Emitter where

import Data.Char (toUpper)
import Data.List (intercalate, nub)
import Data.Maybe (maybeToList)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Types
import Helpers

emit :: StructuredProof -> String
emit sp0 = unlines $ concat
  [ axiomLines (axioms sp)
  , [ "" | not (null (axioms sp)) ]
  , concatMap lemmaLines (lemmas sp)
  , intercalate [""] (zipWith goalLines [1..] (goals sp))
  ]
  where sp = pruneUnusedLemmas sp0

-- A single global renaming covers all axiom entries so that a variable shared
-- across multiple axioms (including non-unit clauses) gets the same display name.
axiomLines :: [Axiom] -> [String]
axiomLines entries = map ppEntry entries
  where
    globalRenaming = zip (nub (concatMap entryVars entries)) prettyVarNames
    entryVars (AUnit _ l)                  = litVars l
    entryVars (ANonUnit _ (Clause bs mh))  = concatMap litVars bs ++ maybe [] litVars mh
    ppEntry (AUnit n l)    = cap n ++ ": " ++ ppLiteral (renameLit globalRenaming l)
    ppEntry (ANonUnit n c) = cap n ++ ": " ++ ppClauseWith globalRenaming c
    cap s = toUpper (head s) : tail s

ppClauseWith :: [(String, String)] -> Clause -> String
ppClauseWith renaming (Clause bodyLits mHead) =
  ppBodies renamedBody ++ " => " ++ maybe "⊥" ppLiteral renamedHead
  where
    renamedBody  = map (renameLit renaming) bodyLits
    renamedHead  = fmap (renameLit renaming) mHead
    ppBodies []  = "(empty)"
    ppBodies [l] = ppLiteral l
    ppBodies ls  = intercalate " /\\ " (map ppLiteral ls)

ppClause :: Clause -> String
ppClause c@(Clause bodyLits mHead) =
  ppClauseWith localRenaming c
  where
    allLits       = bodyLits ++ maybeToList mHead
    localRenaming = zip (nub (concatMap litVars allLits)) prettyVarNames

prettyVarNames :: [String]
prettyVarNames = ["X", "Y", "Z", "A", "B", "C", "U", "V", "W"]
              ++ ["X" ++ show n | n <- [(1 :: Int)..]]

-- Variable names are local to each block — the same display name can mean
-- different things in different lemmas, which is standard mathematical style.
blockRenaming :: Literal -> ProofBlock -> [(String, String)]
blockRenaming lit block = zip (nub (litVars lit ++ blockVars block)) prettyVarNames

lemmaLines :: (String, Literal, ProofBlock) -> [String]
lemmaLines (name, lit, block) =
  (toUpper (head name) : tail name ++ ": " ++ ppLiteral (renameLit renaming lit)) :
  "Proof:" :
  blockLines (renameBlock renaming block) ++
  [""]
  where renaming = blockRenaming lit block

goalLines :: Int -> (Literal, ProofBlock) -> [String]
goalLines n (lit, block) =
  ("Goal " ++ show n ++ ": " ++ ppLiteral (renameLit renaming lit)) :
  "Proof:" :
  blockLines (renameBlock renaming block)
  where renaming = blockRenaming lit block

blockLines :: ProofBlock -> [String]
blockLines (HaveHence ls)    = concatMap renderLine ls
blockLines (EqChain s steps) = renderEqChain s steps

renderLine :: ProofLine -> [String]
renderLine (Have  lit nm) = ["  have "  ++ ppLiteral lit, "    by " ++ nm]
renderLine (And   lit nm) = ["   and "  ++ ppLiteral lit, "    by " ++ nm]
renderLine (Hence lit j)  = ["  hence " ++ ppLiteral lit, "    " ++ ppJust j]

ppJust :: Justification -> String
ppJust (ByAxiom nm)        = "by " ++ nm
ppJust (ByRw nm Nothing)   = "by rw " ++ nm
ppJust (ByRw nm (Just RL)) = "by rw " ++ nm ++ " R->L"
ppJust (ByRw nm (Just LR)) = "by rw " ++ nm

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

ppTerm :: Term -> String
ppTerm (Var x)    = x
ppTerm (Const c)  = c
ppTerm (App f ts) = f ++ "(" ++ intercalate "," (map ppTerm ts) ++ ")"

-- Remove lemmas unreferenced by any goal or other lemma, then renumber.
pruneUnusedLemmas :: StructuredProof -> StructuredProof
pruneUnusedLemmas sp = renumber (fixpoint prune sp)
  where
    prune sp0 = sp0 { lemmas = filter (isUsed sp0) (lemmas sp0) }

    isUsed sp0 (nm, _, _) = Set.member nm (allRefs sp0)

    allRefs sp0 = Set.fromList $
      concatMap (blockRefs . snd) (goals sp0) ++
      concatMap (\(_, _, b) -> blockRefs b) (lemmas sp0)

    blockRefs (HaveHence ls)    = concatMap lineRefs ls
    blockRefs (EqChain _ steps) = map (rwName . fst) steps

    lineRefs (Have _ nm)            = [nm]
    lineRefs (And _ nm)             = [nm]
    lineRefs (Hence _ (ByAxiom nm)) = [nm]
    lineRefs (Hence _ (ByRw nm _))  = [nm]

    fixpoint f x =
      let x' = f x
      in if length (lemmas x') == length (lemmas x) then x' else fixpoint f x'

    renumber sp0 =
      let lemmaNms = map (\(n, _, _) -> n) (lemmas sp0)
          axCount  = length (axioms sp0)
          mapping  = Map.fromList (zip lemmaNms ["lemma " ++ show k | k <- [axCount+1..]])
      in applyRenaming mapping sp0

    applyRenaming mapping sp0 = sp0
      { lemmas = [(ren n, lit, renBlock b) | (n, lit, b) <- lemmas sp0]
      , goals  = [(lit, renBlock b)        | (lit, b)    <- goals sp0]
      }
      where
        ren nm = Map.findWithDefault nm nm mapping
        renBlock (HaveHence ls)    = HaveHence (map renLine ls)
        renBlock (EqChain s steps) = EqChain s
          [(rw { rwName = ren (rwName rw) }, t) | (rw, t) <- steps]
        renLine (Have lit nm)            = Have lit (ren nm)
        renLine (And lit nm)             = And lit (ren nm)
        renLine (Hence lit (ByAxiom nm)) = Hence lit (ByAxiom (ren nm))
        renLine (Hence lit (ByRw nm d))  = Hence lit (ByRw (ren nm) d)
