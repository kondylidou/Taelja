-- The structured proof as plain text, with the axioms, the lemmas and one
-- proof per goal. Unused lemmas are dropped, axioms and lemmas are numbered
-- and variables get readable names. The Lean and TPTP outputs reuse some of
-- these steps.
module Emitter
  ( emitText
  , finalProof
  , dropUnusedAndNumber
  , axiomRenaming
  , blockRenaming
  ) where

import Data.List (intercalate, nub)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Types
import Helpers

-- The plain-text proof, with axioms, lemmas and one proof per goal. Hypotheses
-- of the conjecture are listed and cited as axioms here, while the TPTP
-- output keeps them apart as assumptions.
emitText :: StructuredProof -> String
emitText sp0 = unlines $ concat
  [ axiomLines (axioms sp)
  , [ "" | not (null (axioms sp)) ]
  , concat [ provedLines (capitalize n) lit blk ++ [""] | (n, lit, blk) <- lemmas sp ]
  , intercalate [""] [ provedLines ("Goal " ++ show i) lit blk | (i, (lit, blk)) <- zip [1 :: Int ..] (goals sp) ]
  ]
  where
    sp = finalProof sp0

-- The proof the text and Lean outputs print, with unused lemmas dropped and
-- axioms and lemmas numbered in order.
finalProof :: StructuredProof -> StructuredProof
finalProof = renumberAxioms . dropUnusedAndNumber

-- Numbers the axioms 1, 2, ... and updates every citation of them.
renumberAxioms :: StructuredProof -> StructuredProof
renumberAxioms sp = (renameCitations renaming sp) { axioms = zipWith renameAxiom newNames (axioms sp) }
  where
    newNames = [ "axiom " ++ show i | i <- [1 :: Int ..] ]
    renaming = Map.fromList (zip (map axiomName (axioms sp)) newNames)

-- One line per axiom. All axioms share one variable renaming, so a variable
-- prints the same in each.
axiomLines :: [Axiom] -> [String]
axiomLines axs = map line axs
  where
    ren = renameLit (axiomRenaming axs)
    line (AUnit n l)                 = capitalize n ++ ": " ++ ppLiteral (ren l)
    line (ANucleus n (Clause bs mh)) = capitalize n ++ ": " ++ ppClause (Clause (map ren bs) (fmap ren mh))

-- The readable name of each axiom variable, in order of first occurrence.
axiomRenaming :: [Axiom] -> [(String, String)]
axiomRenaming axs = zip (nub (concatMap litVars (concatMap axiomLits axs))) prettyVarNames

-- Readable variable names, handed out in this order.
prettyVarNames :: [String]
prettyVarNames = ["X", "Y", "Z", "A", "B", "C", "U", "V", "W"] ++ [ "X" ++ show n | n <- [1 :: Int ..] ]

-- The readable name of each variable of a statement and its proof block, in
-- order of first occurrence. Names are local to a block, so one name may mean
-- different things in different lemmas.
blockRenaming :: Literal -> ProofBlock -> [(String, String)]
blockRenaming lit block = zip (nub (litVars lit ++ blockShownVars block ++ blockVars block)) prettyVarNames

-- A lemma or goal under its title with its proof, in variable names of its own.
provedLines :: String -> Literal -> ProofBlock -> [String]
provedLines title lit block =
  (title ++ ": " ++ ppLiteral (renameLit ren lit)) : "Proof:" : blockLines (renameBlock ren block)
  where
    ren = blockRenaming lit block

-- The printed lines of a proof block. A chain prints one term per line with
-- the cited equation in between.
blockLines :: ProofBlock -> [String]
blockLines (HaveHence ls)    = concatMap renderLine ls
blockLines (EqChain s steps) =
  ("  " ++ ppTerm s) : concat [ ["= { by " ++ nm ++ rlMark d ++ " }", "  " ++ ppTerm t] | (RwStep nm _ d, t) <- steps ]

-- A have, and or hence line, with its justification on the line below.
renderLine :: ProofLine -> [String]
renderLine (Have  lit nm) = ["  have "  ++ ppLiteral lit, "    by " ++ nm]
renderLine (And   lit nm) = ["   and "  ++ ppLiteral lit, "    by " ++ nm]
renderLine (Hence lit j)  = ["  hence " ++ ppLiteral lit, "    " ++ ppJust j]

-- The justification of a hence line.
ppJust :: Justification -> String
ppJust (ByAxiom nm)    = "by " ++ nm
ppJust (ByRw nm d)     = "by rw " ++ nm ++ rlMark d
ppJust ByContradiction = "by contradiction"

-- The mark of a rewrite used right to left.
rlMark :: Dir -> String
rlMark LR = ""
rlMark RL = " R->L"

-- Drops the lemmas and axioms the proof does not use and numbers the lemmas
-- after the axioms.
dropUnusedAndNumber :: StructuredProof -> StructuredProof
dropUnusedAndNumber sp = renameCitations numbering kept
  where
    pruned    = dropUnusedLemmas sp
    cited     = citedNames pruned
    kept      = pruned { axioms = filter ((`Set.member` cited) . axiomName) (axioms pruned) }
    numbering = Map.fromList (zip [ n | (n, _, _) <- lemmas kept ]
                                  [ "lemma " ++ show k | k <- [length (axioms kept) + 1 ..] ])
