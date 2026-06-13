module Main where

import Control.DeepSeq (force)
import Control.Exception (SomeException, catch, evaluate)
import qualified Data.ByteString.Lazy.Char8 as LBS
import qualified Data.Text.IO as TIO
import Data.Attoparsec.Text (eitherResult, feed)
import Data.TPTP.Parse.Text (parseTSTP)
import Test.Tasty
import Test.Tasty.Golden

import Translator (translate)
import Emitter (emit)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Taelja"
  [ testGroup "Handcrafted"
      [ golden "test_rl_safety"
      , golden "test_eq_symmetry"
      , golden "test_nonunit_single"
      , golden "test_nonunit_chain"
      , golden "test_split_derived_unit"
      , golden "test_instantiations_no_ground"
      , golden "test_prelemmatize_sym_eq"
      , golden "test_eqchain_in_havehence"
      , golden "test_havehence_in_eqchain"
      ]
  , testGroup "Benchmarks"
      [ benchmark "horn_example_derived_rw"
      , benchmark "horn_example_elim_var_rw"
      , benchmark "horn_example_eq_head_inlined"
      , benchmark "horn_example_eq_rw_chain"
      , benchmark "horn_example_relational_rw"
      , benchmark "krympa_example_hay"
      , benchmark "pure_equational_example"
      , benchmark "resolution_example_eq_positive_rewrite"
      , benchmark "resolution_example_horn_2unit"
      , benchmark "resolution_example_horn_dag"
      , benchmark "resolution_example_horn_general"
      , benchmark "resolution_example_horn_reuse_forced"
      , benchmark "resolution_example_horn_reuse_n1"
      , benchmark "resolution_example_pqr"
      , benchmark "superposition_example_nonground_lemma"
      , benchmark "superposition_example_unit1"
      , benchmark "superposition_example_unit2"
      , benchmark "superposition_exercise12_2"
      , benchmark "units_only_relational_example"
      , benchmark "krympa_example5_nonparallel"
      , benchmark "resolution_example_horn_reuse_inlined"
      , benchmark "superposition_example_clausal1"
      , benchmark "superposition_example_clausal2"
      ]
  ]

golden :: String -> TestTree
golden name = goldenVsString name
  ("test/expected/" ++ name ++ ".txt")
  (run ("test/baseline/" ++ name ++ ".tstp"))

benchmark :: String -> TestTree
benchmark name = goldenVsString name
  ("test/expected/" ++ name ++ ".txt")
  (run ("test/baseline/" ++ name ++ ".tstp"))

run :: FilePath -> IO LBS.ByteString
run path = do
  contents <- TIO.readFile path
  case eitherResult (feed (parseTSTP contents) mempty) of
    Left err   -> fail ("Parse error in " ++ path ++ ": " ++ err)
    Right tstp -> do
      result <- catch (evaluate (force (emit (translate False tstp))))
                      (\e -> return (show (e :: SomeException)))
      return (LBS.pack result)
