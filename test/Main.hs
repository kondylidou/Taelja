-- The test suite. The listed proofs in test/baseline_* are translated and
-- compared with their text, Lean and TPTP goldens, and the executable must
-- print the same text with the fallback off. Small hand-built proofs check
-- that the Lean output states a step exactly when it is right.
module Main where

import Control.DeepSeq (force)
import Control.Exception (evaluate)
import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text.IO as TIO
import System.Environment (setEnv)
import Test.Tasty
import Test.Tasty.Golden
import Test.Tasty.Golden.Advanced (goldenTest)
import System.Process (readProcessWithExitCode)

import Data.Char (isAlphaNum, isDigit, isUpper, ord, toLower)
import Data.List (isInfixOf, nub)

import Translate (translate)
import Emitter (emitText)
import LeanEmitter (emitLean)
import TptpEmitter (emitTptp)
import Helpers (capitalize, trySync)
import TptpConvert (parseProof)
import Types
import qualified Data.Text as Text
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TLE

-- Runs the suite with small prover time limits and a 30 s timeout per test.
main :: IO ()
main = do
  -- A failing Twee call uses its whole time limit, so keep the limits small,
  -- 5 s per call and 10 s per run, well under the 30 s test timeout.
  setEnv "TAELJA_TWEE_TIMEOUT" "5"
  setEnv "TAELJA_FALLBACK_TIMEOUT" "10"
  -- A missing golden is an error rather than created from the output, so
  -- every golden has been checked by hand.
  defaultMain (adjustOption defaultTimeout (localOption (NoCreateFile True) tests))
  where
    defaultTimeout NoTimeout = mkTimeout (30 * 1000000)
    defaultTimeout t         = t

-- The golden tests by prover and output format, and the Lean step tests.
tests :: TestTree
tests = testGroup "Taelja"
  [ testGroup "Handcrafted" (map (mkTextTest "expected_vampire" "baseline_vampire") handcraftedNames)
  , testGroup "Vampire"     (map (mkTextTest "expected_vampire" "baseline_vampire") vampireBenchmarkNames)
  , testGroup "E"           (map (mkTextTest "expected_e"       "baseline_e")       eBenchmarkNames)
  , testGroup "Twee"        (map (mkTextTest "expected_twee"    "baseline_twee")    tweeBenchmarkNames)
  , testGroup "No fallback" (map mkNoFallbackTest suiteNames)
  , testGroup "Lean"        (leanRootTest : map mkLeanTest suiteNames)
  , testGroup "TPTP"        (map mkTptpTest suiteNames)
  , testGroup "Lean, steps"  leanStepTests
  ]

-- Every proof of the suite, by prover, each once.
suiteNames :: [(String, String)]
suiteNames = nub $
  [ ("vampire", n) | n <- handcraftedNames ++ vampireBenchmarkNames ] ++
  [ ("e",       n) | n <- eBenchmarkNames ] ++
  [ ("twee",    n) | n <- tweeBenchmarkNames ]

-- The Twee proofs.
tweeBenchmarkNames :: [String]
tweeBenchmarkNames =
  -- a negated conjecture whose source is not a clause, so the leaf's clause
  -- is the nucleus
  [ "KLE137+1"
  -- a goal Twee derived by rewriting one hypothesis with another, read as
  -- one rewrite by each
  , "GRP136-1"
  -- nested Twee steps, each non-axiom premise replayed from its own step
  , "COL042-7"
  -- c22 fixes a variable the previous rewrite left open, without binding
  -- the equation's own X2
  , "GRP509-1"
  -- a Twee step rewriting a fact P, read as P = true with one rewrite by the
  -- equation and one by the fact
  , "LCL170-3"
  -- Twee rewrites a body literal of c3 by c2 and c5 before resolving it with
  -- c2, so the body atom is c2's instance with those rewrites undone
  , "CAT003-4"
  -- a premise derived more generally than Twee printed it, leaving c4's
  -- head-only variables free where c5 has them equal
  , "LCL431-2"
  -- Twee rewrites the head of c3 by c8 while its body literal remains, so
  -- the derived unit c12 is the rewritten head
  , "CAT014-4"
  -- a chain rewriting a body literal of c6 cites c11, a resolvent of input
  -- units that nothing names yet
  , "SWV251-2"
  -- c13 and c14 both rewrite by the non-ground equation c12, and its second
  -- use is named too
  , "GRP013-1"
  -- the Twee step c13 has the premise X2 = X2, taken by reflexivity, so it
  -- is one rewrite by c12
  , "GRP012-3"
  -- c25 rewrites by c24, whose variables only the remaining literal fixes,
  -- so the chain cites the instance of c24 the lemma sub-run proved
  , "HEN010-3"
  -- the lemma sub-run proves c20 only at its Skolem constants, so the Twee
  -- step c39 using it is read at the instance it needs
  , "BOO006-1"
  -- nested Twee steps reach true in Lemma 21, leave it and come back, a
  -- loop the chain drops
  , "KLE143+2"
  -- Twee's c34 equates two true atoms, which is not a first-order statement,
  -- so it is spliced in where used rather than stated as a lemma
  , "SWB005+2"
  , "sam"
  , "ANA007-2"
  , "HEN005-6"
  , "thesis_example_both_lemmas_cnf"
  , "COL003-4"
  , "LCL146-1"
  , "paper_eq"
  , "paper_eq_cnf"
  , "GRP007-1"
  , "ANA023-2"
  , "HEN006-4"
  , "HEN004-6"        -- c8 rewrites the axiom X2 = Y2, which must not be read as the rewriter
  , "GEO002-4"        -- c17 resolves two body atoms of c6 with one unit
  , "COL083-1"
  , "LCL126-1"
  , "SYN140-1"
  , "SYN553-1"
  , "CAT019-1"
  -- the existential goal Y = apply(combinator,Y) gets its witness only at
  -- the root resolution, which θ must keep
  , "COL008-1"
  , "COL010-1"
  , "COL015-1"
  , "COL017-1"
  , "COL021-1"
  , "COL022-1"
  -- goal literals sharing variables, so one substitution must instantiate
  -- them all
  , "PUZ011-1"
  -- an equation with a bare variable side, which rewrites any term
  , "SWV818-1"
  , "SWV819-1"
  , "SET865-2"        -- goal clause mixing a disequality with a negative atom
  , "CSR031+1"        -- a conjecture ~A that Twee writes as a cnf unit
  , "SYN387+1"        -- a cnf conjecture p | ~p, read as p => p
  , "LCL133-1"        -- goal x = y, whose symbols come only through implies(truth,X) = X
  , "ANA133-1"        -- symbols such as '+', quoted in the input proof
  , "LCL897-10"       -- the symbol ' = =>', quoted in the text
  , "LCL902+1"        -- an instance of c31 rewritten by c17 at a variable position
  , "GRP654+1"        -- a lemma applies the Skolem function to other arguments than the goal
  , "GRP655+1"        -- a Skolem function per conjunct, each defined in the TPTP output
  ]

-- Vampire proofs of small problems written by hand.
handcraftedNames :: [String]
handcraftedNames =
  [ "agda_vampire_ze_uniq"  -- the worked example of Sinkarovs and Rawson, When Agda met Vampire
  , "test_rl_safety"
  , "test_eq_symmetry"
  , "test_nonunit_single"
  , "test_nonunit_chain"
  , "test_split_derived_unit"
  -- a body atom that becomes t = t, before another body atom
  , "test_trivial_body_atom"
  , "test_instantiations_no_ground"
  , "test_prelemmatize_sym_eq"
  , "test_eqchain_in_havehence"
  , "test_havehence_in_eqchain"
  , "test_axioms_contradictory"
  -- plain TPTP style, with bare axioms, cnf clausification, a negate step
  -- and the implication conjecture p => r
  , "tptp_implication_conjecture"
  -- typed proofs, read with sorts erased and printed typed by --tptp
  , "tff_nato"
  -- NATO with one-place predicates, the example of the talk
  , "tff_nato_short"
  -- a lemma over a variable of sort person and a premise over sort city
  , "tff_typed_lemma"
  -- ? [X] : (p(X) & r(X)) gives two axioms through a Skolem definition the
  -- TPTP output cites, and the conjecture is existential
  , "fof_skolem_definition"
  -- two goal atoms with one predicate, each with its own instance from the
  -- negated conjecture
  , "fof_existential_goals"
  ]

-- Vampire proofs of TPTP problems and worked examples.
vampireBenchmarkNames :: [String]
vampireBenchmarkNames =
  -- a chain rewriting by zero = divide(zero,X), whose fresh variable the
  -- next step fixes
  [ "HEN009-3"
  -- derived equations whose chains are read off their demodulations and
  -- superpositions
  , "GRP451-1"
  -- the refutation rewrites inside the Skolem term sK0(W), so the goals are
  -- stated at the resulting witness and a lemma proves W equal to it
  , "GRP658+1"
  -- a candidate lemma whose sub-proof must read its own conjecture and not
  -- the outer one
  , "ALG210+2"
  , "ANA023-2"
  , "GRP001-5"
  , "LCL146-1"
  , "horn_example_derived_rw"
  , "horn_example_elim_var_rw"
  , "horn_example_eq_head_inlined"
  , "horn_example_eq_rw_chain"
  , "horn_example_relational_rw"
  , "krympa_example_hay"
  , "pure_equational_example"
  , "resolution_example_eq_positive_rewrite"
  , "resolution_example_horn_2unit"
  , "resolution_example_horn_dag"
  , "resolution_example_horn_general"
  , "resolution_example_horn_reuse_forced"
  , "resolution_example_horn_reuse_n1"
  , "resolution_example_pqr"
  , "superposition_example_nonground_lemma"
  , "superposition_example_unit1"
  , "superposition_example_unit2"
  , "superposition_exercise12_2"
  , "units_only_relational_example"
  , "krympa_example5_nonparallel"
  , "resolution_example_horn_reuse_inlined"
  , "resolution_example_shared_varname"
  , "superposition_example_clausal1"
  , "superposition_example_clausal2"
  , "thesis_example_both_lemmas"
  , "paper_heu"
  , "GRP041-2"
  , "GRP007-1"
  , "HEN006-4"
  , "HEN008-2"
  , "tau_shared"
  , "tau_mixed"
  , "COL083-1"
  , "NUM025-1"
  , "LAT005-2"
  , "ANA009-2"
  , "SYN558-1"
  , "SYN719-1"
  , "LCL430-2"        -- a nucleus variable the step binds, renamed apart inside a premise's term
  -- a conclusion that is the cited axiom's head flipped, which the Lean
  -- step states by Eq.symm
  , "HEN003-3"
  -- a premise-free block citing a conditional axiom states its head under
  -- θ, since the general head would drop the condition
  , "RNG038-1"
  -- a hypothesis whose variable was eliminated at a witness must be rewritten
  -- at that same witness
  , "RNG039-1"
  -- a negated goal that Vampire rewrites to the trivial disequation
  -- unordered_pair(sK4,sK4) != unordered_pair(sK4,sK4)
  , "SET886+1"
  , "PUZ011-1"        -- goal literals instantiated under one shared substitution
  , "NLP258-1"
  , "SWV818-1"
  -- ? [X0] : ! [X1] : G, whose Skolem term for X1 is a variable again in
  -- the stated goal
  , "GRP656+1"
  , "GRP195-1"        -- a chain that returns to an earlier term once its variables are bound
  , "TOP050-1"        -- a step rewriting every occurrence of a constant in a premise
  ]

-- The E proofs.
eBenchmarkNames :: [String]
eBenchmarkNames =
  [ "GRP001-5"
  -- derived equations read off E's nested steps, whose unprinted clauses
  -- the replay supplies
  , "GRP117-1"
  -- E simplifies ~(p(z) => p(z)) to ~$true, and the resolution is put back
  , "SYN973+1"
  , "COL003-4"
  , "LCL146-1"
  , "e_unit_source_axiom"
  , "horn_example_derived_rw"
  , "horn_example_elim_var_rw"
  , "horn_example_eq_head_inlined"
  , "horn_example_eq_rw_chain"
  , "horn_example_relational_rw"
  , "krympa_example_hay"
  , "pure_equational_example"
  , "resolution_example_eq_positive_rewrite"
  , "resolution_example_horn_2unit"
  , "resolution_example_horn_dag"
  , "resolution_example_horn_general"
  , "resolution_example_horn_reuse_forced"
  , "resolution_example_horn_reuse_n1"
  , "resolution_example_pqr"
  , "superposition_example_nonground_lemma"
  , "krympa_example5_nonparallel"
  , "resolution_example_horn_reuse_inlined"
  , "superposition_example_clausal1"
  , "superposition_example_clausal2"
  , "horn_rel_two_step_chain"
  , "HEN006-4"
  , "GRP007-1"
  , "ANA023-2"
  , "tau_shared"
  , "tau_mixed"
  , "COL083-1"
  , "GRP009-1"
  , "GRP012-2"
  , "LCL212-3"
  , "SYO632-1"
  , "COL099-1"
  , "SYN179-1"
  , "SYN555-1"
  , "ALG006-1"
  -- a permutative equation in one rw step, which the replay applies once
  -- rather than normalising with it
  , "ALG442-1"
  -- resolution against a headless clause, whose replayed resolvent must not
  -- carry the consumer's head twice or θ loses a binding
  , "ANA027-2"
  , "COL006-2"
  , "GRP703-10"
  , "SYN163-1"        -- a premise variable named like a nucleus variable the step binds is renamed apart (Lemma 62), and a block is instantiated without capturing its own variables (Goal 1)
  , "SYN159-1"        -- a premise variable named like a nucleus variable the step binds, renamed apart
  , "LCL126-1"        -- goal cited from an axiom whose head is an instance of it, not a variant
  , "PUZ011-1"        -- goal literals instantiated under one shared substitution
  , "GRP192-1"
  , "SWV818-1"
  , "SWV819-1"
  -- superposition with an equation used as a demodulator, which replaces
  -- every occurrence of the redex
  , "LAT263-2"
  -- a Horn premise brings its body literals along, and a duplicate must be
  -- condensed before the unit removes it
  , "MGT006-1"
  , "MGT010-1"
  -- contextual simplify-reflect with an all-negative clause cancels the
  -- head and brings the other conditions along
  , "MGT001-1"
  , "MGT032-2"
  , "SYN590-1"
  , "SYN982-1"
  , "SYO611-1"        -- three goal conjuncts, whose pairing with the proved goals is searched
  -- a goal clause mixing a disequality with negative atoms states two goals
  , "SET864-2"
  -- an implication conjecture whose equational hypothesis rewrites in the
  -- goal chain
  , "fof_equational_hypothesis"
  -- E's definition ~epred <=> ! [X] (~a | ~b) unfolds to the existential
  -- goals a and b
  , "SYN577-1"
  , "COM001_1"        -- a typed proof from E, whose clauses are tcf units
  -- E's propositional refutation, replayed as a chain of resolutions
  , "e_cdclpropres"
  , "CSR026+3"        -- the same step over seven clauses, a chain through a lemma
  -- one formula giving two axioms with the same body, which must keep their
  -- own numbers or a step cites the other
  , "MGT001+1"
  -- a hypothesis of the conjecture, stated rather than proved, so not a
  -- lemma candidate
  , "LCL888+1"
  , "LCL902+1"        -- symbols such as '==>' and '>='
  , "SWW967+1"        -- body atoms of c_0_12 that E rewrites to true by the unit c_0_13
  , "SWW968+1"        -- E's condensation, named condense
  , "CSR117+1"        -- a conjunct proved twice and one never, and 55.67631 quoted
  , "GRP656+1"        -- a Skolem function E leaves undefined, defined in the TPTP output
  , "GRP035-3"        -- a spliced unit read at the instance its premise was derived at
  , "HEN008-1"        -- a unit rewritten by a conditional equation whose condition is resolved after
  , "GRP415-1"        -- a rewrite that binds a variable an earlier rewrite brought in free
  , "GRP430-1"        -- the same, where the binding is the constant a1
  , "GRP655+2"        -- a long rw chain that brings in many free variables
  , "GRP410-1"        -- c_0_77's first rw brings in a free variable its second rw binds
  ]

-- The Lean module name of a proof. A TPTP name keeps its separator as a
-- letter, p for + and t for _, and drops a -, so MGT001+1 and MGT001-1 get
-- distinct modules. Other names are camel-cased.
leanModule :: String -> String
leanModule name = case name of
  (a : b : c : rest)
    | all isUpper [a, b, c]
    , (num, sep : version) <- span isDigit rest
    , length num == 3, not (null version), all (\x -> isDigit x || x == '.') version ->
        a : map toLower [b, c] ++ num ++ separator sep ++ map (\x -> if x == '.' then 'v' else x) version
  _ -> concatMap capitalize (splitWords name)
  where
    separator '-' = ""
    separator '+' = "p"
    separator '_' = "t"
    separator x   = "c" ++ show (ord x)
    splitWords w = case span isAlphaNum w of
      (x, [])       -> [x]
      (x, _ : more) -> x : splitWords more

-- Each suite proof as a Lean file. The golden is its module in the Lean
-- project under lean/, so Lean checks exactly what the translator prints.
mkLeanTest :: (String, String) -> TestTree
mkLeanTest (prover, name) = goldenVsString (prover ++ "/" ++ name)
  ("lean/TaeljaVerify/" ++ capitalize prover ++ "/" ++ leanModule name ++ ".lean")
  (runEncoded utf8 (emitLean (capitalize prover ++ leanModule name)) ("test/baseline_" ++ prover ++ "/" ++ name ++ ".tstp"))

-- The root module of the Lean project, which imports every suite proof.
leanRootTest :: TestTree
leanRootTest = goldenVsString "TaeljaVerify.lean" "lean/TaeljaVerify.lean" $ return $ utf8 $ unlines $
  [ "-- The root of the `TaeljaVerify` library: one module per proof of the test"
  , "-- suite, as `taelja --lean` prints it.  The test suite keeps this file and"
  , "-- the modules up to date (cabal test --test-options=--accept)." ]
  ++ [ "import TaeljaVerify." ++ capitalize prover ++ "." ++ leanModule name | (prover, name) <- suiteNames ]

-- The Lean output must state a step only when it is the inference the
-- proof claims, and otherwise leave a taelja_* name Lean rejects. Each test
-- is a small proof, correct or with one wrong step.
leanStepTests :: [TestTree]
leanStepTests =
  [ stated   "have and hence"                 [Have pa "axiom 1", Hence qa (ByAxiom "axiom 2")]
  , unstated "have by an axiom stating another fact" [Have pb "axiom 1", Hence qa (ByAxiom "axiom 2")]
  , unstated "hence without its premise"      [Hence qa (ByAxiom "axiom 2")]
  , unstated "hence of another instance"      [Have pa "axiom 1", Hence (Rel "q" [b]) (ByAxiom "axiom 2")]
  , unstated "block ending on another fact"   [Have pa "axiom 1"]
  , statedFor pa   "rewrite of the line before"    [Have pfa "axiom 4", Hence pa (ByRw "axiom 3" LR)]
  , unstatedFor pa "rewrite in the wrong direction" [Have pfa "axiom 4", Hence pa (ByRw "axiom 3" RL)]
  , unstatedFor pb "rewrite into another term"     [Have pfa "axiom 4", Hence pb (ByRw "axiom 3" LR)]
  , statedFor (Rel "r" [c])   "body equation closed by reflexivity" [Have (Rel "r" [c]) "axiom 5"]
  , unstatedFor (Rel "r" [a]) "body equation that is not reflexive" [Have (Rel "r" [a]) "axiom 5"]
  , chainTest True  "chain of two steps" [(step, f a), (step, a)]
  , chainTest False "chain step that is two rewrites" [(step, a)]
  , chainTest False "chain step in the wrong direction" [(step { rwDir = RL }, f a), (step, a)]
  ]
  where
    a = Const "a"; b = Const "b"; c = Const "c"
    f t = App "f" [t]
    x = Var "X"
    pa = Rel "p" [a]; pb = Rel "p" [b]; qa = Rel "q" [a]; pfa = Rel "p" [f a]
    step = RwStep "axiom 3" (f x, x) LR
    proofOf goal blk = StructuredProof
      { axioms = [ AUnit "axiom 1" pa
                 , ANucleus "axiom 2" (Clause [Rel "p" [x]] (Just (Rel "q" [x])))
                 , AUnit "axiom 3" (Eq (f x) x)
                 , AUnit "axiom 4" pfa
                 , ANucleus "axiom 5" (Clause [Eq x c] (Just (Rel "r" [x]))) ]
      , lemmas = [], goals = [(goal, blk)], spInput = emptyInput }
    holds goal blk = let out = emitLean "" (proofOf goal blk)
                     in not (any (`isInfixOf` out) [ "taelja_step_not_justified"
                                                   , "taelja_unbound_variable"
                                                   , "taelja_undeclared_symbol" ])
    check want name goal blk = goldenTest name (return want) (return (holds goal blk))
      (\w got -> return (if w == got then Nothing
                          else Just (if w then "a correct step is not stated" else "a wrong step is stated")))
      (const (return ()))
    statedFor goal name ls   = check True name goal (HaveHence ls)
    unstatedFor goal name ls = check False name goal (HaveHence ls)
    stated   = statedFor qa
    unstated = unstatedFor qa
    chainTest want name steps = check want name (Eq (f (f a)) a) (EqChain (f (f a)) steps)

-- A proof translated to text and compared with its golden .txt file.
mkTextTest :: String -> String -> String -> TestTree
mkTextTest expectedDir prover name = goldenVsString name
  ("test/" ++ expectedDir ++ "/" ++ name ++ ".txt")
  (runAscii emitText ("test/" ++ prover ++ "/" ++ name ++ ".tstp"))

-- Each suite proof translated by the executable with --no-fallback must
-- match its golden exactly, stderr included. The golden belongs to the
-- prover's group, so --accept never rewrites it from here.
mkNoFallbackTest :: (String, String) -> TestTree
mkNoFallbackTest (prover, name) = goldenTest (prover ++ "/" ++ name)
  (LBS.readFile ("test/expected_" ++ prover ++ "/" ++ name ++ ".txt"))
  (do (_, out, err) <- readProcessWithExitCode "taelja"
        ["--no-fallback", "test/baseline_" ++ prover ++ "/" ++ name ++ ".tstp"] ""
      return (LBS.pack (out ++ err)))
  (\golden out -> return (if golden == out then Nothing else Just "differs from the golden with the fallback off"))
  (const (return ()))

-- Each suite proof as a TPTP derivation. The suite only compares, so accept
-- a golden here only after GDV has verified it against the problem.
mkTptpTest :: (String, String) -> TestTree
mkTptpTest (prover, name) = goldenVsString (prover ++ "/" ++ name)
  ("test/expected_tptp/" ++ prover ++ "/" ++ name ++ ".p")
  (runAscii emitTptp ("test/baseline_" ++ prover ++ "/" ++ name ++ ".tstp"))

-- Translates and renders a proof file whose output is ASCII.
runAscii :: (StructuredProof -> String) -> FilePath -> IO LBS.ByteString
runAscii = runEncoded LBS.pack

-- Text as UTF-8 bytes. Lean output is not ASCII, so it is compared this way.
utf8 :: String -> LBS.ByteString
utf8 = TLE.encodeUtf8 . TL.pack

-- Translates a proof file and renders it with the given encoding. A parse
-- error, a refusal or a crash fails the test.
runEncoded :: (String -> LBS.ByteString) -> (StructuredProof -> String) -> FilePath -> IO LBS.ByteString
runEncoded encode render path = do
  raw <- TIO.readFile path
  case parseProof (Text.unpack raw) of
    Left err   -> fail ("Parse error in " ++ path ++ ": " ++ err)
    Right tstp -> do
      -- a refusal or a crash fails the test, so no golden records one
      result <- trySync (translate False tstp >>= evaluate . force . fmap render)
      case result of
        Right (Right out)   -> return (encode out)
        Right (Left reason) -> fail ("translation failed: " ++ reason)
        Left e              -> fail (show e)
