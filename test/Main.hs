module Main where

import Control.DeepSeq (force)
import Control.Exception (SomeException, catch, evaluate)
import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import Test.Tasty
import Test.Tasty.Golden

import Translate (translate)
import Emitter (emit)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Taelja"
  [ testGroup "Handcrafted" (map (mkTest "expected_vampire" "baseline_vampire") handcraftedNames)
  , testGroup "Vampire"     (map (mkTest "expected_vampire" "baseline_vampire") benchmarkNames)
  , testGroup "E"           (map (mkTest "expected_e"       "baseline_e")       eBenchmarkNames)
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
  [ "horn_example_derived_rw"
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
  , "superposition_example_clausal1"
  , "superposition_example_clausal2"
  ]

-- Benchmarks for which an E prover output exists.
eBenchmarkNames :: [String]
eBenchmarkNames =
  [ "horn_example_derived_rw"
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
  ]

mkTest :: String -> String -> String -> TestTree
mkTest expectedDir prover name = goldenVsString name
  ("test/" ++ expectedDir ++ "/" ++ name ++ ".txt")
  (run ("test/" ++ prover ++ "/" ++ name ++ ".tstp"))

run :: FilePath -> IO LBS.ByteString
run path = do
  contents <- TIO.readFile path
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err   -> fail ("Parse error in " ++ path ++ ": " ++ err)
    Right tstp -> do
      result <- catch (evaluate (force (emit (translate False tstp))))
                      (\e -> return (show (e :: SomeException)))
      return (LBS.pack result)
