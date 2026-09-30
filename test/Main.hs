module Main where

import Control.DeepSeq (force)
import Control.Exception (SomeException, catch, evaluate)
import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import System.Environment (setEnv)
import Test.Tasty
import Test.Tasty.Golden
import Test.Tasty.Golden.Advanced (goldenTest)
import System.Process (readProcessWithExitCode)

import Translate (translate)
import Emitter (emit)
import TptpEmitter (emitTptp)
import Helpers (extractSzsBlock)
import Types (StructuredProof)
import qualified Data.Text as Text

main :: IO ()
main = do
  -- A successful Twee fallback here finishes in under 2 s and a failing one
  -- burns the whole budget, so the suite keeps it small.  Normal runs and the
  -- eval use the 15 s default.
  setEnv "TAELJA_TWEE_TIMEOUT" "5"
  defaultMain tests

tests :: TestTree
tests = testGroup "Taelja"
  [ testGroup "Handcrafted" (map (mkTest "expected_vampire" "baseline_vampire") handcraftedNames)
  , testGroup "Vampire"     (map (mkTest "expected_vampire" "baseline_vampire") benchmarkNames)
  , testGroup "E"           (map (mkTest "expected_e"       "baseline_e")       eBenchmarkNames)
  , testGroup "Twee"        (map (mkTest "expected_twee"    "baseline_twee")    tweeBenchmarkNames)
  , testGroup "Twee, no fallback" (map mkReadTest tweeReadNames)
  , testGroup "TPTP"        (map mkTptpTest tptpNames)
  ]

-- Every proof of the suite printed as a TPTP derivation by --tptp.
tptpNames :: [(String, String)]
tptpNames =
  [ ("vampire", n) | n <- handcraftedNames ++ benchmarkNames ] ++
  [ ("e",       n) | n <- eBenchmarkNames ] ++
  [ ("twee",    n) | n <- tweeBenchmarkNames ]

tweeBenchmarkNames :: [String]
tweeBenchmarkNames =
  -- a negated conjecture whose source is the negated universal formula,
  -- which is no clause, so the clause the leaf states is the nucleus
  [ "KLE137+1"
  -- a goal Twee derived by rewriting one hypothesis with another, replayed
  -- from that step as one rewrite with each, with no call to Twee
  , "GRP136-1"
  -- a chain of Twee steps, each premise that is no axiom replayed from the
  -- step that derived it, down to the axioms
  , "COL042-7"
  -- a step whose rewrite fixes a variable the first rewrite left open, as
  -- c22 fixes A to X2, where the equation's own X2 must not be bound
  , "GRP509-1"
  -- a Twee step that rewrites a fact, read as P = true, one rewrite with its
  -- equation and one with the fact, as c4 rewrites axiom(implies(A,or(B,A)))
  , "LCL170-3"
  -- Twee rewrites a body literal of the nucleus c3 by c2 and c5 before
  -- resolving it with c2, so the body atom is c2's instance with those
  -- rewrites undone
  , "CAT003-4"
  -- a premise the algorithm derives more generally than Twee printed it,
  -- with the head-only variables of c4 free where c5 has them equal
  , "LCL431-2"
  -- Twee rewrites the head of the nucleus c3 by c8 while its body literal
  -- remains, so the electron it derives, c12, is the head rewritten
  , "CAT014-4"
  -- the chain that rewrites a body literal of c6 cites c11, which resolution
  -- derived from input units, so it is read though nothing names it yet
  , "SWV251-2"
  -- c13 and c14 rewrite a body literal of c5 by c12, an equation with a
  -- variable that the tree uses twice, and its second use is named too
  , "GRP013-1"
  -- the premise c2 of the Twee step c13 is X2 = X2, taken by reflexivity,
  -- so the step is one rewrite by c12
  , "GRP012-3"
  -- c25 rewrites zero to a larger term by c24, whose variables only the
  -- literal the step leaves fixes, and the chain cites the instance of c24
  -- the lemma sub-run proved, stated the way round the electron is
  , "HEN010-3"
  -- the lemma sub-run proves c20 only under its Skolem constants, so the
  -- Twee step c39 that rests on it is read at the instance its use needs
  , "BOO006-1"
  -- the reading of nested Twee steps reaches true in Lemma 21 and goes out
  -- and back to it, a loop the chain drops
  , "KLE143+2"
  -- Twee's c34 equates two atoms that both hold, which is no first-order
  -- statement, so it is spliced where used and never stated as a lemma
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
  , "COL083-1"
  , "LCL126-1"
  , "SYN140-1"
  , "SYN553-1"
  , "CAT019-1"
  -- the existential goal Y = apply(combinator,Y) gets its witness only at the
  -- root resolution, which θ must keep, and then closes by a two-step chain
  , "COL008-1"
  , "COL010-1"
  , "COL015-1"
  , "COL017-1"
  , "COL021-1"
  , "COL022-1"
  -- the goal literals share their variables, so one substitution must
  -- instantiate them all.  Read independently, borders(X0,X1) took a value
  -- that african(X1) rules out
  , "PUZ011-1"
  -- an equation with a bare variable on one side rewrites any term, so it
  -- is relevant to every goal even when it shares no symbol with one
  , "SWV818-1"
  , "SWV819-1"
  , "SET865-2"        -- goal clause mixing a disequality with a negative atom
  , "CSR031+1"        -- a conjecture ~A that Twee writes as a cnf unit
  , "SYN387+1"        -- a cnf conjecture p | ~p, read as p => p
  , "LCL133-1"        -- goal x = y, whose symbols come only through implies(truth,X) = X
  , "ANA133-1"        -- symbols such as '+' that Twee prints infix, given aliases for the call
  , "LCL897-10"       -- the symbol ' = =>', quoted in the text
  , "LCL902+1"        -- an instance of c31 rewritten by c17 at a variable position
  ]

handcraftedNames :: [String]
handcraftedNames =
  [ "agda_vampire_ze_uniq"  -- the worked example of Sinkarovs and Rawson, When Agda met Vampire
  , "test_rl_safety"
  , "test_eq_symmetry"
  , "test_nonunit_single"
  , "test_nonunit_chain"
  , "test_split_derived_unit"
  , "test_instantiations_no_ground"
  , "test_prelemmatize_sym_eq"
  , "test_eqchain_in_havehence"
  , "test_havehence_in_eqchain"
  , "test_axioms_contradictory"
  -- a proof in plain TPTP style, with bare axioms, clausification by cnf, the
  -- negation step named negate, and an implication conjecture p => r
  , "tptp_implication_conjecture"
  -- typed proofs, read with their sorts erased and printed typed by --tptp.
  -- The second has a lemma over a variable of sort person and a premise over
  -- one of sort city
  , "tff_nato"
  -- NATO with one-place predicates, the example of the talk
  , "tff_nato_short"
  , "tff_typed_lemma"
  -- a FOF axiom ? [X] : (p(X) & r(X)) gives two clauses, so two axioms, through
  -- a Skolem definition that the TPTP output cites, and the conjecture is
  -- existential
  , "fof_skolem_definition"
  -- two goal atoms with one predicate, each taking its own instance from the
  -- negated conjecture clause
  , "fof_existential_goals"
  ]

benchmarkNames :: [String]
benchmarkNames =
  -- a Twee chain rewriting by zero = divide(zero,X), whose fresh variable the
  -- next step fixes
  [ "HEN009-3"
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
  , "LCL430-2"        -- premise freshening of a tau-bound nucleus variable nested in a term
  , "HEN003-3"        -- a conclusion matches the cited axiom's head only when flipped, so Lean needs .symm
  -- a block with no premises that cites a conditional axiom must state its
  -- head under theta.  The general head would drop the axiom's condition
  , "RNG038-1"
  -- a hypothesis whose variable was eliminated at a witness must be rewritten
  -- at that same witness
  , "RNG039-1"
  -- a rewrite that leaves unordered_pair(sK4,sK4) = unordered_pair(sK4,sK4),
  -- which Lean's rw closes by rfl before the step's exact
  , "SET886+1"
  , "PUZ011-1"        -- goal literals instantiated under one shared substitution
  , "NLP258-1"
  , "SWV818-1"
  -- ? [X0] : ! [X1] : G, whose Skolem function term for X1 is the variable
  -- again in the stated goal
  , "GRP656+1"
  ]

-- Benchmarks for which an E prover output exists.
eBenchmarkNames :: [String]
eBenchmarkNames =
  [ "GRP001-5"
  , "SYN973+1"        -- E simplifies ~(p(z) => p(z)) to ~$true; the resolution of the clauses is put back
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
  -- E records each demodulation as its own rw step, and this equation only
  -- permutes its arguments, so the replay applies it once rather than
  -- normalising with it
  , "ALG442-1"
  -- resolution against a clause with no head.  The replayed resolvent must
  -- not carry the consumer's head twice, or theta loses the binding that only
  -- this resolution determines
  , "ANA027-2"
  , "COL006-2"
  , "GRP703-10"
  , "SYN163-1"        -- identity-binding freshening (Lemma 62) and capture-avoiding block instantiation (Goal 1)
  , "SYN159-1"        -- identity-binding freshening of a tau-bound nucleus variable
  , "LCL126-1"        -- goal cited from an axiom whose head is an instance of it, not a variant
  , "PUZ011-1"        -- goal literals instantiated under one shared substitution
  , "GRP192-1"
  , "SWV818-1"
  , "SWV819-1"
  -- superposition with an equation that the prover used as a demodulator,
  -- replacing every occurrence of the redex rather than just one
  , "LAT263-2"
  -- a Horn premise brings its body literals along, and a duplicate must be
  -- condensed before the unit removes it
  , "MGT006-1"
  , "MGT010-1"
  -- contextual simplify-reflect with an all-negative clause of several
  -- literals cancels the head and brings the other conditions along
  , "MGT001-1"
  , "MGT032-2"
  , "SYN590-1"
  , "SYN982-1"
  , "SYO611-1"        -- three goal conjuncts, whose pairing with the proved goals is searched
  -- a goal clause whose literals mix a disequality with negative atoms,
  -- X1 != v_x(X1) | ~c_in(X1,v_S,tc_set(t_a)), states two goals
  , "SET864-2"
  -- an implication conjecture whose hypothesis is an equation, used as a
  -- rewrite in the goal chain
  , "fof_equational_hypothesis"
  -- E abbreviates the negated conjecture's conjuncts as ~epred <=> ! [X] (~a | ~b),
  -- which unfolds to the existential goals a and b
  , "SYN577-1"
  , "COM001_1"        -- a typed proof from E, whose clauses are tcf units
  -- E's propositional refutation of the cited Horn clauses, replayed as the
  -- chain of resolutions
  , "e_cdclpropres"
  , "CSR026+3"        -- the same step over seven clauses, a chain through a lemma
  -- one source formula stating two axioms with the same body and different
  -- heads, which must keep their own numbers or a step cites the other one
  , "MGT001+1"
  -- a hypothesis the conjecture grants, which is stated and not proved, so it
  -- is no lemma candidate
  , "LCL888+1"
  , "LCL902+1"        -- symbols such as '==>' and '>=', which Twee prints infix
  , "SWW967+1"        -- a re-proof citing the outer candidate lemma c_0_13, stated too
  , "SWW968+1"        -- E's condensation, named condense
  , "CSR117+1"        -- a conjunct proved twice and one never, and 55.67631 quoted
  ]

mkTest :: String -> String -> String -> TestTree
mkTest expectedDir prover name = goldenVsString name
  ("test/" ++ expectedDir ++ "/" ++ name ++ ".txt")
  (run emit ("test/" ++ prover ++ "/" ++ name ++ ".tstp"))

-- The Twee proofs the translation reads from the input proof alone.  The
-- executable translates each with the fallback off, and the output must be
-- its golden unchanged.  The golden belongs to the Twee group, so accepting
-- never rewrites it from here.
tweeReadNames :: [String]
tweeReadNames = filter (/= "KLE137+1") tweeBenchmarkNames
  -- KLE137+1 resolves an equation with a unit by rewriting it to t = t

mkReadTest :: String -> TestTree
mkReadTest name = goldenTest name
  (LBS.readFile ("test/expected_twee/" ++ name ++ ".txt"))
  (do (_, out, err) <- readProcessWithExitCode "taelja" ["--no-fallback", "test/baseline_twee/" ++ name ++ ".tstp"] ""
      return (LBS.pack (out ++ err)))
  (\golden out -> return (if golden == out then Nothing else Just "differs from the golden with the fallback off"))
  (const (return ()))

mkTptpTest :: (String, String) -> TestTree
mkTptpTest (prover, name) = goldenVsString (prover ++ "/" ++ name)
  ("test/expected_tptp/" ++ prover ++ "/" ++ name ++ ".p")
  (run emitTptp ("test/baseline_" ++ prover ++ "/" ++ name ++ ".tstp"))

run :: (StructuredProof -> String) -> FilePath -> IO LBS.ByteString
run render path = do
  raw <- TIO.readFile path
  let contents = Text.pack (extractSzsBlock (Text.unpack raw))
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err   -> fail ("Parse error in " ++ path ++ ": " ++ err)
    Right tstp -> do
      result <- catch (translate False tstp >>= \msp -> evaluate (force (either (++ "\n") render msp)))
                      (\e -> return (show (e :: SomeException)))
      return (LBS.pack result)
