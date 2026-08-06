module Debug
  ( dumpTSTP
  , dumpProofInfo
  , dumpProofTree
  , dumpInferenceRules
  ) where

import Data.List (intercalate, nub, sort, sortBy)
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Ord (comparing)
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.TPTP as T

import ProofTree (ProofInfo(..), LeafEntry(..), LeafRole(..), unitNameStr, demodRuleNames)
import Types (Dir(..))

ppTerm :: T.Term -> String
ppTerm (T.Variable (T.Var v))                   = Text.unpack v
ppTerm (T.Function (T.Defined (T.Atom f)) [])   = Text.unpack f
ppTerm (T.Function (T.Defined (T.Atom f)) args) =
  Text.unpack f ++ "(" ++ intercalate ", " (map ppTerm args) ++ ")"
ppTerm (T.Function (T.Reserved (T.Standard f)) args) =
  "$" ++ Text.unpack (T.name f)
  ++ (if null args then "" else "(" ++ intercalate ", " (map ppTerm args) ++ ")")
ppTerm (T.Function (T.Reserved (T.Extended t)) args) =
  "$" ++ Text.unpack t
  ++ (if null args then "" else "(" ++ intercalate ", " (map ppTerm args) ++ ")")
ppTerm (T.Number (T.IntegerConstant n))      = show n
ppTerm (T.Number (T.RationalConstant n d))   = show n ++ "/" ++ show d
ppTerm (T.Number (T.RealConstant r))         = show r
ppTerm (T.DistinctTerm (T.DistinctObject t)) = "\"" ++ Text.unpack t ++ "\""

ppLit :: T.Literal -> String
ppLit (T.Predicate (T.Defined (T.Atom n)) [])   = Text.unpack n
ppLit (T.Predicate (T.Defined (T.Atom n)) args) =
  Text.unpack n ++ "(" ++ intercalate ", " (map ppTerm args) ++ ")"
ppLit (T.Predicate (T.Reserved (T.Standard p)) args) =
  "$" ++ Text.unpack (T.name p)
  ++ (if null args then "" else "(" ++ intercalate ", " (map ppTerm args) ++ ")")
ppLit (T.Predicate (T.Reserved (T.Extended t)) args) =
  "$" ++ Text.unpack t
  ++ (if null args then "" else "(" ++ intercalate ", " (map ppTerm args) ++ ")")
ppLit (T.Equality l T.Positive r) = ppTerm l ++ " = " ++ ppTerm r
ppLit (T.Equality l T.Negative r) = ppTerm l ++ " != " ++ ppTerm r

ppClause :: T.Clause -> String
ppClause (T.Clause lits) =
  let ls  = toList lits
      pos = [ppLit l | (T.Positive, l) <- ls, not (isReserved l)]
      neg = [ppLit l | (T.Negative, l) <- ls]
  in case (neg, pos) of
    ([], []) -> "bot"
    ([], _)  -> intercalate " | " pos
    (_, [])  -> intercalate ", " neg ++ " -> bot"
    (_, _)   -> intercalate ", " neg ++ " -> " ++ intercalate " | " pos

isReserved :: T.Literal -> Bool
isReserved (T.Predicate (T.Reserved _) _) = True
isReserved _                              = False

ppFOF :: T.UnsortedFirstOrder -> String
ppFOF (T.Atomic lit)                          = ppLit lit
ppFOF (T.Negated f)                           = "~" ++ ppFOF f
ppFOF (T.Quantified T.Forall vs body)         = "![" ++ ppVars vs ++ "]: " ++ ppFOF body
ppFOF (T.Quantified T.Exists vs body)         = "?[" ++ ppVars vs ++ "]: " ++ ppFOF body
ppFOF (T.Connected l T.Conjunction r)         = ppFOF l ++ " & " ++ ppFOF r
ppFOF (T.Connected l T.Disjunction r)         = ppFOF l ++ " | " ++ ppFOF r
ppFOF (T.Connected l T.Implication r)         = ppFOF l ++ " => " ++ ppFOF r
ppFOF (T.Connected l T.Equivalence r)         = ppFOF l ++ " <=> " ++ ppFOF r
ppFOF (T.Connected l _ r)                     = ppFOF l ++ " ? " ++ ppFOF r

ppVars :: NonEmpty (T.Var, b) -> String
ppVars vs = intercalate ", " [Text.unpack v | (T.Var v, _) <- toList vs]

ppDecl :: T.Declaration -> String
ppDecl (T.Formula _ (T.CNF cl)) = ppClause cl
ppDecl (T.Formula _ (T.FOF f))  = ppFOF f
ppDecl d                        = show d

roleStr :: T.Declaration -> String
roleStr (T.Formula (T.Standard r) _) = show r
roleStr _                            = "?"

annStr :: Maybe T.Annotation -> String
annStr Nothing          = "input"
annStr (Just (src, _)) = show src

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

-- Raw TPTP view (goal literals, all nodes by position, simpl chains).
-- Algorithm-level trace goes to stderr from translate when debug=True.
dumpProofInfo :: ProofInfo -> IO ()
dumpProofInfo info = do
  putStrLn ("Goal literals [" ++ show (length (piGoalLits info)) ++ "]:")
  mapM_ (\l -> putStrLn ("  " ++ ppLit l)) (piGoalLits info)
  putStrLn ""
  let allEntries = piElectrons info ++ piNonUnits info
  putStrLn ("Nodes by position [" ++ show (length allEntries) ++ "]:")
  mapM_ ppEntry (sortBy (comparing lePos) allEntries)
  putStrLn ""
  let withSimpl = filter (not . null . leSimpl) allEntries
  putStrLn ("Simpl[pos] chains [" ++ show (length withSimpl) ++ "]:")
  if null withSimpl
    then putStrLn "  (none)"
    else mapM_ ppSimpl withSimpl
  where
    ppEntry e = putStrLn $
      "  pos=" ++ (if null (lePos e) then "ε" else lePos e)
      ++ "  [" ++ ppRole (leRole e) ++ "]"
      ++ "  " ++ leName e
      ++ ": " ++ ppDecl (leDecl e)
    ppSimpl e = putStrLn $
      "  pos=" ++ (if null (lePos e) then "ε" else lePos e)
      ++ " (" ++ leName e ++ "): "
      ++ intercalate ", " [nm ++ "(" ++ ppDirS d ++ ")" | (nm, d) <- leSimpl e]
    ppRole OrigAxiom     = "axiom"
    ppRole NegConjecture = "goal"
    ppRole Derived       = "derived"
    ppDirS LR = "L→R"
    ppDirS RL = "R→L"

-- Proof tree reconstructed from bit-string positions (left=provider, right=consumer).
dumpProofTree :: ProofInfo -> IO ()
dumpProofTree info = do
  putStrLn "Proof tree (left=provider, right=consumer):"
  let allEntries = piElectrons info ++ piNonUnits info
      byPos = Map.fromListWith (++) [(lePos e, [e]) | e <- allEntries]
  go byPos "" "" ""
  where
    -- go nodeMap currentPos linePrefix lastChildPrefix
    go :: Map String [LeafEntry] -> String -> String -> String -> IO ()
    go byPos pos linePrefix contPrefix = do
      let entries  = Map.findWithDefault [] pos byPos
          children = childPositions byPos pos
          label    = case entries of
            []  -> "(internal)"
            [e] -> nodeLabel e
            es  -> intercalate " | " (map nodeLabel es)
      putStrLn (linePrefix ++ label)
      let n = length children
      mapM_ (\(i, child) ->
        let isLast     = i == n - 1
            branch     = if isLast then "└── " else "├── "
            cont       = if isLast then "    " else "│   "
        in go byPos child (contPrefix ++ branch) (contPrefix ++ cont)
        ) (zip [0..] children)

    childPositions :: Map String [LeafEntry] -> String -> [String]
    childPositions byPos pos =
      sortBy (comparing id)
        [ c | c0 <- ['0'..'9']
            , let c = pos ++ [c0]
            , Map.member c byPos ]

    nodeLabel :: LeafEntry -> String
    nodeLabel e =
      "[" ++ role ++ "] "
      ++ ppDecl (leDecl e)
      ++ simplSuffix
      where
        role = case leRole e of
                 OrigAxiom     -> "axiom"
                 NegConjecture -> "goal"
                 Derived       -> "derived"
        simplSuffix
          | null (leSimpl e) = ""
          | otherwise = "  {simpl: "
              ++ intercalate ", " [nm ++ "(" ++ d ++ ")" | (nm, dir) <- leSimpl e
                                  , let d = case dir of LR -> "L→R"; RL -> "R→L"]
              ++ "}"

-- Inference rules classified by Waldmann's proof categories.
-- "unclassified" must be empty for his conversion proof to hold.
dumpInferenceRules :: [T.Unit] -> IO ()
dumpInferenceRules units = do
  let ruleNames = sort $ nub
        [ Text.unpack rule
        | T.Unit _ _ (Just (T.Inference (T.Atom rule) _ _, _)) <- units ]
      bucket nm
        | Set.member (Text.pack nm) demodRuleNames     = "demodulation"
        | Set.member (Text.pack nm) resolutionRules    = "resolution"
        | Set.member (Text.pack nm) eqResolutionRules  = "eq-resolution"
        | Set.member (Text.pack nm) condensationRules  = "condensation"
        | Set.member (Text.pack nm) preprocessingRules = "preprocessing"
        | otherwise                                    = "unclassified"
      grouped = foldr (\nm m -> Map.insertWith (++) (bucket nm) [nm] m)
                      Map.empty ruleNames
      showBucket k = putStrLn $ "  " ++ pad k ++ "  " ++
        maybe "(none)" (intercalate ", " . sort) (Map.lookup k grouped)
      pad s = s ++ replicate (14 - length s) ' '
  putStrLn ("Inference rules [" ++ show (length ruleNames) ++ "]:")
  mapM_ showBucket ["demodulation", "resolution", "eq-resolution",
                    "condensation", "preprocessing", "unclassified"]
  where
    resolutionRules = Set.fromList $ map Text.pack
      [ "resolution", "binary_resolution", "hyper_resolution"
      , "hyperresolution", "ur_resolution", "superposition"
      , "subsumption_resolution" ]
    eqResolutionRules = Set.fromList $ map Text.pack
      [ "trivial_inequality_removal", "equality_resolution" ]
    condensationRules = Set.fromList $ map Text.pack
      [ "cn", "condensation", "duplicate_literal_removal" ]
    preprocessingRules = Set.fromList $ map Text.pack
      [ "cnf_transformation", "ennf_transformation", "ennf_negation_normalization"
      , "flattening", "negated_conjecture", "rectify", "skolemize"
      , "variable_rename", "definition_folding"
      , "pure_predicate_removal", "predicate_definition_introduction"
      , "unused_predicate_definition_removal" ]
