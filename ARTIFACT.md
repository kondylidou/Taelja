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

- `src/`, `app/` — Tälja (Haskell).
- `bin/` — where the prover binaries must be placed. Taelja uses three
  provers, E, Twee and Vampire, none of them distributed with this artifact;
  see Requirements below.
- `scripts/eval.py` — runs E/Twee/Vampire over a TPTP directory and Tälja
  over each resulting proof; writes `eval_out/`.
- `scripts/taelja2lean.py`, `scripts/regen_lean_eval.py`,
  `scripts/check_lean_eval.py` — the Lean-verification pipeline used for the
  paper's "accepted by the Lean kernel" claim.
- `lean/` — the Lean 4 project (`TaeljaVerify`) that both the golden tests
  and the evaluation's Lean-verification step check proofs against.
- `test/` — the golden test suite (`cabal test`).

## Requirements

- Cabal 3 and GHC 9.6 or newer. The package accepts base 4.18 to 4.21,
  which covers GHC 9.6 through 9.12. Built and golden-tested with both
  GHC 9.6.7 and GHC 9.10.3, with cabal-install 3.14.2.0.
- E, installed from <https://www.eprover.org/> (tested with E 3.2.5).
  `eval.py` needs its path via `--eprover`, and resolves that path against
  the current directory rather than searching `PATH`, so give an absolute one.
  Without the flag E is skipped and only the other two provers run.
- Twee, from the `horn` branch,
  <https://codeberg.org/nick8325/twee/src/branch/horn>. A released Twee will
  not work. It is a Haskell package, so (tested with twee 2.7):

  ```
  git clone https://codeberg.org/nick8325/twee
  cd twee && git checkout horn && cabal build
  cp "$(cabal list-bin twee)" /path/to/taelja/bin/twee
  ```

  where `/path/to/taelja` is the directory holding this file, so the binary
  ends up in the `bin/` folder next to `src/` and `test/`.
- Vampire, from <https://github.com/vprover/vampire>. Build it as that
  repository describes, then copy the executable into the same `bin/` folder,
  renaming it to `vampire`, so that it ends up at `./bin/vampire`. Any recent
  build works (tested at 5.0.1).
- Lean 4 + Lake (tested with Lean 4.33.1 / Lake 5.0.0; see
  `lean/lean-toolchain` — `elan` will fetch the pinned toolchain
  automatically).
- Python 3 — only for the scripts in `scripts/`, no third-party packages.
- The TPTP problem library — needed to reproduce the evaluation from scratch
  (§2 below). The paper's numbers use v9.2.1,
  <https://tptp.org/TPTP/Archive/TPTP-v9.2.1.tgz>.

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

Run this from the directory holding this file, replacing
`/path/to/TPTP-v9.2.1` with the path to the unpacked TPTP library and
`/path/to/eprover` with the path to the E binary (`which eprover` prints it
if E is on your PATH):

```
python3 scripts/eval.py bin/vampire /path/to/TPTP-v9.2.1 \
  --eprover /path/to/eprover --twee bin/twee --jobs 8
```

This classifies every TPTP problem into HNE/HEQ/UEQ by its SPC field (821 /
452 / 1140 problems, per the paper), runs each of E, Twee, and Vampire with
a 60 s timeout, and feeds every successful proof to Tälja with a 60 s
timeout, writing `eval_out/<category>/<problem>/<prover>/{proof.tstp,
taelja.txt, taelja.err}` and `eval_out/results.csv`. `--jobs N` controls
parallelism (default: 2 — raise this for a full run, e.g. `--jobs 8`); a
full run is 2413 problems × 3 provers. Omit `--skip-done` to re-run
everything, or keep it to resume an interrupted run.

A cached `proof.tstp` is reused even without `--skip-done`, and an empty one
left by an interrupted run reads back as a failure rather than being retried.
Delete `eval_out/` before a fresh run.

The printed summary table (Category/Prover/Total/Proved/Unsupp/Transl/
Fail/TFail) corresponds directly to Table 1's Problems/Proved/Translated
columns (`Unsupp` + `Fail` + `TFail` = Proved − Translated).

## 3. Reproducing the Lean-verification numbers

The paper's "all translated proofs were accepted by the Lean kernel" claim
is checked in two steps, separate from `eval.py` (whose own `--lean` flag
does a simpler, less complete check — see note below):

```
python3 scripts/regen_lean_eval.py           # emit lean/TaeljaVerify/**/*.lean
                                             # for every taelja=ok row
python3 scripts/check_lean_eval.py --jobs 8  # `lake env lean` each module
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
