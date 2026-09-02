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
  , "LAT005-2"
  , "ANA009-2"
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
  , "HEN008-2"
  , "tau_shared"
  , "tau_mixed"
  , "COL083-1"
  , "SYN179-1"
  , "ALG006-1"
  , "COL006-2"
  , "GRP703-10"
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
      result <- catch (translate False tstp >>= \msp -> evaluate (force (maybe "" emit msp)))
                      (\e -> return (show (e :: SomeException)))
      return (LBS.pack result)
