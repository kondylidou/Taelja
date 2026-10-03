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
import Data.Map.Strict (Map)
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

-- A clause or formula as TPTP writes it.
ppDecl :: T.Declaration -> String
ppDecl (T.Formula _ f) = show (pretty f)
ppDecl d               = show (pretty d)

-- Prints the proof tree, rebuilt from node positions. A child's position adds
-- one digit to its parent's, 0 for the provider and 1 for the consumer.
dumpProofTree :: ProofInfo -> IO ()
dumpProofTree info = do
  hPutStrLn stderr "Proof tree (left=provider, right=consumer):"
  let allEntries = piElectrons info ++ piNuclei info
      byPos = Map.fromListWith (++) [(lePos e, [e]) | e <- allEntries]
  go byPos "" "" ""
  where
    -- linePrefix draws this node's line and contPrefix the lines below it
    go :: Map String [LeafEntry] -> String -> String -> String -> IO ()
    go byPos pos linePrefix contPrefix = do
      let entries  = Map.findWithDefault [] pos byPos
          children = childPositions byPos pos
          label    = case entries of
            []  -> "(internal)"
            [e] -> nodeLabel e
            es  -> intercalate " | " (map nodeLabel es)
      hPutStrLn stderr (linePrefix ++ label)
      let n = length children
      mapM_ (\(i, child) ->
        let isLast     = i == n - 1
            branch     = if isLast then "└── " else "├── "
            cont       = if isLast then "    " else "│   "
        in go byPos child (contPrefix ++ branch) (contPrefix ++ cont)
        ) (zip [0..] children)

    childPositions :: Map String [LeafEntry] -> String -> [String]
    childPositions byPos pos =
      sort
        [ c | c0 <- ['0'..'9']
            , let c = pos ++ [c0]
            , Map.member c byPos ]

    nodeLabel :: LeafEntry -> String
    nodeLabel e =
      "[" ++ role ++ "] "
      ++ ppDecl (leDecl e)
      where
        role = case leRole e of
                 OrigAxiom     -> "axiom"
                 NegConjecture -> "goal"
                 Derived       -> "derived"

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
      ruleNames = nub (concat (Map.elems grouped))
      showBucket k = hPutStrLn stderr $ "  " ++ padRight 14 k ++ "  " ++
        maybe "(none)" (intercalate ", " . sort) (Map.lookup k grouped)
  hPutStrLn stderr ("Inference rules [" ++ show (length ruleNames) ++ "]:")
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
