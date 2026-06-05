module Translator where

import Data.TPTP (TSTP)
import Types (StructuredProof)

-- | Translate a parsed TSTP refutation into a structured readable proof.
--
--   Implements the algorithm from horn_approach.md §5:
--     - split clauses into Units and NonUnits
--     - process NonUnits in topological order
--     - discharge body literals via hyperresolution + rw steps
--     - emit lemmas when forced (i>=2 body literal, or cited as rw step)
translate :: TSTP -> StructuredProof
translate = error "Translator.translate: not yet implemented"
