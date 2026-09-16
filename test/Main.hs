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
  [ "sam"
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
  , "KLE057+1"        -- a conjecture written G <= H, negated by Twee's negate_conjecture
  ]

handcraftedNames :: [String]
handcraftedNames =
  [ "test_rl_safety"
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
  , "tff_typed_lemma"
  -- a FOF axiom ? [X] : (p(X) & r(X)) gives two clauses, so two axioms, through
  -- a Skolem definition that the TPTP output cites, and the conjecture is
  -- existential
  , "fof_skolem_definition"
  -- a conjecture concluding a negation, proved by assuming the negated
  -- conjuncts and deriving $false from an axiom with head $false
  , "ALG018+1"
  -- a hypothesis ? [Y] : r(X,Y) reaches its clause through Vampire's
  -- skolemisation step, which also cites the Skolem definition it introduced
  , "fof_skolem_hypothesis"
  -- two goal atoms with one predicate, each taking its own instance from the
  -- negated conjecture clause
  , "fof_existential_goals"
  ]

benchmarkNames :: [String]
benchmarkNames =
  [ "ANA023-2"
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
  , "PUZ011-1"        -- goal literals instantiated under one shared substitution
  , "NLP258-1"
  , "SWV818-1"
  ]

-- Benchmarks for which an E prover output exists.
eBenchmarkNames :: [String]
eBenchmarkNames =
  [ "GRP001-5"
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
  -- a goal clause whose literals mix a disequality with negative atoms,
  -- X1 != v_x(X1) | ~c_in(X1,v_S,tc_set(t_a)), states two goals
  , "SET864-2"
  -- an implication conjecture whose hypothesis is a Horn clause, which E
  -- prints with its literals reordered
  , "fof_reordered_hypothesis"
  -- an implication conjecture whose hypothesis is an equation, used as a
  -- rewrite in the goal chain
  , "fof_equational_hypothesis"
  , "ALG018+1"        -- a conjecture concluding a negation, see the Vampire list
  -- E abbreviates the negated conjecture's conjuncts as ~epred <=> ! [X] (~a | ~b),
  -- which unfolds to the existential goals a and b
  , "SYN577-1"
  , "COM001_1"        -- a typed proof from E, whose clauses are tcf units
  , "e_cdclpropres"   -- refused, its last step is outside the calculus
  -- a negated conjunction whose one negated conjunct is the goal, with E's
  -- negation step nested in a fof_simplification
  , "LCL414+1"
  , "PUZ128+1"        -- ? [X] : (C & ~D), the negation of a universal clause
  , "SYN946+1"        -- refused, the conclusion p(Y) | r(Z) is a disjunction
  ]

mkTest :: String -> String -> String -> TestTree
mkTest expectedDir prover name = goldenVsString name
  ("test/" ++ expectedDir ++ "/" ++ name ++ ".txt")
  (run emit ("test/" ++ prover ++ "/" ++ name ++ ".tstp"))

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
