# Artifact: Tälja

This is the artifact for "Readable Proofs for the Horn Fragment" (CPP 2027).
It contains the Tälja translator, its Twee integration, and the benchmark
scripts used to produce Table 1 of the paper. The raw evaluation data
(`eval_out/`: every prover's `proof.tstp` and Tälja's `taelja.txt`/`.err` for
each of the 2413 × 3 problem/prover pairs, plus the summary `results.csv`) is
distributed separately, not as part of this repository. `README.md`
documents the tool itself (building, running on a single proof, the output
format); this file covers reproducing the evaluation.

## What's included

- `src/`, `app/` — Tälja (Haskell), built with `cabal build`.
- `bin/` — where the two prover binaries must be placed. They are not
  distributed with this artifact and have to be built from source, see
  Requirements below.
- `scripts/eval.py` — runs E/Twee/Vampire over a TPTP directory and Tälja
  over each resulting proof; writes `eval_out/`.
- `scripts/taelja2lean.py`, `scripts/regen_lean_eval.py`,
  `scripts/check_lean_eval.py` — the Lean-verification pipeline used for the
  paper's "accepted by the Lean kernel" claim.
- `scripts/check_chains.py` — an independent sanity check of equality-chain
  steps, without going through Lean.
- `lean/` — the Lean 4 project (`TaeljaVerify`) that both the golden tests
  and the evaluation's Lean-verification step check proofs against.
- `test/` — the golden test suite (`cabal test`).

## Requirements

- GHC 9.6 and Cabal 3 (tested with GHC 9.6.7 / cabal-install 3.14.2.0).
- [E](https://www.eprover.org/) on `PATH` or via `--eprover PATH` (tested
  with E 3.2.5).
- Twee, built from the `horn` branch of
  <https://codeberg.org/nick8325/twee/src/branch/horn> and placed at
  `bin/twee`. This branch extends Twee to prove Horn problems via an
  encoding, so a standard Twee release will not work. Taelja resolves `bin/twee` relative to its working
  directory, so the binary has to sit exactly there. Without it the golden
  suite and any translation that needs an equational chain will fail.
- Vampire, built from <https://github.com/vprover/vampire> and placed at
  `bin/vampire` (tested at 5.0.1, any recent build works). Only needed to
  produce input proofs for the evaluation, not to translate them.
- Lean 4 + Lake (tested with Lean 4.33.1 / Lake 5.0.0; see
  `lean/lean-toolchain` — `elan` will fetch the pinned toolchain
  automatically) — only needed to re-verify proofs, not to translate them.
- Python 3 — only for the scripts in `scripts/`, no third-party packages.
- The [TPTP problem library](https://www.tptp.org) — needed to reproduce the
  evaluation from scratch (§2 below); not bundled, for size. The paper's
  numbers use TPTP v9.2.1.

## 1. Build and smoke-test

```
cabal build
cabal test          # golden suite: 127 stored proofs, all three provers
```

A minimal end-to-end check on one proof:

```
cabal run taelja -- test/baseline_vampire/resolution_example_horn_general.tstp
```

See `README.md` for the single-proof workflow and the Lean-checking recipe
for one proof.

## 2. Reproducing the evaluation from scratch

```
python3 scripts/eval.py bin/vampire /path/to/TPTP-v9.2.1 \
  --eprover eprover --twee bin/twee --jobs 8
```

This classifies every TPTP problem into HNE/HEQ/UEQ by its SPC field (821 /
452 / 1140 problems, per the paper), runs each of E, Twee, and Vampire with
a 60 s timeout, and feeds every successful proof to Tälja with a 60 s
timeout, writing `eval_out/<category>/<problem>/<prover>/{proof.tstp,
taelja.txt, taelja.err}` and `eval_out/results.csv`. `--jobs N` controls
parallelism (default: 2 — raise this for a full run, e.g. `--jobs 8`); a
full run is 2413 problems × 3 provers. Omit `--skip-done` to re-run
everything, or keep it to resume an interrupted run.

The printed summary table (Category/Prover/Total/Proved/Unsupp/Transl/
Fail/TFail) corresponds directly to Table 1's Problems/Proved/Translated
columns (`Unsupp` + `Fail` + `TFail` = Proved − Translated).

## 3. Reproducing the Lean-verification numbers

The paper's "all translated proofs were accepted by the Lean kernel" claim
is checked in two steps, separate from `eval.py` (whose own `--lean` flag
does a simpler, less complete check — see note below):

```
python3 scripts/regen_lean_eval.py          # emit lean/TaeljaVerify/**/*.lean
                                             # for every taelja=ok row
python3 scripts/check_lean_eval.py --jobs 8 # `lake env lean` each module
                                             # individually; writes eval_out/
                                             # results.csv's `lean` column
                                             # and eval_out/lean_failing.txt
```

`check_lean_eval.py` checks each generated module with its own `lake env
lean` invocation rather than one aggregate `lake build`, because `lake
build` stops scheduling modules once some fail and so under-reports
failures. `regen_lean_eval.py` regenerates every `taelja=ok` row
and deletes modules whose row is no longer `ok`, so the generated module set
always matches the current evaluation data.

As an independent cross-check that doesn't go through Lean at all,
`scripts/check_chains.py [LIMIT]` re-verifies every equality-chain step in
`eval_out` by replaying the cited rewrite directly, and reports the share of
unjustifiable steps per prover.

## Notes

- `eval.py`'s own `--lean PATH` flag runs `lean <file>` directly on each
  proof right after translation, without the `lake env` project context;
  it's a quick check during the main run, not the authoritative one — use
  §3 above to reproduce the paper's Lean numbers.
- All scripts are read-only with respect to the prover/Tälja binaries and
  only write under `eval_out/` and `lean/TaeljaVerify/`; re-running them is
  safe to interrupt and resume.
- Problem counts, timeouts, and the translation-failure breakdown (1101
  timeouts, 1 prover proof-output failure, 33 known limitations) are
  discussed in the paper's Evaluation section (§7).
