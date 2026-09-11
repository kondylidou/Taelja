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

**This file covers the tool itself. See `ARTIFACT.md` for reproducing the
paper's evaluation.**

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

E comes from <https://www.eprover.org/>. Either put `eprover` on the PATH, or
set `TAELJA_EPROVER` to its full path, for example

```
export TAELJA_EPROVER="$(which eprover)"
```

Tested with E 3.2.5.

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
