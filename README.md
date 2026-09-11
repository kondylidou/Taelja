# Taelja

Taelja converts resolution/superposition refutation proofs in TSTP format into
structured, human-readable proofs, and can emit them as Lean 4 theorems for
independent verification.

It reads the TSTP output of Vampire, E, or Twee and produces direct proofs in
two forms: `have … and … hence … by axiom N` blocks (one block per
hyperresolution step) and equality chains
(`t1 = { by axiom 1 } t2 = { by lemma 3 R->L } t3`). Every step cites a
concrete axiom or lemma. Derived clauses that the input proof uses more than
once are introduced as named lemmas with their own proofs.

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

Two prover binaries are not distributed with the source. Build each one in its
own repository, then copy the executable into this project's `bin/` directory,
under exactly these names. Below, `TAELJA` is the directory holding this
README.

**Twee** must come from the `horn` branch, which proves Horn problems via an
encoding. A released version of Twee will not work in its place.

```
git clone https://codeberg.org/nick8325/twee
cd twee
git checkout horn
cabal build
cp "$(cabal list-bin twee)" "$TAELJA/bin/twee"
```

Taelja looks for `bin/twee` relative to the directory it runs in, so the file
has to sit exactly at `$TAELJA/bin/twee`. Without it the golden tests and any
translation needing an equational chain will fail.

**Vampire** is only needed to produce input proofs, not to translate them, and
any recent build works. Follow its own README if the build layout differs; all
that matters here is where the executable ends up.

```
git clone https://github.com/vprover/vampire
cd vampire
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cp build/vampire "$TAELJA/bin/vampire"
```

The E prover (`eprover`) should be on the PATH, or set `TAELJA_EPROVER` to
its path.

With those in place, build Taelja itself:

```
cabal build
```

## Usage

```
cabal run taelja -- <proof-file.tstp>
cabal run taelja -- --debug <proof-file.tstp>
```

`--debug` additionally prints the parsed units, the refutation proof tree,
and per-step matching traces.

Environment variables (all optional):

| Variable | Default | Meaning |
|----------|---------|---------|
| `TAELJA_TWEE_TIMEOUT` | 15 s | Budget for goal-level Twee calls |
| `TAELJA_TWEE_INTERNAL_TIMEOUT` | 5 s | Budget for internal Twee calls; never exceeds the goal budget |
| `TAELJA_E_TIMEOUT` | 5 s | Budget per E lemma sub-proof |
| `TAELJA_RESCUE_TIMEOUT` | 30 s | Budget for the second attempt that re-proves derived units when the first translation is incomplete |
| `TAELJA_EPROVER` | `eprover` | Path to the E binary |
| `TAELJA_STRICT` | unset | `1` runs only the strict translation stage |

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
