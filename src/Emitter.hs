module Emitter where

import Data.Char (toUpper)
import Data.List (intercalate, nub)
import Data.Maybe (maybeToList)
import Types

emit :: StructuredProof -> String
emit sp = unlines $ concat
  [ axiomLines (axioms sp)
  , [ "" | not (null (axioms sp)) ]
  , concatMap lemmaLines (lemmas sp)
  , intercalate [""] (zipWith goalLines [1..] (goals sp))
  ]

axiomLines :: [AxiomEntry] -> [String]
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
prettyVarNames = ["X", "Y", "Z", "A", "B", "C", "U", "V", "W"] ++ ["X" ++ show n | n <- [(1 :: Int)..]]

blockRenaming :: Literal -> ProofBlock -> [(String, String)]
blockRenaming lit block = zip (nub (litVars lit ++ blockVars block)) prettyVarNames

lemmaLines :: (String, Literal, ProofBlock) -> [String]
lemmaLines (name, lit, block) =
  (toUpper (head name) : tail name ++ ": " ++ ppLiteral (renameLit renaming lit)) :
  "Proof:" :
  blockLines (renameBlock renaming block) ++
  [""]
  where renaming = blockRenaming lit block

blockVars :: ProofBlock -> [String]
blockVars (HaveHence ls)    = nub (concatMap lineVars ls)
blockVars (EqChain s steps) = nub (termVars s ++ concatMap stepVars steps)
  where stepVars (RwStep _ (l, r) _, cur) = termVars l ++ termVars r ++ termVars cur

lineVars :: ProofLine -> [String]
lineVars (Have  lit _) = litVars lit
lineVars (And   lit _) = litVars lit
lineVars (Hence lit _) = litVars lit

renameBlock :: [(String, String)] -> ProofBlock -> ProofBlock
renameBlock r (HaveHence ls)    = HaveHence (map (renameProofLine r) ls)
renameBlock r (EqChain s steps) = EqChain (renameTerm r s) (map renameStep steps)
  where renameStep (RwStep nm (l, ri) d, cur) =
          (RwStep nm (renameTerm r l, renameTerm r ri) d, renameTerm r cur)

renameProofLine :: [(String, String)] -> ProofLine -> ProofLine
renameProofLine r (Have  lit nm) = Have  (renameLit r lit) nm
renameProofLine r (And   lit nm) = And   (renameLit r lit) nm
renameProofLine r (Hence lit j)  = Hence (renameLit r lit) j

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
