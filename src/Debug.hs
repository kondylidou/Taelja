module Debug
  ( dumpTSTP
  , dumpProofTree
  , dumpPhaseOne
  ) where

import Data.List (intercalate)
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Maybe (fromMaybe)
import qualified Data.Text as Text
import qualified Data.TPTP as T

import ProofTree (ProofTree(..), unitNameStr)
import Translate (UnitEntry(..))

-- Terms

ppTerm :: T.Term -> String
ppTerm (T.Variable (T.Var v))                   = Text.unpack v
ppTerm (T.Function (T.Defined (T.Atom f)) [])   = Text.unpack f
ppTerm (T.Function (T.Defined (T.Atom f)) args) =
  Text.unpack f ++ "(" ++ intercalate ", " (map ppTerm args) ++ ")"
ppTerm _ = "_"

-- Literals

ppLit :: T.Literal -> String
ppLit (T.Predicate (T.Defined (T.Atom n)) [])   = Text.unpack n
ppLit (T.Predicate (T.Defined (T.Atom n)) args) =
  Text.unpack n ++ "(" ++ intercalate ", " (map ppTerm args) ++ ")"
ppLit (T.Equality l T.Positive r) = ppTerm l ++ " = " ++ ppTerm r
ppLit (T.Equality l T.Negative r) = ppTerm l ++ " ≠ " ++ ppTerm r
ppLit _ = "_"

-- CNF clauses: body → head notation (Horn convention)

ppClause :: T.Clause -> String
ppClause (T.Clause lits) =
  let ls  = toList lits
      pos = [ppLit l | (T.Positive, l) <- ls, not (isReserved l)]
      neg = [ppLit l | (T.Negative, l) <- ls]
  in case (neg, pos) of
    ([], []) -> "⊥"
    ([], _)  -> intercalate " ∨ " pos
    (_, [])  -> intercalate ", " neg ++ " → ⊥"
    (_, _)   -> intercalate ", " neg ++ " → " ++ intercalate " ∨ " pos

isReserved :: T.Literal -> Bool
isReserved (T.Predicate (T.Reserved _) _) = True
isReserved _                              = False

-- FOF formulas

ppFOF :: T.UnsortedFirstOrder -> String
ppFOF (T.Atomic lit)                  = ppLit lit
ppFOF (T.Negated f)                   = "¬" ++ ppFOF f
ppFOF (T.Quantified T.Forall vs body) = "∀" ++ ppVars vs ++ ". " ++ ppFOF body
ppFOF (T.Quantified T.Exists vs body) = "∃" ++ ppVars vs ++ ". " ++ ppFOF body
ppFOF (T.Connected l T.Conjunction r) = ppFOF l ++ " ∧ " ++ ppFOF r
ppFOF (T.Connected l T.Disjunction r) = ppFOF l ++ " ∨ " ++ ppFOF r
ppFOF (T.Connected l T.Implication r) = ppFOF l ++ " → " ++ ppFOF r
ppFOF (T.Connected l T.Equivalence r) = ppFOF l ++ " ↔ " ++ ppFOF r
ppFOF _                               = "?"

ppVars :: NonEmpty (T.Var, b) -> String
ppVars vs = intercalate ", " [Text.unpack v | (T.Var v, _) <- toList vs]

-- Declarations

ppDecl :: T.Declaration -> String
ppDecl (T.Formula _ (T.CNF cl)) = ppClause cl
ppDecl (T.Formula _ (T.FOF f))  = ppFOF f
ppDecl d                        = show d

-- Dump helpers

roleStr :: T.Declaration -> String
roleStr (T.Formula (T.Standard r) _) = show r
roleStr _                            = "?"

annStr :: Maybe T.Annotation -> String
annStr Nothing          = "input"
annStr (Just (src, _)) = show src

-- TSTP parser output

dumpTSTP :: [T.Unit] -> IO ()
dumpTSTP units = do
  putStrLn ("Parsed " ++ show (length units) ++ " units")
  putStrLn ""
  mapM_ go units
  where
    go (T.Unit name decl source) = do
      putStr   (unitNameStr name ++ " [" ++ roleStr decl ++ "]")
      putStrLn (" <- " ++ annStr source)
      putStrLn ("  " ++ ppDecl decl)
      putStrLn ""
    go (T.Include path _) = putStrLn ("include(" ++ show path ++ ")")

-- Proof tree pretty-printer using box-drawing characters

ppProofTree :: ProofTree -> String
ppProofTree = unlines . drawPT

drawPT :: ProofTree -> [String]
drawPT (PTLeaf name decl)           = [name ++ ": " ++ ppDecl decl]
drawPT (PTNode name decl rule kids) =
  (name ++ " [" ++ Text.unpack rule ++ "]: " ++ ppDecl decl) : drawKids kids

drawKids :: [ProofTree] -> [String]
drawKids []     = []
drawKids [k]    = treeShift "└── " "    " (drawPT k)
drawKids (k:ks) = treeShift "├── " "│   " (drawPT k) ++ drawKids ks

treeShift :: String -> String -> [String] -> [String]
treeShift first rest = zipWith (++) (first : repeat rest)

dumpProofTree :: ProofTree -> IO ()
dumpProofTree = putStr . ppProofTree

-- Phase 1 result

dumpPhaseOne :: [UnitEntry] -> [(String, String, T.Declaration)] -> [T.Literal] -> IO ()
dumpPhaseOne us nus goal = do
  putStrLn ("Goal: " ++ intercalate " ∧ " (map ppLit goal))
  putStrLn ""
  putStrLn ("Units (electrons) [" ++ show (length us) ++ "]:")
  mapM_ goU us
  putStrLn ""
  putStrLn ("NonUnits (nuclei) [" ++ show (length nus) ++ "]:")
  mapM_ goN nus
  where
    goU (UnitEntry name lit _ pos) =
      putStrLn ("  pos=" ++ fromMaybe "nil" pos
             ++ "  " ++ fromMaybe "?" name
             ++ ": " ++ ppLit lit)
    goN (pos, name, decl) =
      putStrLn ("  pos=" ++ pos ++ "  " ++ name ++ ": " ++ ppDecl decl)
