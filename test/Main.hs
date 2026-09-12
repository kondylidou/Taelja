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
import Helpers (extractSzsBlock)
import qualified Data.Text as Text

main :: IO ()
main = do
  -- Successful Twee fallback calls in the suite finish in under 2 s; a failing
  -- one burns the whole budget, so keep it small here.  The eval and normal
  -- runs use the 15 s default (see TweeInterface.timeoutSecsFromEnv in runTwee).
  setEnv "TAELJA_TWEE_TIMEOUT" "5"
  defaultMain tests

tests :: TestTree
tests = testGroup "Taelja"
  [ testGroup "Handcrafted" (map (mkTest "expected_vampire" "baseline_vampire") handcraftedNames)
  , testGroup "Vampire"     (map (mkTest "expected_vampire" "baseline_vampire") benchmarkNames)
  , testGroup "E"           (map (mkTest "expected_e"       "baseline_e")       eBenchmarkNames)
  , testGroup "Twee"        (map (mkTest "expected_twee"    "baseline_twee")    tweeBenchmarkNames)
  ]

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
  -- existential goal Y = apply(combinator,Y): the witness is bound only at the
  -- root resolution, which θ must keep (Theorem 1's grounding θ); with it the
  -- goal is ground and closes by a two-step chain
  , "COL008-1"
  , "COL010-1"
  , "COL015-1"
  , "COL017-1"
  , "COL021-1"
  , "COL022-1"
  -- the conjecture's goal literals share their variables, so one substitution
  -- has to instantiate all of them: read independently, borders(X0,X1) took
  -- the value african(X1) rules out
  , "PUZ011-1"
  -- an equation with a bare variable on one side rewrites any term, so it
  -- is relevant to every goal even when it shares no symbol with one
  , "SWV818-1"
  , "SWV819-1"
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
  , "LCL430-2"        -- premise freshening of a tau-bound nucleus variable nested in a term (Oop(Y,false), Y -> Ovar(Y'))
  , "HEN003-3"        -- a nucleus's conclusion matches the cited axiom's head only flipped (Eq symmetry); the emitted Lean citation needs .symm (Vampire's own derived clause states "zero = divide(...)")
  -- a body-free block citing a conditional axiom must state its head under
  -- theta, not the axiom's own general head: asserting product(X,h(X,b),b)
  -- from "X = additive_identity => product(X,h(X,Y),Y)" drops the condition
  , "RNG038-1"
  -- rewriting a hypothesis whose own variable was eliminated at a concrete
  -- witness: the rewrite must be instantiated at that same witness
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
  -- E folds each demodulation into its own rw step; the equation here
  -- (u(X,X,Y) = u(Y,X,X)) only permutes its arguments, so the replay
  -- must apply it as a single rewrite rather than normalise with it
  , "ALG442-1"
  -- resolution against a clause whose conclusion keeps no head: the
  -- replayed resolvent must not carry the consumer's head twice, or the
  -- step is rejected and theta loses the binding for the transitivity
  -- argument that only the resolution determines
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
  , "HEN009-1"
  , "HEN010-1"
  , "LAT263-2"
  -- a Horn premise brings its own body literals along; when one is already
  -- present the duplicates must be condensed before the unit removes it
  , "MGT006-1"
  , "MGT010-1"
  -- contextual simplify-reflect with an all-negative clause of several
  -- literals: it cancels the head and brings its other conditions along
  , "MGT001-1"
  , "MGT032-2"
  , "SYN590-1"
  , "SYN982-1"
  ]

mkTest :: String -> String -> String -> TestTree
mkTest expectedDir prover name = goldenVsString name
  ("test/" ++ expectedDir ++ "/" ++ name ++ ".txt")
  (run ("test/" ++ prover ++ "/" ++ name ++ ".tstp"))

run :: FilePath -> IO LBS.ByteString
run path = do
  raw <- TIO.readFile path
  let contents = Text.pack (extractSzsBlock (Text.unpack raw))
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err   -> fail ("Parse error in " ++ path ++ ": " ++ err)
    Right tstp -> do
      result <- catch (translate False tstp >>= \msp -> evaluate (force (maybe "translation failed\n" emit msp)))
                      (\e -> return (show (e :: SomeException)))
      return (LBS.pack result)
