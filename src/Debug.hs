-- Debug output for --debug, printed on stderr. It shows the proof tree, the
-- inference rules of the input proof and trace lines from the translation.
module Debug
  ( dumpProofTree
  , dumpInferenceRules
  , dbg
  , dbgScoped
  ) where

import Data.List (intercalate, nub, sort)
import Control.Exception (finally)
import Data.IORef (IORef, newIORef, readIORef, modifyIORef')
import System.IO.Unsafe (unsafePerformIO)
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Data.TPTP as T
import Data.TPTP.Pretty ()
import Prettyprinter (pretty)

import System.IO (hPutStrLn, stderr)
import Helpers (padRight)
import ProofTree (RuleReading (..), inferenceReading)
import TptpConvert (unitNameStr)
import Types (ProofInfo(..), LeafEntry(..), LeafRole(..))

-- Prints the proof tree, rebuilt from node positions. A child's position adds
-- one digit to its parent's, 0 for the provider and 1 for the consumer.
dumpProofTree :: ProofInfo -> IO ()
dumpProofTree info = do
  hPutStrLn stderr "Proof tree (left=provider, right=consumer):"
  go "" "" ""
  where
    byPos = Map.fromListWith (++) [ (lePos e, [e]) | e <- piElectrons info ++ piNuclei info ]
    -- linePrefix draws this node's line and contPrefix the lines below it
    go pos linePrefix contPrefix = do
      let entries  = Map.findWithDefault [] pos byPos
          children = [ c | d <- ['0' .. '9'], let c = pos ++ [d], Map.member c byPos ]
          label    = if null entries then "(internal)" else intercalate " | " (map nodeLabel entries)
      hPutStrLn stderr (linePrefix ++ label)
      mapM_ (\(i, child) ->
        let (branch, cont) = if i == length children then ("└── ", "    ") else ("├── ", "│   ")
        in go child (contPrefix ++ branch) (contPrefix ++ cont)) (zip [1 ..] children)
    -- a node's role and its clause as TPTP writes it
    nodeLabel e = "[" ++ role (leRole e) ++ "] " ++ case leDecl e of
      T.Formula _ f -> show (pretty f)
      d             -> show (pretty d)
    role OrigAxiom     = "axiom"
    role NegConjecture = "goal"
    role Derived       = "derived"

-- Prints the inference rules of the proof, grouped by how the translation
-- reads them, so a rule it copies or refuses stands out.
dumpInferenceRules :: [T.Unit] -> IO ()
dumpInferenceRules units = do
  let unitMap = Map.fromList [ (unitNameStr n, u) | u@(T.Unit n _ _) <- units ]
      inferences src = case src of
        T.Inference (T.Atom rule) _ ps -> (rule, ps) : concat [ inferences s | T.Parent s _ <- ps ]
        _                              -> []
      reading (rule, ps) = case inferenceReading unitMap rule ps of
        TreeStep    -> "tree step"
        RewriteStep -> "rewrite step"
        Copy        -> "copy"
        Refused _   -> "refused"
      grouped = Map.map (nub . sort) $ Map.fromListWith (++)
        [ (reading inf, [Text.unpack (fst inf)])
        | T.Unit _ _ (Just (src, _)) <- units, inf <- inferences src ]
      showBucket k = hPutStrLn stderr $ "  " ++ padRight 14 k ++ "  " ++
        maybe "(none)" (intercalate ", ") (Map.lookup k grouped)
  hPutStrLn stderr ("Inference rules [" ++ show (length (nub (concat (Map.elems grouped)))) ++ "]:")
  mapM_ showBucket ["tree step", "rewrite step", "copy", "refused"]

-- Nesting depth of recursive sub-translations. Sub-runs reuse clause names
-- and positions, so each debug line is tagged with its depth.
{-# NOINLINE debugDepthRef #-}
debugDepthRef :: IORef Int
debugDepthRef = unsafePerformIO (newIORef 0)

-- Prints a trace line tagged with the nesting depth when debugging is on.
dbg :: Bool -> String -> IO ()
dbg True  msg = do
  d <- readIORef debugDepthRef
  hPutStrLn stderr ("[d" ++ show d ++ "] " ++ msg)
dbg False _   = return ()

-- Runs an action one level deeper, between enter and exit markers.
dbgScoped :: Bool -> String -> IO a -> IO a
dbgScoped debug label act = do
  modifyIORef' debugDepthRef (+ 1)
  dbg debug ("[subrun-enter] " ++ label)
  -- restore the depth even if the sub-run throws
  r <- act `finally` modifyIORef' debugDepthRef (subtract 1)
  dbg debug ("[subrun-exit] " ++ label)
  return r
