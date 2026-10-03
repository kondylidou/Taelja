-- The structured proof as plain text, with the axioms, the lemmas and one
-- proof per goal. Unused lemmas are dropped, axioms and lemmas are numbered
-- and variables get readable names. The Lean and TPTP outputs reuse some of
-- these steps.
module Emitter
  ( emitText
  , finalProof
  , dropAndNumberLemmas
  , axiomRenaming
  , blockRenaming
  ) where

import Data.List (intercalate, nub)
import qualified Data.Map.Strict as Map
import Types
import Helpers

-- The plain-text proof, with axioms, lemmas and one proof per goal. Hypotheses
-- of the conjecture are listed and cited as axioms here, while the TPTP
-- output keeps them apart as assumptions.
emitText :: StructuredProof -> String
emitText sp0 = unlines $ concat
  [ axiomLines (axioms sp)
  , [ "" | not (null (axioms sp)) ]
  , concatMap lemmaLines (lemmas sp)
  , intercalate [""] (zipWith goalLines [1..] (goals sp))
  ]
  where
    sp = finalProof sp0

-- The proof the text and Lean outputs print, with unused lemmas dropped and
-- axioms and lemmas numbered in order.
finalProof :: StructuredProof -> StructuredProof
finalProof = renumberAxioms . dropAndNumberLemmas

-- Numbers the axioms 1, 2, ... and updates every citation of them.
renumberAxioms :: StructuredProof -> StructuredProof
renumberAxioms sp =
  let oldNames = [ axiomName ax
                 | ax <- axioms sp ]
      renaming  = Map.fromList (zip oldNames
                    ["axiom " ++ show i | i <- [(1 :: Int) ..]])
      newAxioms = zipWith (\i -> renameAxiom ("axiom " ++ show i)) [(1 :: Int) ..] (axioms sp)
  in (renameCitations renaming sp) { axioms = newAxioms }

-- One line per axiom. All axioms share one variable renaming, so a variable
-- prints the same in each.
axiomLines :: [Axiom] -> [String]
axiomLines entries = map ppEntry entries
  where
    globalRenaming = axiomRenaming entries
    ppEntry (AUnit n l)    = capitalize n ++ ": " ++ ppLiteral (renameLit globalRenaming l)
    ppEntry (ANucleus n (Clause bs mh)) = capitalize n ++ ": " ++ ppClause (Clause (map (renameLit globalRenaming) bs) (fmap (renameLit globalRenaming) mh))

-- The readable name of each axiom variable, in order of first occurrence.
axiomRenaming :: [Axiom] -> [(String, String)]
axiomRenaming entries = zip (nub (concatMap litVars (concatMap axiomLits entries))) prettyVarNames

-- Readable variable names, handed out in this order.
prettyVarNames :: [String]
prettyVarNames = ["X", "Y", "Z", "A", "B", "C", "U", "V", "W"]
              ++ ["X" ++ show n | n <- [(1 :: Int)..]]

-- The readable name of each variable of a statement and its proof block, in
-- order of first occurrence. Names are local to a block, so one name may mean
-- different things in different lemmas.
blockRenaming :: Literal -> ProofBlock -> [(String, String)]
blockRenaming lit block = zip (nub (litVars lit ++ blockShownVars block ++ blockVars block)) prettyVarNames

-- A lemma with its proof, in variable names of its own.
lemmaLines :: (String, Literal, ProofBlock) -> [String]
lemmaLines (name, lit, block) =
  (capitalize name ++ ": " ++ ppLiteral (renameLit renaming lit)) :
  "Proof:" :
  blockLines (renameBlock renaming block) ++
  [""]
  where
    renaming = blockRenaming lit block

-- The nth goal with its proof, in variable names of its own.
goalLines :: Int -> (Literal, ProofBlock) -> [String]
goalLines n (lit, block) =
  ("Goal " ++ show n ++ ": " ++ ppLiteral (renameLit renaming lit)) :
  "Proof:" :
  blockLines (renameBlock renaming block)
  where
    renaming = blockRenaming lit block

-- The printed lines of a proof block.
blockLines :: ProofBlock -> [String]
blockLines (HaveHence ls)    = concatMap renderLine ls
blockLines (EqChain s steps) = renderEqChain s steps

-- A have, and or hence line, with its justification on the line below.
renderLine :: ProofLine -> [String]
renderLine (Have  lit nm) = ["  have "  ++ ppLiteral lit, "    by " ++ nm]
renderLine (And   lit nm) = ["   and "  ++ ppLiteral lit, "    by " ++ nm]
renderLine (Hence lit j)  = ["  hence " ++ ppLiteral lit, "    " ++ ppJust j]

-- The justification of a hence line. A rewrite right to left is marked R->L.
ppJust :: Justification -> String
ppJust (ByAxiom nm)        = "by " ++ nm
ppJust (ByRw nm RL) = "by rw " ++ nm ++ " R->L"
ppJust (ByRw nm LR) = "by rw " ++ nm
ppJust ByContradiction     = "by contradiction"

-- An equational chain, one term per line with the cited equation in between.
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

-- Drops unused lemmas and numbers the rest after the axioms.
dropAndNumberLemmas :: StructuredProof -> StructuredProof
dropAndNumberLemmas sp = renumber (dropUnusedLemmas sp)
  where
    renumber sp0 =
      let lemmaNames = map (\(n, _, _) -> n) (lemmas sp0)
          axCount    = length (axioms sp0)
          mapping    = Map.fromList (zip lemmaNames ["lemma " ++ show k | k <- [axCount+1..]])
      in renameCitations mapping sp0
