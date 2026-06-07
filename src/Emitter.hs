module Emitter where

import Data.Char (toUpper)
import Data.List (intercalate)
import Types

emit :: StructuredProof -> String
emit sp = unlines $ concat
  [ axiomLines (axioms sp)
  , [ "" | not (null (axioms sp)) ]
  , concatMap lemmaLines (lemmas sp)
  , goalLines (goal sp)
  ]

axiomLines :: [(String, Literal)] -> [String]
axiomLines = map (\(n, l) -> toUpper (head n) : tail n ++ ": " ++ ppLiteral l)

lemmaLines :: (String, Literal, ProofBlock) -> [String]
lemmaLines (name, lit, block) =
  (toUpper (head name) : tail name ++ ": " ++ ppLiteral lit) :
  "Proof:" :
  blockLines block ++
  [""]

goalLines :: (Literal, ProofBlock) -> [String]
goalLines (lit, block) =
  ("Goal 1: " ++ ppLiteral lit) :
  "Proof:" :
  blockLines block

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
ppLiteral (Rel n ts)  = n ++ "(" ++ intercalate ", " (map ppTerm ts) ++ ")"
ppLiteral (NRel n []) = "~" ++ n
ppLiteral (NRel n ts) = "~" ++ n ++ "(" ++ intercalate ", " (map ppTerm ts) ++ ")"

ppTerm :: Term -> String
ppTerm (Var x)    = x
ppTerm (Const c)  = c
ppTerm (App f ts) = f ++ "(" ++ intercalate ", " (map ppTerm ts) ++ ")"
