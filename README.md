# Taelja

Taelja converts resolution/superposition refutation proofs in TSTP format into
structured, human-readable proofs, and can emit them as Lean 4 theorems for
independent verification.

It reads the TSTP output of Vampire, E, or Twee and produces direct proofs in
two forms: `have … and … hence … by axiom N` blocks (one block per
hyperresolution step) and equality chains
(`t1 = { by axiom 1 } t2 = { by lemma 3 R->L } t3`). Every step cites a
concrete axiom or lemma. Derived clauses that the input proof uses more than
once are introduced as named lemmas with their own proofs. The hypotheses of
a conjecture `H1 & ... & Hn => G` are unit clauses, listed with the axioms,
and `G` is the goal.

Taelja covers the Horn fragment, decided on the problem as written: every
axiom is a Horn clause, a universally closed `A1 & ... & An => B`, an atom, a
disjunction with at most one positive literal, or a negated conjunction, and
the conjecture is a Horn clause whose hypotheses are atoms and whose
conclusion is an atom, a conjunction of atoms, or one under an existential
quantifier. The refutation must use resolution, superposition, demodulation
and equality resolution on Horn clauses; a non-Horn clause, another inference
rule, or a conjecture outside the fragment is refused with a message naming
it.

## Example

Input (`resolution_example_horn_general.tstp`, Vampire output):

```
fof(f1, axiom,   t(b)).
fof(f2, axiom,   ! [X] : (t(X) => q(X))).
fof(f3, axiom,   s(a)).
fof(f4, axiom,   ! [X] : (s(X) => p(X))).
fof(f5, axiom,   ! [X,Y] : (p(X) & q(Y) => r(X,Y))).
fof(f6, conjecture, r(a,b)).
...
```

Output:

```
Axiom 1: t(b)
Axiom 2: t(X) => q(X)
Axiom 3: s(a)
Axiom 4: s(X) => p(X)
Axiom 5: p(X) /\ q(Y) => r(X,Y)

Lemma 6: q(b)
Proof:
  have t(b)
    by axiom 1
  hence q(b)
    by axiom 2

Goal 1: r(a,b)
Proof:
  have s(a)
    by axiom 3
  hence p(a)
    by axiom 4
   and q(b)
    by lemma 6
  hence r(a,b)
    by axiom 5
```

## Building

Requires Cabal 3 and GHC 9.6 or newer. The package accepts base 4.18 to
4.21, which covers GHC 9.6 through 9.12. Tested with GHC 9.6.7 and 9.10.3.

Taelja calls three provers, none of them bundled: E, Twee and Vampire.

Twee and Vampire have to be built from source:

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

E comes from <https://www.eprover.org/>.

Taelja looks for each prover at its variable if set (`TAELJA_TWEE`,
`TAELJA_EPROVER`), then at `bin/twee` or `bin/eprover` under the current
directory, then on the PATH, and says once on stderr when one is missing.
Without Twee the rewrite steps the refutation does not justify itself are left
unproved, and without E derived clauses used more than once are inlined rather
than proved as lemmas. All Twee and E calls of one run share a time budget,
`TAELJA_FALLBACK_TIMEOUT` seconds (30 by default); a run that spends it stops
and says so.

Tested with E 3.2.5.

With those in place, build Taelja itself:

```
cabal build
```

## Usage

```
cabal run taelja -- <proof-file.tstp>
cabal run taelja -- --debug <proof-file.tstp>
cabal run taelja -- --tptp <proof-file.tstp>
```

`--debug` additionally prints the parsed units, the refutation proof tree,
and per-step matching traces.

`--tptp` prints the same proof as a TPTP derivation, one fof formula per
line with an inference record naming its parents.  Each lemma and goal is
the last step of its block, and no step derives $false.

## Checking a proof with Lean

```
cabal run taelja -- proof.tstp > proof.txt
python3 scripts/taelja2lean.py proof.txt > proof.lean
cd lean && lake env lean proof.lean
```

Each theorem in the generated file mirrors one lemma or goal of the
structured proof.

## Testing

```
cabal test
```

Golden tests translate stored prover outputs for all three provers
(`test/baseline_{vampire,e,twee}/`) and compare against
`test/expected_{vampire,e,twee}/`. Each golden also has a Lean module under
`lean/TaeljaVerify/`.

## Running the evaluation

The evaluation runs over the TPTP problems that are Horn as written. From
this directory, with the TPTP library unpacked at `/path/to/TPTP-v9.2.1`:

```
python3 scripts/select_horn.py /path/to/TPTP-v9.2.1 --jobs 8 --output-dir eval_out
python3 scripts/eval.py bin/vampire /path/to/TPTP-v9.2.1 \
  --eprover /opt/homebrew/bin/eprover --twee bin/twee --jobs 8 --output-dir eval_out \
  --list eval_out/horn_cnf.txt --list eval_out/horn_fof.txt --list eval_out/horn_tff.txt
python3 scripts/regen_lean_eval.py
python3 scripts/check_lean_eval.py --jobs 3
```

The first command writes the problem lists, one per format, judging each FOF
and TFF problem with `taelja --horn-problem <problem.p>` and reading the CNF
categories off the SPC field. The second runs E, Twee and Vampire on them
and translates every proof, writing `eval_out/<category>/<problem>/<prover>/`
and `eval_out/results.csv`; `--skip-done` resumes an interrupted run. The
last two translate every translated proof to Lean and check it:
`regen_lean_eval.py` writes a module under `lean/TaeljaVerify/` for every
translated proof and deletes the modules of proofs no longer translated, and
`check_lean_eval.py` runs `lake env lean` on each module by itself, since one
`lake build` stops scheduling modules once some fail and under-reports, and
records the verdicts in the `lean` column of `results.csv` and in
`eval_out/lean_failing.txt`. (`eval.py --lean` checks each proof right after
translation without the project context; it is a quick check, not the one
the paper reports.) The scripts only write under `eval_out/` and
`lean/TaeljaVerify/`.
